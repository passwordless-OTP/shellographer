# Shellographer Build Plan (Expanded)

## Overview
4 phases, 16 steps, ~40 hours over 4 weeks.

## Project Structure

All files in `shellographer/` directory for single-directory install:

```
~/.oh-my-zsh/custom/plugins/shellographer/
├── shellographer.plugin.zsh      # Main loader
├── README.md
├── lib/                          # Shared utilities
│   ├── alias-helper.zsh
│   ├── cache-helper.zsh
│   └── caps.zsh
└── plugins/                      # Individual tool plugins
    ├── wrangler/
    │   └── wrangler.plugin.zsh
    ├── gh/
    │   └── gh.plugin.zsh
    ├── docker/
    │   └── docker.plugin.zsh
    ├── doctl/
    ├── aws/
    └── firebase/
```

**Install:**
```bash
git clone https://github.com/passwordless-OTP/shellographer.git \
  ~/.oh-my-zsh/custom/plugins/shellographer
```

**Configure:**
```zsh
# ~/.zshrc
plugins=(shellographer)
```

---

## Phase 1: Core Infrastructure (Week 1)

### Step 1: Create Shared Library
**File:** `shellographer/lib/alias-helper.zsh`
**Time:** 2 hours
**Dependencies:** None

**Implementation:**
```zsh
# shellographer/lib/alias-helper.zsh
# Shared utilities for safe alias creation

# _shellographer_alias <name> <command> [description]
# Returns 0 if alias created, 1 if skipped (conflict)
_shellographer_alias() {
  local name=$1 cmd=$2 desc=${3:-}
  
  # Check if function exists
  (( $+functions[$name] )) && return 1
  
  # Check if alias exists
  (( $+aliases[$name] )) && return 1
  
  # Check if command exists
  (( $+commands[$name] )) && return 1
  
  # Create alias
  alias "$name"="$cmd"
  
  # Register for caps if description provided
  [[ -n $desc ]] && _shellographer_register "$name" "$desc"
  
  return 0
}

# _shellographer_register <alias> <description>
# Registers alias for caps discovery
_shellographer_register() {
  local alias=$1 desc=$2
  local registry="${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/shellographer/registry"
  mkdir -p "${registry%/*}"
  echo "$alias:$desc" >> "$registry"
}
```

**Testing:**
```zsh
# Test 1: Create alias
source shellographer/lib/alias-helper.zsh
_shellographer_alias "test-alias" "echo hello"
alias test-alias  # Should show: test-alias='echo hello'

# Test 2: Conflict with function
test-alias() { echo "function"; }
_shellographer_alias "test-alias" "echo hello"  # Should return 1
unfunction test-alias

# Test 3: Conflict with existing alias
alias test-alias="echo existing"
_shellographer_alias "test-alias" "echo hello"  # Should return 1
unalias test-alias
```

**Acceptance Criteria:**
- [ ] Sources without errors
- [ ] Creates alias when no conflict
- [ ] Returns 1 (skip) when function exists
- [ ] Returns 1 (skip) when alias exists
- [ ] Returns 1 (skip) when command exists

---

### Step 2: Create Cache Helper
**File:** `shellographer/lib/cache-helper.zsh`
**Time:** 1.5 hours
**Dependencies:** Step 1

**Implementation:**
```zsh
# shellographer/lib/cache-helper.zsh
# Async caching for completions

# _shellographer_cache <name> <ttl_seconds> <command>
# Returns cached output or runs command async
_shellographer_cache() {
  local name=$1 ttl=$2 cmd=$3
  local cache_dir="${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/shellographer"
  local cache_file="$cache_dir/$name"
  
  mkdir -p "$cache_dir"
  
  # Check if cache exists and is fresh
  if [[ -f "$cache_file" ]]; then
    local mod_time
    if [[ "$OSTYPE" == darwin* ]]; then
      mod_time=$(stat -f%m "$cache_file" 2>/dev/null)
    else
      mod_time=$(stat -c%Y "$cache_file" 2>/dev/null)
    fi
    local age=$(( $(date +%s) - ${mod_time:-0} ))
    
    if (( age < ttl )); then
      cat "$cache_file" 2>/dev/null
      return 0
    fi
  fi
  
  # Cache miss - refresh in background
  (eval "$cmd" >| "$cache_file" 2>/dev/null) &
  
  # Return stale data if available, empty otherwise
  cat "$cache_file" 2>/dev/null
  return 0
}

# _shellographer_cache_invalidate <name>
_shellographer_cache_invalidate() {
  local cache_file="${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/shellographer/$1"
  rm -f "$cache_file"
}
```

**Testing:**
```zsh
source shellographer/lib/cache-helper.zsh

# Test 1: Cache miss
_shellographer_cache "test" 60 "echo fresh"
# Should run command, cache output

# Test 2: Cache hit (within TTL)
sleep 1
_shellographer_cache "test" 60 "echo stale"
# Should return "fresh" (cached)

# Test 3: Cache expired
sleep 2
_shellographer_cache "test" 1 "echo expired"
# Should trigger refresh in background
```

---

### Step 3: Create Meta-Plugin Loader
**File:** `shellographer/shellographer.plugin.zsh`
**Time:** 1 hour
**Dependencies:** Steps 1-2

**Implementation:**
```zsh
# shellographer/shellographer.plugin.zsh
# Core plugin - provides shared utilities

# Guard: Skip if already loaded
(( $+functions[_shellographer_alias] )) && return 0

# Get plugin directory
0=${(%):-%N}
SHELLOGRAPHER_DIR="${0:A:h}"

# Load shared libraries
source "${SHELLOGRAPHER_DIR}/lib/alias-helper.zsh" 2>/dev/null || true
source "${SHELLOGRAPHER_DIR}/lib/cache-helper.zsh" 2>/dev/null || true

# Optional: Auto-load configured tools
if [[ -n "$SHELLOGRAPHER_TOOLS" ]]; then
  for tool in ${(s:,:)SHELLOGRAPHER_TOOLS}; do
    local tool_file="${SHELLOGRAPHER_DIR}/../${tool}/${tool}.plugin.zsh"
    [[ -f "$tool_file" ]] && source "$tool_file"
  done
fi
```

**Usage:**
```zsh
# ~/.zshrc
plugins=(shellographer wrangler gh docker)
# OR
SHELLOGRAPHER_TOOLS="wrangler,gh,docker"
plugins=(shellographer)
```

---

### Step 4: Create Wrangler Plugin (PoC)
**File:** `wrangler/wrangler.plugin.zsh`
**Time:** 4 hours
**Dependencies:** Step 1

**Aliases to Create:**
| Alias | Command | Description |
|-------|---------|-------------|
| `wrangler-dev-server` | `wrangler dev` | Start local dev server |
| `wrangler-deploy-worker` | `wrangler deploy` | Deploy worker |
| `wrangler-kv-list` | `wrangler kv:list` | List KV namespaces |
| `wrangler-kv-get` | `wrangler kv:key get` | Get KV value |
| `wrangler-kv-put` | `wrangler kv:key put` | Put KV value |
| `wrangler-r2-list` | `wrangler r2:buckets list` | List R2 buckets |
| `wrangler-tail` | `wrangler tail` | Stream logs |
| `wrangler-secrets-list` | `wrangler secret list` | List secrets |

**Implementation:**
```zsh
# wrangler.plugin.zsh
# PoC plugin with conflict detection

# Guard: Skip if wrangler not installed
(( $+commands[wrangler] )) || return 0

# Load shellographer lib if available
local lib="${ZSH_CUSTOM:-$ZSH/custom}/plugins/shellographer/lib/alias-helper.zsh"
[[ -f "$lib" ]] && source "$lib"

# Define aliases (with or without helper)
if (( $+functions[_shellographer_alias] )); then
  _shellographer_alias "wrangler-dev-server" "wrangler dev" "Start local dev server"
  _shellographer_alias "wrangler-deploy-worker" "wrangler deploy" "Deploy to Cloudflare"
  _shellographer_alias "wrangler-kv-list" "wrangler kv:list" "List KV namespaces"
  _shellographer_alias "wrangler-kv-get" "wrangler kv:key get" "Get KV value"
  _shellographer_alias "wrangler-kv-put" "wrangler kv:key put" "Put KV value"
  _shellographer_alias "wrangler-r2-list" "wrangler r2:buckets list" "List R2 buckets"
  _shellographer_alias "wrangler-tail" "wrangler tail" "Stream logs"
  _shellographer_alias "wrangler-secrets-list" "wrangler secret list" "List secrets"
else
  # Fallback: manual conflict detection
  (( $+functions[wrangler-dev-server] || $+aliases[wrangler-dev-server] )) || 
    alias wrangler-dev-server="wrangler dev"
  # ... etc for all 8
fi

# Basic completions ( Phase 1 - minimal)
compdef '_path_files -/' wrangler-dev-server 2>/dev/null || true
```

**Testing:**
```zsh
# Test 1: Load without errors
source wrangler/wrangler.plugin.zsh

# Test 2: Aliases exist
alias | grep wrangler-

# Test 3: Tab completion
wrangler-<Tab>  # Should show 8 options

# Test 4: No conflict with user's function
type wrangler-kv-get  # Should show alias
```

---

### Step 5: Integration Test with User's .zshrc
**Time:** 2 hours
**Dependencies:** Steps 1-4

**Test Scenarios:**

1. **Clean install**
   ```zsh
   cp -r shellographer wrangler ~/.oh-my-zsh/custom/plugins/
   # Add to ~/.zshrc: plugins=(shellographer wrangler)
   source ~/.zshrc
   echo $?  # Must be 0
   ```

2. **With user's existing functions**
   ```zsh
   # User has in .zshrc:
   wrangler-kv-get() { wrangler kv:key get "$@"; }
   
   source ~/.zshrc
   # Should not error
   # Should preserve user's function
   type wrangler-kv-get  # Shows function, not alias
   ```

3. **Tab discovery**
   ```zsh
   wrangler-<Tab>
   # Shows:
   # wrangler-deploy-worker  wrangler-kv-list
   # wrangler-dev-server     wrangler-r2-list
   # ...
   ```

**Acceptance Criteria:**
- [ ] `source ~/.zshrc` exits 0
- [ ] No parse errors
- [ ] 8 wrangler aliases available
- [ ] User's existing functions preserved
- [ ] Tab completion shows all options

---

## Phase 2: MVP Tools (Week 2)

### Step 6: GitHub Plugin
**File:** `gh/gh.plugin.zsh`
**Time:** 4 hours
**Dependencies:** Step 1

**Aliases:**
| Alias | Command | Description |
|-------|---------|-------------|
| `gh-pr-create` | `gh pr create` | Create PR |
| `gh-pr-checkout` | `gh pr checkout` | Checkout PR |
| `gh-pr-merge` | `gh pr merge` | Merge PR |
| `gh-pr-view` | `gh pr view` | View PR |
| `gh-pr-list` | `gh pr list` | List PRs |
| `gh-issue-create` | `gh issue create` | Create issue |
| `gh-issue-list` | `gh issue list` | List issues |
| `gh-repo-view` | `gh repo view` | View repo |
| `gh-workflow-list` | `gh workflow list` | List workflows |
| `gh-run-list` | `gh run list` | List workflow runs |

**Completions:**
- Dynamic PR numbers: `gh pr checkout <Tab>`
- Workflow names: `gh workflow run <Tab>`
- Cache: 60s TTL

---

### Step 7: Docker Plugin
**File:** `docker/docker.plugin.zsh`
**Time:** 3 hours

**Aliases:**
| Alias | Command |
|-------|---------|
| `docker-container-list` | `docker ps` |
| `docker-container-list-all` | `docker ps -a` |
| `docker-container-exec` | `docker exec -it` |
| `docker-container-logs` | `docker logs -f` |
| `docker-container-stop` | `docker stop` |
| `docker-container-rm` | `docker rm` |
| `docker-image-list` | `docker images` |
| `docker-image-build` | `docker build` |
| `docker-compose-up` | `docker-compose up -d` |
| `docker-compose-down` | `docker-compose down` |

**Completions:**
- Container names from `docker ps`
- Image names from `docker images`

---

### Step 8: DigitalOcean Plugin
**File:** `doctl/doctl.plugin.zsh`
**Time:** 2 hours

**Aliases:**
| Alias | Command |
|-------|---------|
| `doctl-droplet-list` | `doctl compute droplet list` |
| `doctl-droplet-create` | `doctl compute droplet create` |
| `doctl-k8s-list` | `doctl kubernetes cluster list` |
| `doctl-db-list` | `doctl databases list` |
| `doctl-app-list` | `doctl apps list` |
| `doctl-account-get` | `doctl account get` |

---

### Step 9: AWS Plugin (Basic)
**File:** `aws/aws.plugin.zsh`
**Time:** 3 hours

**Aliases (S3 + Lambda basics):**
| Alias | Command |
|-------|---------|
| `aws-s3-list` | `aws s3 ls` |
| `aws-s3-sync` | `aws s3 sync` |
| `aws-lambda-list` | `aws lambda list-functions` |
| `aws-lambda-logs` | `aws logs tail` |
| `aws-ecs-list` | `aws ecs list-services` |
| `aws-cloudformation-list` | `aws cloudformation list-stacks` |

**Note:** Full AWS completion is complex; start with common operations.

---

### Step 10: Firebase Plugin (Basic)
**File:** `firebase/firebase.plugin.zsh`
**Time:** 2 hours

**Aliases:**
| Alias | Command |
|-------|---------|
| `firebase-deploy` | `firebase deploy` |
| `firebase-deploy-hosting` | `firebase deploy --only hosting` |
| `firebase-deploy-functions` | `firebase deploy --only functions` |
| `firebase-emulators-start` | `firebase emulators:start` |
| `firebase-functions-log` | `firebase functions:log` |
| `firebase-init` | `firebase init` |

---

## Phase 3: Discovery System (Week 3)

### Step 11: Caps Command
**File:** `shellographer/lib/caps.zsh`
**Time:** 3 hours
**Dependencies:** Phase 2

**Implementation:**
```zsh
# caps - Command discovery
caps() {
  local registry="${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/shellographer/registry"
  
  if [[ -z "$1" ]]; then
    # List all services
    [[ -f "$registry" ]] && cut -d: -f1 "$registry" | cut -d- -f1 | sort -u
  else
    # List commands for service
    [[ -f "$registry" ]] && grep "^$1-" "$registry" 2>/dev/null | column -t -s:
  fi
}
```

**Usage:**
```zsh
caps              # Show: wrangler, gh, docker, doctl, aws, firebase
caps wrangler     # Show all wrangler-* aliases with descriptions
```

---

### Step 12: Enhanced Completions
**Time:** 3 hours
**Files:** Update all plugins

**Add to each plugin:**
```zsh
# Example: wrangler completions
_wrangler_complete_namespaces() {
  local cache_key="wrangler/namespaces"
  local cmd="wrangler kv:namespace list --json 2>/dev/null | jq -r '.[].title'"
  _shellographer_cache "$cache_key" 300 "$cmd"
}

# Register with compdef
compdef '_wrangler_complete_namespaces' wrangler-kv-get 2>/dev/null || true
compdef '_wrangler_complete_namespaces' wrangler-kv-put 2>/dev/null || true
```

---

### Step 13: Documentation
**Files:** Multiple READMEs
**Time:** 3 hours

**Structure:**
```
README.md                    # Main project README
├── Installation
├── Usage
├── Available Plugins
└── Philosophy

wrangler/README.md           # Per-plugin docs
├── Aliases
├── Completions
└── Examples

gh/README.md
docker/README.md
...
```

**Main README sections:**
1. One-line install
2. Philosophy (transparent technology)
3. Quick start
4. Naming convention explanation
5. Plugin list
6. Caps command usage

---

## Phase 4: Polish & Release (Week 4)

### Step 14: Install Script
**File:** `install.sh`
**Time:** 2 hours

**Features:**
```bash
#!/bin/bash
# One-line install: curl -fsSL ... | bash

# 1. Detect oh-my-zsh installation
# 2. Clone or copy plugins to custom/plugins/
# 3. Update ~/.zshrc (or print instructions)
# 4. Verify installation
```

**Modes:**
- `--all` - Install all plugins
- `--minimal` - Install wrangler, gh, docker only
- `--dry-run` - Show what would happen

---

### Step 15: Testing Suite
**Directory:** `tests/`
**Time:** 4 hours

**Tests:**
```
tests/
├── test_alias_helper.zsh      # Unit tests for _shellographer_alias
├── test_cache_helper.zsh      # Unit tests for _shellographer_cache
├── test_wrangler.zsh          # Plugin tests
├── test_gh.zsh
├── integration.zsh            # Full .zshrc integration
└── run_all.zsh                # Test runner
```

**CI:** GitHub Actions (optional)
```yaml
# .github/workflows/test.yml
- Run all tests
- Check zsh syntax
- Verify no alias collisions
```

---

### Step 16: GitHub Release
**Time:** 1 hour

**Tasks:**
- [ ] Tag v1.0.0
- [ ] Write release notes
- [ ] Create shellographer-1.0.0.tar.gz
- [ ] Update install.sh with release URL
- [ ] Test install on fresh system

---

## Summary

| Phase | Steps | Hours | Deliverables |
|-------|-------|-------|--------------|
| 1 | 5 | 10.5 | Core lib, wrangler plugin, tested |
| 2 | 5 | 14 | 5 plugins (gh, docker, doctl, aws, firebase) |
| 3 | 3 | 9 | Caps, completions, docs |
| 4 | 2 | 7 | Install script, tests, release |
| **Total** | **15** | **40.5** | v1.0.0 |

---

## Current Status

- [x] PRD expanded and committed
- [ ] Step 1: alias-helper.zsh
- [ ] Step 2: cache-helper.zsh
- [ ] Step 3: shellographer.plugin.zsh
- [ ] Step 4: wrangler.plugin.zsh
- [ ] ...

**Next:** Step 1 - Create `shellographer/lib/alias-helper.zsh`
