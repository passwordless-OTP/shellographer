# Shellographer Build Plan (Production Ready)

## Revised Scope

Based on senior developer review:
- **Reduced scope:** 3 plugins (wrangler, gh, docker) for MVP
- **Simplified:** Explicit plugin loading, no auto-discovery
- **Performance:** No file I/O during startup
- **Quality:** Debug mode, proper error handling, tests

**Total:** ~25 hours over 3 weeks

---

## Phase 1: Core Infrastructure (Week 1)

### Step 1: Alias Helper
**File:** `shellographer/lib/alias-helper.zsh`  
**Time:** 3 hours

```zsh
# Requirements:
# - No file I/O during init
# - Debug mode (SHELLOGRAPHER_DEBUG=1)
# - Memory-only registry
# - Clear return codes (0=created, 1=skipped, 2=error)

_typeset -gA _SHELLOGRAPHER_REGISTRY

typeset -g SHELLOGRAPHER_DEBUG=${SHELLOGRAPHER_DEBUG:-0}

_shellographer_alias() {
  local name=$1 cmd=$2 desc=${3:-}
  
  # Validation
  [[ -z "$name" ]] && { 
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Error: empty alias name" >&2
    return 2
  }
  
  # Conflict detection with feedback
  if (( $+functions[$name] )); then
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Skip: $name (function exists)" >&2
    return 1
  fi
  
  if (( $+aliases[$name] )); then
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Skip: $name (alias exists)" >&2
    return 1
  fi
  
  alias "$name"="$cmd"
  [[ -n $desc ]] && _SHELLOGRAPHER_REGISTRY[$name]=$desc
  
  return 0
}
```

**Tests:**
- Create alias when no conflict
- Skip when function exists
- Skip when alias exists
- Debug mode prints messages

---

### Step 2: Cache Helper
**File:** `shellographer/lib/cache-helper.zsh`  
**Time:** 2 hours

```zsh
# Requirements:
# - Lock files prevent races
# - Stale-while-revalidate
# - Async refresh

typeset -gA _SHELLOGRAPHER_CACHE_PID

_shellographer_cache() {
  local name=$1 ttl=$2 cmd=$3
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer"
  local cache_file="$cache_dir/$name"
  local lock_file="$cache_dir/$name.lock"
  
  mkdir -p "$cache_dir"
  
  # Check freshness
  if [[ -f "$cache_file" && ! -f "$lock_file" ]]; then
    local mod_time=$(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0)
    local age=$(( $(date +%s) - mod_time ))
    
    if (( age < ttl )); then
      cat "$cache_file" 2>/dev/null
      return 0
    fi
    
    # Trigger async refresh with lock
    if [[ ! -f "$lock_file" ]]; then
      touch "$lock_file"
      (eval "$cmd" >| "$cache_file" 2>/dev/null; rm -f "$lock_file") &!
      _SHELLOGRAPHER_CACHE_PID[$name]=$!
    fi
  fi
  
  # Return stale data
  cat "$cache_file" 2>/dev/null
}
```

**Tests:**
- Cache hit returns immediately
- Cache miss triggers background job
- Lock file prevents duplicate jobs

---

### Step 3: Main Loader
**File:** `shellographer/shellographer.plugin.zsh`  
**Time:** 2 hours

```zsh
# Requirements:
# - Guard against double-loading
# - Explicit plugin list (no auto-discovery)
# - Graceful fallback if lib missing
# - Clean up temp variables

(( $+_SHELLOGRAPHER_LOADED )) && return 0
typeset -gr _SHELLOGRAPHER_LOADED=1

0=${(%):-%N}
local _sdir=${0:A:h}

# Load libs
[[ -f "$_sdir/lib/alias-helper.zsh" ]] && source "$_sdir/lib/alias-helper.zsh"
[[ -f "$_sdir/lib/cache-helper.zsh" ]] && source "$_sdir/lib/cache-helper.zsh"

# Load plugins (explicit for MVP)
local _plugins=(${(s: :)SHELLOGRAPHER_PLUGINS:-wrangler gh docker})

for _plugin in $_plugins; do
  local _plugin_file="$_sdir/plugins/$_plugin/$_plugin.plugin.zsh"
  local _loaded_var="_SHELLOGRAPHER_PLUGIN_${(U)_plugin}"
  
  (( ${(P)+_loaded_var} )) && continue
  
  if [[ -f "$_plugin_file" ]]; then
    typeset -g "${_loaded_var}=1"
    source "$_plugin_file"
  fi
done

unset _sdir _plugin _plugin_file _plugins _loaded_var
```

---

### Step 4: Caps Command
**File:** `shellographer/lib/caps.zsh`  
**Time:** 2 hours

```zsh
# Requirements:
# - Write registry to file ONLY when called
# - Never during startup

caps() {
  local _registry_file="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer/registry"
  
  # Write memory to file (lazy)
  if (( $#_SHELLOGRAPHER_REGISTRY > 0 )); then
    mkdir -p "${_registry_file:h}"
    for name desc in "${(@kv)_SHELLOGRAPHER_REGISTRY}"; do
      print "$name:$desc"
    done >| "$_registry_file"
  fi
  
  if [[ -z "$1" ]]; then
    # List services
    [[ -f "$_registry_file" ]] && cut -d: -f1 "$_registry_file" | cut -d- -f1 | sort -u
  else
    # List commands for service
    [[ -f "$_registry_file" ]] && grep "^$1-" "$_registry_file" 2>/dev/null | column -t -s:
  fi
}
```

---

## Phase 2: Plugins (Week 2)

### Step 5: Wrangler Plugin
**File:** `shellographer/plugins/wrangler/wrangler.plugin.zsh`  
**Time:** 4 hours

**Aliases (8):**
```
wrangler-dev-server      # wrangler dev
wrangler-deploy-worker   # wrangler deploy
wrangler-kv-list         # wrangler kv:list
wrangler-kv-get          # wrangler kv:key get
wrangler-kv-put          # wrangler kv:key put
wrangler-r2-list         # wrangler r2:buckets list
wrangler-tail            # wrangler tail
wrangler-secrets-list    # wrangler secret list
```

**Requirements:**
- Add fpath early
- Guard if wrangler not installed
- Fallback if lib missing
- Defer compdef check

---

### Step 6: GitHub Plugin
**File:** `shellographer/plugins/gh/gh.plugin.zsh`  
**Time:** 4 hours

**Aliases (10):**
```
gh-pr-create      # gh pr create
gh-pr-checkout    # gh pr checkout
gh-pr-merge       # gh pr merge
gh-pr-view        # gh pr view
gh-pr-list        # gh pr list
gh-issue-create   # gh issue create
gh-issue-list     # gh issue list
gh-repo-view      # gh repo view
gh-workflow-list  # gh workflow list
gh-run-list       # gh run list
```

**Completions:**
- Dynamic PR numbers (cache 60s)
- Workflow names (cache 300s)

---

### Step 7: Docker Plugin
**File:** `shellographer/plugins/docker/docker.plugin.zsh`  
**Time:** 3 hours

**Aliases (8):**
```
docker-container-list      # docker ps
docker-container-list-all  # docker ps -a
docker-container-exec      # docker exec -it
docker-container-logs      # docker logs -f
docker-container-stop      # docker stop
docker-image-list          # docker images
docker-image-build         # docker build
docker-compose-up          # docker-compose up -d
```

---

## Phase 3: Testing & Release (Week 3)

### Step 8: Test Suite
**Directory:** `shellographer/tests/`  
**Time:** 4 hours

```
tests/
├── test_alias_helper.zsh
├── test_cache_helper.zsh
├── test_wrangler.zsh
├── test_gh.zsh
└── run_all.zsh
```

**Test Framework:**
```zsh
#!/usr/bin/env zsh
setopt err_exit nounset

TESTS_RUN=0 TESTS_PASSED=0 TESTS_FAILED=0

assert() {
  local expected=$1 actual=$2 name=$3
  (( TESTS_RUN++ ))
  if [[ "$expected" == "$actual" ]]; then
    (( TESTS_PASSED++ ))
    print "✓ $name"
  else
    (( TESTS_FAILED++ ))
    print "✗ $name"
    print "  Expected: $expected, Actual: $actual"
  fi
}

# Load and test
source ../lib/alias-helper.zsh

# Test 1: Create alias
_shellographer_alias "test-1" "echo test"
assert 0 $? "Alias creation returns 0"

# Test 2: Conflict detection
alias existing="echo test"
_shellographer_alias "existing" "echo new"
assert 1 $? "Conflict returns 1"

print ""
print "Results: $TESTS_PASSED/$TESTS_RUN passed"
(( TESTS_FAILED == 0 )) || exit 1
```

---

### Step 9: Documentation
**Files:**  
**Time:** 3 hours

- `README.md` - Main project docs
- `plugins/wrangler/README.md` - Usage examples
- `plugins/gh/README.md` - Usage examples
- `plugins/docker/README.md` - Usage examples

---

### Step 10: Install Script
**File:** `install.sh`  
**Time:** 2 hours

```bash
#!/bin/bash
# One-line install
# curl -fsSL ... | bash

set -e

INSTALL_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/shellographer"

echo "Installing Shellographer..."

# Clone
if [[ -d "$INSTALL_DIR" ]]; then
  echo "Updating existing installation..."
  git -C "$INSTALL_DIR" pull
else
  git clone https://github.com/passwordless-OTP/shellographer.git "$INSTALL_DIR"
fi

# Instructions
echo ""
echo "Add to your ~/.zshrc:"
echo "  plugins=(shellographer)"
echo ""
echo "Optional - customize plugins:"
echo "  SHELLOGRAPHER_PLUGINS=\"wrangler gh docker\""
echo ""
echo "Enable debug mode:"
echo "  SHELLOGRAPHER_DEBUG=1"
```

---

### Step 11: Performance Benchmarks
**Time:** 1 hour

```bash
# Benchmark startup time
$ time zsh -c "source ~/.zshrc; exit"
# Target: < 50ms

# Benchmark completion
$ time (wrangler-<Tab>)
# Target: < 100ms
```

---

### Step 12: GitHub Release
**Time:** 1 hour

- [ ] Tag v1.0.0
- [ ] Write release notes
- [ ] Test install on fresh macOS
- [ ] Test install on fresh Ubuntu

---

## Summary

| Phase | Steps | Hours | Deliverables |
|-------|-------|-------|--------------|
| 1 | 4 | 9 | Core libs, loader, caps |
| 2 | 3 | 11 | 3 plugins (wrangler, gh, docker) |
| 3 | 4 | 8 | Tests, docs, install, release |
| **Total** | **11** | **28** | **v1.0.0** |

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Explicit plugin list | Faster startup, no surprises |
| No file I/O at init | < 50ms startup guarantee |
| Debug mode | Easier troubleshooting |
| Lock files | Prevent cache race conditions |
| 3 plugins for MVP | Quality over quantity |
| Standalone plugins | Work without shellographer lib |

---

## Next Action

**Step 1:** Create `shellographer/lib/alias-helper.zsh`

Ready to start?
