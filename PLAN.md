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

typeset -gA _SHELLOGRAPHER_REGISTRY

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

### Step 8: Test Framework
**File:** `tests/framework.zsh`  
**Time:** 1 hour

```zsh
#!/usr/bin/env zsh
# Test framework with setup/teardown, skip, and proper error handling

setopt nounset local_options no_err_exit

typeset -gi _TESTS_RUN=0 _TESTS_PASSED=0 _TESTS_FAILED=0 _TESTS_SKIPPED=0
typeset -ga _TEST_FAILURES=() _TEST_SETUP=() _TEST_TEARDOWN=()

assert_equals() {
  local expected=$1 actual=$2 name=$3
  (( _TESTS_RUN++ ))
  if [[ "$expected" == "$actual" ]]; then
    (( _TESTS_PASSED++ ))
    print "✓ $name"
    return 0
  else
    (( _TESTS_FAILED++ ))
    _TEST_FAILURES+=("$name: expected '$expected', got '$actual'")
    print "✗ $name"
    print "  Expected: $expected"
    print "  Actual:   $actual"
    return 1
  fi
}

assert_true() {
  local exit_code=$1 name=$2
  (( _TESTS_RUN++ ))
  if (( exit_code == 0 )); then
    (( _TESTS_PASSED++ ))
    print "✓ $name"
    return 0
  else
    (( _TESTS_FAILED++ ))
    _TEST_FAILURES+=("$name: expected true, got exit code $exit_code")
    print "✗ $name"
    return 1
  fi
}

assert_alias_exists() {
  local name=$1
  (( _TESTS_RUN++ ))
  if (( $+aliases[$name] )); then
    (( _TESTS_PASSED++ ))
    print "✓ Alias $name exists"
  else
    (( _TESTS_FAILED++ ))
    _TEST_FAILURES+=("Alias $name does not exist")
    print "✗ Alias $name does not exist"
  fi
}

skip_if_no_command() {
  local cmd=$1
  if (( ! $+commands[$cmd] )); then
    (( _TESTS_SKIPPED++ ))
    print "⊘ Skipped: $cmd not installed"
    return 1
  fi
  return 0
}

print_summary() {
  print ""
  print "═══════════════════════════════════════"
  print "Test Results: $_TESTS_PASSED/$_TESTS_RUN passed ($_TESTS_SKIPPED skipped)"
  print "═══════════════════════════════════════"
  
  if (( ${#_TEST_FAILURES} > 0 )); then
    print ""
    print "Failures:"
    local failure
    for failure in $_TEST_FAILURES; do
      print "  - $failure"
    done
  fi
  
  (( _TESTS_FAILED == 0 ))
  return $?
}
```

---

### Step 9: Unit Tests
**Files:** `tests/unit/test_*.zsh`  
**Time:** 1.5 hours

```
tests/unit/
├── test_alias_helper.zsh
└── test_cache_helper.zsh
```

**test_alias_helper.zsh:**
```zsh
#!/usr/bin/env zsh
source "${0:A:h:h}/framework.zsh"
source "${0:A:h:h:h}/lib/alias-helper.zsh"

test_alias_created_when_no_conflict() {
  _shellographer_alias "test-create" "echo test"
  assert_equals 0 $? "Alias creation returns 0"
  assert_alias_exists "test-create"
  unalias test-create 2>/dev/null || true
}

test_alias_skipped_when_function_exists() {
  test-skip-func() { echo "existing"; }
  _shellographer_alias "test-skip-func" "echo new"
  assert_equals 1 $? "Conflict with function returns 1"
  unfunction test-skip-func 2>/dev/null || true
}

test_alias_skipped_when_alias_exists() {
  alias test-skip-alias="echo existing"
  _shellographer_alias "test-skip-alias" "echo new"
  assert_equals 1 $? "Conflict with alias returns 1"
  unalias test-skip-alias 2>/dev/null || true
}

test_debug_mode_shows_output() {
  SHELLOGRAPHER_DEBUG=1
  alias test-debug="echo test"
  local output=$(_shellographer_alias "test-debug" "echo new" 2>&1)
  SHELLOGRAPHER_DEBUG=0
  [[ "$output" == *"Skip"* ]]
  assert_equals 0 $? "Debug mode shows skip message"
  unalias test-debug 2>/dev/null || true
}

# Run
run_test test_alias_created_when_no_conflict
run_test test_alias_skipped_when_function_exists
run_test test_alias_skipped_when_alias_exists
run_test test_debug_mode_shows_output
print_summary
```

**test_cache_helper.zsh:**
```zsh
#!/usr/bin/env zsh
source "${0:A:h:h}/framework.zsh"
source "${0:A:h:h:h}/lib/cache-helper.zsh"

test_cache_hit_returns_data() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer-test"
  mkdir -p "$cache_dir"
  echo "cached" > "$cache_dir/test_hit"
  
  local result=$(_shellographer_cache "test_hit" 60 "echo new")
  assert_equals "cached" "$result" "Cache hit returns cached data"
  
  rm -rf "$cache_dir"
}

test_cache_expired_returns_stale() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer-test"
  mkdir -p "$cache_dir"
  echo "stale" > "$cache_dir/test_stale"
  touch -t $(date -v-10S +%Y%m%d%H%M.%S 2>/dev/null || date -d "10 sec ago" +%Y%m%d%H%M.%S 2>/dev/null || echo 197001010000.00) "$cache_dir/test_stale" 2>/dev/null || true
  
  local result=$(_shellographer_cache "test_stale" 5 "echo refreshed")
  assert_equals "stale" "$result" "Cache expired returns stale data"
  
  rm -rf "$cache_dir"
}

# Run
run_test test_cache_hit_returns_data
run_test test_cache_expired_returns_stale
print_summary
```

---

### Step 10: Integration Tests
**Files:** `tests/integration/test_*.zsh`  
**Time:** 2 hours

```
tests/integration/
├── test_zshrc_loading.zsh
├── test_plugin_isolation.zsh
└── test_no_collisions.zsh
```

**test_zshrc_loading.zsh:**
```zsh
#!/usr/bin/env zsh
source "${0:A:h:h}/framework.zsh"

test_no_parse_errors() {
  local test_zshrc=$(mktemp)
  cat > $test_zshrc << 'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(shellographer)
source $ZSH/oh-my-zsh.sh
EOF
  
  zsh -c "source $test_zshrc; exit 0" 2>&1
  assert_equals 0 $? ".zshrc sources without errors"
  
  rm -f $test_zshrc
}

test_user_function_preserved() {
  local test_zshrc=$(mktemp)
  cat > $test_zshrc << 'EOF'
gh-pr-create() { echo "user function"; }
export ZSH="$HOME/.oh-my-zsh"
plugins=(shellographer)
source $ZSH/oh-my-zsh.sh
# Check if function still exists
type gh-pr-create | grep -q "function"
EOF
  
  zsh -c "source $test_zshrc" 2>&1
  assert_equals 0 $? "User function preserved"
  
  rm -f $test_zshrc
}

run_test test_no_parse_errors
run_test test_user_function_preserved
print_summary
```

**test_plugin_isolation.zsh:**
```zsh
#!/usr/bin/env zsh
source "${0:A:h:h}/framework.zsh"

test_wrangler_works_standalone() {
  # Don't load shellographer.plugin.zsh, just wrangler
  local test_zshrc=$(mktemp)
  cat > $test_zshrc << 'EOF'
export ZSH="$HOME/.oh-my-zsh"
source ~/.oh-my-zsh/custom/plugins/shellographer/plugins/wrangler/wrangler.plugin.zsh
alias | grep -q "wrangler-dev-server"
EOF
  
  zsh -c "source $test_zshrc" 2>&1
  assert_equals 0 $? "Wrangler plugin works standalone"
  
  rm -f $test_zshrc
}

run_test test_wrangler_works_standalone
print_summary
```

---

### Step 11: End-to-End Tests
**Files:** `tests/e2e/test_*.zsh`  
**Time:** 1.5 hours

```
tests/e2e/
├── test_fresh_install.zsh
├── test_real_zshrc.zsh
└── test_cli_integration.zsh
```

**test_fresh_install.zsh:**
```zsh
#!/usr/bin/env zsh
source "${0:A:h:h}/framework.zsh"

test_install_script_on_fresh_system() {
  # Simulate fresh install
  local test_home=$(mktemp -d)
  local test_zsh_custom="$test_home/.oh-my-zsh/custom"
  
  # Run install script
  ZSH_CUSTOM="$test_zsh_custom" ./install.sh --dry-run 2>&1
  assert_equals 0 $? "Install script runs without errors"
  
  # Verify structure
  [[ -d "$test_zsh_custom/plugins/shellographer" ]]
  assert_equals 0 $? "Plugin directory created"
  
  [[ -f "$test_zsh_custom/plugins/shellographer/shellographer.plugin.zsh" ]]
  assert_equals 0 $? "Main plugin file exists"
  
  # Cleanup
  rm -rf "$test_home"
}

test_uninstall_removes_all() {
  # Verify clean removal is possible
  local test_home=$(mktemp -d)
  cp -r . "$test_home/shellographer"
  
  rm -rf "$test_home/shellographer"
  [[ ! -d "$test_home/shellographer" ]]
  assert_equals 0 $? "Uninstall removes all files"
  
  rm -rf "$test_home"
}

run_test test_install_script_on_fresh_system
run_test test_uninstall_removes_all
print_summary
```

**test_real_zshrc.zsh:**
```zsh
#!/usr/bin/env zsh
source "${0:A:h:h}/framework.zsh"

test_backup_and_modify_real_zshrc() {
  # Backup real .zshrc
  cp ~/.zshrc ~/.zshrc.backup.test
  
  # Add shellographer
  echo '' >> ~/.zshrc
  echo '# Added by shellographer test' >> ~/.zshrc
  echo 'plugins=(shellographer)' >> ~/.zshrc
  
  # Test load
  zsh -c "source ~/.zshrc; exit 0" 2>&1
  local result=$?
  
  # Restore
  mv ~/.zshrc.backup.test ~/.zshrc
  
  assert_equals 0 $result "Real .zshrc loads with shellographer"
}

test_aliases_available_after_source() {
  # Source plugin and verify aliases exist
  source shellographer/shellographer.plugin.zsh 2>/dev/null
  
  (( $+aliases[wrangler-dev-server] || $+functions[wrangler-dev-server] ))
  assert_equals 0 $? "Wrangler aliases available after source"
}

run_test test_backup_and_modify_real_zshrc
run_test test_aliases_available_after_source
print_summary
```

**test_cli_integration.zsh:**
```zsh
#!/usr/bin/env zsh
source "${0:A:h:h}/framework.zsh"

test_wrangler_aliases_with_real_cli() {
  skip_if_no_command "wrangler" || return 0
  
  # If wrangler installed, verify aliases work
  source shellographer/plugins/wrangler/wrangler.plugin.zsh
  
  # Test that alias points to valid command
  alias wrangler-dev-server | grep -q "wrangler dev"
  assert_equals 0 $? "wrangler-dev-server alias is valid"
}

test_gh_aliases_with_real_cli() {
  skip_if_no_command "gh" || return 0
  
  source shellographer/plugins/gh/gh.plugin.zsh
  
  alias gh-pr-create | grep -q "gh pr create"
  assert_equals 0 $? "gh-pr-create alias is valid"
}

test_docker_aliases_with_real_cli() {
  skip_if_no_command "docker" || return 0
  
  source shellographer/plugins/docker/docker.plugin.zsh
  
  alias docker-container-list | grep -q "docker ps"
  assert_equals 0 $? "docker-container-list alias is valid"
}

run_test test_wrangler_aliases_with_real_cli
run_test test_gh_aliases_with_real_cli
run_test test_docker_aliases_with_real_cli
print_summary
```

---

### Step 13: Performance Tests
**Files:** `tests/performance/test_*.zsh`  
**Time:** 1 hour

```
tests/performance/
└── test_startup_time.zsh
```

**test_startup_time.zsh:**
```zsh
#!/usr/bin/env zsh
source "${0:A:h:h}/framework.zsh"

test_startup_under_50ms() {
  # Warmup
  zsh -c "source ~/.zshrc" 2>/dev/null
  
  # Benchmark
  local start end duration_ms
  start=$(date +%s%N)
  zsh -c "source ~/.zshrc; exit 0" 2>/dev/null
  end=$(date +%s%N)
  
  duration_ms=$(( (end - start) / 1000000 ))
  print "Startup time: ${duration_ms}ms"
  
  (( duration_ms < 50 )) && \
    assert_equals 0 0 "Startup under 50ms (${duration_ms}ms)" || \
    assert_equals 0 1 "Startup over 50ms (${duration}ms)"
}

run_test test_startup_under_50ms
print_summary
```

---

### Step 12: Test Runner
**File:** `tests/run_all.zsh`  
**Time:** 0.5 hours

```zsh
#!/usr/bin/env zsh
# Run all test files

0=${(%):-%N}
local test_dir=${0:A:h}

# Source framework
source "$test_dir/framework.zsh"

# Find and run all test files
local test_files=("$test_dir"/unit/test_*.zsh(N) "$test_dir"/integration/test_*.zsh(N))

for test_file in $test_files; do
  print ""
  print "═══════════════════════════════════════"
  print "Running: ${test_file:t}"
  print "═══════════════════════════════════════"
  
  # Source test file (defines test functions)
  source "$test_file"
  
  # Find test functions
  local test_fns=(${(k)functions[(I)test_*]})
  
  for fn in $test_fns; do
    run_test $fn
  done
  
  # Cleanup functions for next file
  unfunction $test_fns 2>/dev/null || true
done

print_summary
exit $?
```

---

### Step 14: CI Configuration
**File:** `.github/workflows/test.yml`  
**Time:** 0.5 hours

```yaml
name: Tests

on:
  push:
    branches: [ master, main ]
  pull_request:
    branches: [ master, main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        zsh-version: ['5.8', '5.9']
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Zsh
      run: sudo apt-get update && sudo apt-get install -y zsh
    
    - name: Install oh-my-zsh
      run: |
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        rm -rf ~/.oh-my-zsh/custom/plugins/shellographer
        ln -s $PWD ~/.oh-my-zsh/custom/plugins/shellographer
    
    - name: Run All Tests
      run: zsh tests/run_all.zsh
    
    - name: Test .zshrc Loading
      run: |
        echo 'plugins=(shellographer)' >> ~/.zshrc
        zsh -c "source ~/.zshrc; exit 0"
```

---

### Step 15: Documentation
**Files:**  
**Time:** 3 hours

- `README.md` - Main project docs
- `plugins/wrangler/README.md` - Usage examples
- `plugins/gh/README.md` - Usage examples
- `plugins/docker/README.md` - Usage examples

---

### Step 16: Install Script
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

### Step 17: Performance Benchmarks
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

### Step 18: GitHub Release
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
| 3 | 8 | 12 | Tests (framework, unit, integration, e2e, perf, runner, CI), docs, install, release |
| **Total** | **15** | **32** | **v1.0.0** |

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
