# Shellographer MVP PRD (Expanded)

## 1. Vision

### 1.1 Philosophy
Technology is best when it's transparent. A user hits 1-2 tabs and sees what they intended to do—not memorize syntax or read documentation.

### 1.2 Problem Statement
Current CLI workflows require:
- Memorizing command syntax (`gh pr create --title "x" --body "y"`)
- Reading man pages or `--help` output
- Context-switching between terminal and documentation
- Learning multiple CLI patterns (docker vs gh vs aws)

### 1.3 Solution
Shellographer provides **discoverable, semantic aliases** that:
- Follow predictable patterns: `<service>-<action>-<resource>`
- Reveal themselves via tab completion
- Coexist with user's existing setup
- Work within oh-my-zsh ecosystem

## 2. Naming Convention

### 2.1 Pattern
```
<service>-<action>-<resource>
```

### 2.2 Examples
| Alias | Command | Discovery Path |
|-------|---------|----------------|
| `wrangler-dev-server` | `wrangler dev` | `wran<Tab>` → `wrangler-<Tab>` |
| `wrangler-deploy-worker` | `wrangler deploy` | `wrangler-<Tab>` |
| `wrangler-kv-list` | `wrangler kv:list` | `wrangler-kv-<Tab>` |
| `wrangler-r2-list` | `wrangler r2:buckets list` | `wrangler-r2-<Tab>` |
| `gh-pr-create` | `gh pr create` | `gh-<Tab>` → `gh-pr-<Tab>` |
| `gh-pr-checkout` | `gh pr checkout` | `gh-pr-<Tab>` |
| `gh-pr-merge` | `gh pr merge` | `gh-pr-<Tab>` |
| `gh-issue-create` | `gh issue create` | `gh-issue-<Tab>` |
| `docker-container-list` | `docker ps` | `docker-<Tab>` |
| `docker-container-exec` | `docker exec -it` | `docker-container-<Tab>` |
| `docker-image-build` | `docker build` | `docker-image-<Tab>` |
| `docker-compose-up` | `docker-compose up -d` | `docker-compose-<Tab>` |

### 2.3 Naming Rules
1. **Service name first**: Full CLI name, not abbreviation (`wrangler`, not `w`)
2. **Action second**: Verb describing operation (`create`, `list`, `delete`)
3. **Resource third**: Noun being operated on (`worker`, `container`, `pr`)
4. **Hyphen-separated**: Always use `-`, never camelCase or underscores
5. **No abbreviations**: `container`, not `cnt`; `worker`, not `wrkr`

## 3. Architecture

### 3.1 Overview
Shellographer is an **oh-my-zsh enhancement layer**—not a replacement. It provides:
- Individual plugins per CLI tool
- Shared utility library for conflict detection
- Optional meta-plugin for one-line installation

### 3.2 Directory Structure

Single directory install - everything self-contained:

```
~/.oh-my-zsh/custom/plugins/
└── shellographer/                    # ← Everything lives here
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

**Usage:**
```zsh
# ~/.zshrc
plugins=(shellographer)  # Loads all or configure individually
```

### 3.3 Why `custom/plugins/`?

#### 3.3.1 Oh-My-Zsh Plugin Loading Priority

```zsh
# From oh-my-zsh.sh
for plugin ($plugins); do
  if is_plugin "$ZSH_CUSTOM" "$plugin"; then    # 1. Check custom/ first
    fpath=("$ZSH_CUSTOM/plugins/$plugin" $fpath)
  elif is_plugin "$ZSH" "$plugin"; then          # 2. Check core
    fpath=("$ZSH/plugins/$plugin" $fpath)
  else
    echo "[oh-my-zsh] plugin '$plugin' not found"
  fi
done
```

| Location | Purpose | Risk |
|----------|---------|------|
| `$ZSH_CUSTOM/plugins/` | **User-installed plugins** | Safe, survives updates |
| `$ZSH/plugins/` | Core oh-my-zsh plugins | **Overwritten on update** |

If we put shellographer in `$ZSH/plugins/`:
- `git pull` or auto-update would **overwrite** our changes
- Core plugins get reset on oh-my-zsh updates

**`custom/` is git-ignored:**
```bash
$ cat ~/.oh-my-zsh/.gitignore | grep custom
custom/
```

This means shellographer plugins **survive oh-my-zsh updates**.

#### 3.3.2 Why Not Other Locations?

| Location | Problem |
|----------|---------|
| `~/.shellographer/` | Oh-my-zsh won't load it automatically |
| `~/.oh-my-zsh/plugins/` | Gets wiped on `git pull` |
| `/usr/local/share/zsh/site-functions` | No oh-my-zsh integration |
| `~/.zshrc` directly | Messy, hard to maintain |

**`custom/plugins/` is the only location that:**
1. Integrates with oh-my-zsh plugin system
2. Survives updates (git-ignored)
3. Allows selective loading via `plugins=()`
4. Can eventually move to core via PR

### 3.4 Upstream Strategy

Shellographer follows a **progressive upstream** model:

#### Phase 1: User Installation (Now)
```zsh
# ~/.zshrc
plugins=(git docker wrangler gh doctl)  # Mix official + shellographer
```
```bash
# Install shellographer plugins
git clone https://github.com/passwordless-OTP/shellographer.git
cp -r shellographer/{wrangler,gh,docker} ~/.oh-my-zsh/custom/plugins/
```

#### Phase 2: PR to Oh-My-Zsh (Future)
Once mature, submit individual plugins to `ohmyzsh/ohmyzsh`:
```
ohmyzsh/ohmyzsh PR #1234: Add wrangler plugin
ohmyzsh/ohmyzsh PR #1235: Add gh completions
ohmyzsh/ohmyzsh PR #1236: Add docker aliases
```

After merge:
```zsh
# ~/.zshrc (after update)
plugins=(git docker wrangler gh)  # wrangler now in core!
```

#### Phase 3: Core Inclusion (Endgame)
- All plugins in oh-my-zsh main repo
- Shellographer becomes "recommended patterns" documentation
- Meta-plugin (`shellographer`) becomes thin loader

### 3.5 Meta-Plugin vs Individual Plugins

Shellographer supports **both** patterns:

#### Pattern A: Individual Plugins (Recommended)
```zsh
# ~/.zshrc
plugins=(wrangler gh docker)  # Pick only what you use
```

Each plugin is **self-contained** with fallback:
```zsh
# wrangler.plugin.zsh
if [[ -f "$ZSH_CUSTOM/plugins/shellographer/lib/alias-helper.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/shellographer/lib/alias-helper.zsh"
  _shellographer_alias "wrangler-dev-server" "wrangler dev"
else
  # Fallback: manual conflict detection
  (( $+functions[wrangler-dev-server] )) || 
    alias wrangler-dev-server="wrangler dev"
fi
```

#### Pattern B: Meta-Plugin (Optional)
```zsh
# ~/.zshrc
plugins=(shellographer)  # Loads all configured tools
```

```zsh
# shellographer.plugin.zsh
_shellographer_tools=(wrangler gh docker doctl aws firebase)

for tool in $_shellographer_tools; do
  source "${0:A:h}/tools/$tool.zsh"
done
```

**Recommendation:** Start with Pattern A (individual), add Pattern B later for convenience.

### 3.6 Core Library: `shellographer/lib/alias-helper.zsh`

```zsh
# shellographer/lib/alias-helper.zsh
# Shared utilities for safe alias creation

# _shellographer_alias <name> <command> [description]
# Creates alias only if name is not already a function or alias
_shellographer_alias() {
  local name=$1 cmd=$2 desc=${3:-}
  
  # Skip if function exists
  (( $+functions[$name] )) && return 1
  
  # Skip if alias exists
  (( $+aliases[$name] )) && return 1
  
  # Skip if command exists (for short names)
  (( $+commands[$name] )) && return 1
  
  # Create alias
  alias $name=$cmd
  
  # Register for caps discovery if desc provided
  [[ -n $desc ]] && _shellographer_register $name $desc
  
  return 0
}

# _shellographer_register <alias> <description>
# Registers alias for caps discovery system
_shellographer_register() {
  local alias=$1 desc=$2
  # Implementation for caps command
}

# _shellographer_cache <name> <ttl> <command>
# Caches command output for TTL seconds
_shellographer_cache() {
  local name=$1 ttl=$2 cmd=$3
  local cache_dir="${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/shellographer"
  local cache_file="$cache_dir/$name"
  
  mkdir -p "$cache_dir"
  
  # Check if cache is fresh
  if [[ -f "$cache_file" ]]; then
    local age=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
    (( $age < $ttl )) && cat "$cache_file" && return 0
  fi
  
  # Refresh cache
  eval "$cmd" >| "$cache_file" 2>/dev/null &|
  [[ -f "$cache_file" ]] && cat "$cache_file"
}
```

### 3.7 Plugin Template: `wrangler.plugin.zsh`

```zsh
# wrangler.plugin.zsh
# Shellographer-enhanced wrangler completions

# Guard: Skip if wrangler not installed
(( $+commands[wrangler] )) || return

# Load shellographer utilities if available
[[ -f "${ZSH_CUSTOM:-$ZSH/custom}/plugins/shellographer/lib/alias-helper.zsh" ]] && \
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/shellographer/lib/alias-helper.zsh"

# Define aliases with conflict detection
if (( $+functions[_shellographer_alias] )); then
  # Use shellographer helper
  _shellographer_alias "wrangler-dev-server" "wrangler dev" "Start local dev server"
  _shellographer_alias "wrangler-deploy-worker" "wrangler deploy" "Deploy worker to Cloudflare"
  _shellographer_alias "wrangler-kv-list" "wrangler kv:list" "List KV namespaces"
  _shellographer_alias "wrangler-kv-get" "wrangler kv:key get" "Get KV value"
  _shellographer_alias "wrangler-kv-put" "wrangler kv:key put" "Put KV value"
  _shellographer_alias "wrangler-r2-list" "wrangler r2:buckets list" "List R2 buckets"
  _shellographer_alias "wrangler-tail" "wrangler tail" "Stream worker logs"
  _shellographer_alias "wrangler-secrets-list" "wrangler secret list" "List worker secrets"
else
  # Fallback: manual conflict detection
  (( $+functions[wrangler-dev-server] || $+aliases[wrangler-dev-server] )) || alias wrangler-dev-server="wrangler dev"
  (( $+functions[wrangler-deploy-worker] || $+aliases[wrangler-deploy-worker] )) || alias wrangler-deploy-worker="wrangler deploy"
  # ... etc
fi

# Enhanced completions
_wrangler_enhanced() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # First level - main commands
  if (( CURRENT == 2 )); then
    local commands=(
      'dev:Start local dev server'
      'deploy:Deploy worker'
      'kv:KV namespace management'
      'r2:R2 bucket management'
      'tail:Stream logs'
      'secret:Secret management'
    )
    _describe -t commands "wrangler commands" commands
    return
  fi
  
  local cmd=$words[2]
  
  case "$cmd" in
    kv)
      _wrangler_kv_completion
      ;;
    r2)
      _wrangler_r2_completion
      ;;
    deploy)
      _wrangler_deploy_completion
      ;;
    *)
      _files
      ;;
  esac
}

_wrangler_kv_completion() {
  if (( CURRENT == 3 )); then
    local kv_commands=(
      'namespace:Manage namespaces'
      'key:Manage keys'
      'bulk:Bulk operations'
      'list:List namespaces'
    )
    _describe -t commands "kv commands" kv_commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    namespace|key)
      _arguments \
        '(--namespace-id)--namespace-id[Namespace ID]:id:_wrangler_kv_namespaces'
      ;;
    list)
      # No additional args
      ;;
  esac
}

_wrangler_kv_namespaces() {
  local cache_file="${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/wrangler/kv-namespaces"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    mkdir -p "${cache_file%/*}"
    wrangler kv:namespace list --json 2>/dev/null | \
      jq -r '.[] | "\(.id):\(.title)"' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file" 2>/dev/null
}

# Register completion
compdef _wrangler_enhanced wrangler 2>/dev/null || true

# Also register completions for aliases
compdef _wrangler_enhanced wrangler-dev-server 2>/dev/null || true
compdef _wrangler_enhanced wrangler-deploy-worker 2>/dev/null || true
```

## 4. Implementation Plan

### 4.1 Phase 1: Core Infrastructure (Week 1)

| Task | Effort | Deliverable |
|------|--------|-------------|
| Create `shellographer` core plugin | 4h | `lib/alias-helper.zsh` |
| Create `wrangler` plugin (PoC) | 6h | 8 aliases + completions |
| Test with user's .zshrc | 2h | No conflicts verified |
| Documentation | 2h | README for each plugin |

### 4.2 Phase 2: MVP Tools (Week 2-3)

| Tool | Aliases | Completions | Effort |
|------|---------|-------------|--------|
| wrangler | 8 | KV, R2, secrets, tail | 6h |
| gh | 10 | PRs, issues, workflows | 8h |
| docker | 8 | Containers, images, compose | 6h |
| doctl | 6 | Droplets, k8s, databases | 4h |
| aws | 6 | S3, ECS, Lambda basics | 6h |
| firebase | 6 | Hosting, functions, emulators | 4h |

### 4.3 Phase 3: Discovery System (Week 4)

| Task | Effort | Deliverable |
|------|--------|-------------|
| `caps` command | 4h | List all services |
| `caps <service>` | 2h | List service commands |
| Cache indexing | 4h | Fast lookup |
| Integration | 2h | Works with all plugins |

## 5. Requirements

### 5.1 P0: Never Break .zshrc

**Acceptance Criteria:**
```zsh
source ~/.zshrc
echo $?  # Must be 0
```

**Implementation:**
- Conflict detection before every alias definition
- Graceful fallback if shellographer lib unavailable
- No dependencies on external tools beyond the CLI itself

### 5.2 P0: Tab-Discoverable

**Acceptance Criteria:**
```zsh
$ wrangler-<Tab>
wrangler-dev-server     wrangler-kv-list
wrangler-deploy-worker  wrangler-r2-list
wrangler-kv-get         wrangler-tail
wrangler-kv-put         wrangler-secrets-list
```

**Implementation:**
- All aliases follow `<service>-<action>-<resource>` pattern
- Hyphens enable progressive discovery via tab completion
- Completions provide descriptions

### 5.3 P0: Coexist with User's Setup

**Acceptance Criteria:**
- User's `ghprc()` function continues working
- User's `alias ghpr='gh pr'` preserved
- Shellographer fills gaps, doesn't overwrite

**Implementation:**
```zsh
# Before defining alias, check:
(( $+functions[gh-pr-create] )) && return  # Skip if function exists
(( $+aliases[gh-pr-create] )) && return    # Skip if alias exists
(( $+commands[gh-pr-create] )) && return   # Skip if command exists
```

### 5.4 P1: MVP Tools (6)

| Priority | Tool | Aliases | Completions |
|----------|------|---------|-------------|
| P0 | wrangler | 8 | KV, R2, secrets, tail, deploy |
| P0 | gh | 10 | PRs, issues, workflows, releases |
| P1 | docker | 8 | Containers, images, compose, networks |
| P1 | doctl | 6 | Droplets, k8s, databases, apps |
| P2 | aws | 6 | S3, Lambda, ECS, CloudFormation |
| P2 | firebase | 6 | Hosting, functions, emulators, storage |

### 5.5 P1: Core Utilities

```zsh
# shellographer/lib/alias-helper.zsh

_shellographer_alias() {
  local name=$1 cmd=$2 desc=$3
  (( $+functions[$name] || $+aliases[$name] || $+commands[$name] )) && return 1
  alias $name=$cmd
  return 0
}

_shellographer_cache() {
  local name=$1 ttl=$2 cmd=$3
  # Cache implementation
}

_shellographer_register_caps() {
  local alias=$1 service=$2 desc=$3
  # Register for caps discovery
}
```

### 5.6 P2: Discovery System

```zsh
$ caps
Service        Commands    Status
───────        ────────    ──────
wrangler       8           ✅
gh             10          ✅
docker         8           ✅
doctl          6           ✅
aws            6           ⏳ (not installed)
firebase       6           ⏳ (not installed)

$ caps wrangler
Alias                      Description
─────                      ───────────
wrangler-dev-server        Start local dev server
wrangler-deploy-worker     Deploy worker to Cloudflare
wrangler-kv-list           List KV namespaces
wrangler-kv-get            Get KV value
wrangler-kv-put            Put KV value
wrangler-r2-list           List R2 buckets
wrangler-tail              Stream worker logs
wrangler-secrets-list      List worker secrets
```

### 5.7 P2: Rich Completions

**Dynamic Data Sources:**
- PR numbers from `gh pr list`
- Container names from `docker ps`
- Droplets from `doctl compute droplet list`
- KV namespaces from `wrangler kv:namespace list`

**Caching Strategy:**
| Data Type | TTL | Source |
|-----------|-----|--------|
| PR numbers | 60s | `gh pr list` |
| Containers | 30s | `docker ps` |
| Droplets | 300s | `doctl compute droplet list` |
| KV namespaces | 300s | `wrangler kv:namespace list` |
| Workflows | 300s | `gh workflow list` |

## 6. Success Criteria

### 6.1 Functional
1. `source ~/.zshrc` exits 0
2. `wrangler-<Tab>` shows 5+ commands
3. User's existing functions preserved
4. No alias collisions

### 6.2 UX
1. User never reads docs to find a command
2. Commands discoverable in ≤2 tabs
3. Pattern predictable after first use

### 6.3 Performance
1. Plugin load time < 50ms
2. Completion latency < 100ms
3. Cache refresh async (non-blocking)

## 7. Anti-Goals

| Anti-Goal | Why | Alternative |
|-----------|-----|-------------|
| Short aliases (`wd`, `ghprc`) | Requires memorization | Full semantic names |
| 22 tools for MVP | Scope creep, quality loss | 6 focused tools |
| Breaking existing setups | Violates P0 | Conflict detection |
| Replacing oh-my-zsh | We enhance it | Work within ecosystem |
| Complex configuration | Friction | Zero-config defaults |
| Mandatory dependencies | Fragility | Graceful fallbacks |

## 8. Testing Strategy

### 8.1 Unit Tests
```zsh
# Test _shellographer_alias
test_alias_collision() {
  # Setup: Define function
  gh-pr-create() { echo "existing"; }
  
  # Action: Try to create alias
  _shellographer_alias "gh-pr-create" "gh pr create"
  
  # Assert: Alias not created
  (( $+aliases[gh-pr-create] )) && return 1 || return 0
}
```

### 8.2 Integration Tests
```zsh
# Test with full .zshrc
test_zshrc_load() {
  zsh -c "source ~/.zshrc" 2>&1
  [[ $? -eq 0 ]]
}
```

### 8.3 User Acceptance
- [ ] User can discover `wrangler-deploy-worker` without docs
- [ ] User's `ghprc()` function still works
- [ ] Tab completion shows descriptions

## 9. Rollout Plan

### 9.1 Internal (This Week)
1. Build `shellographer` core + `wrangler` plugin
2. Test with your `.zshrc`
3. Iterate on naming

### 9.2 Alpha (Next Week)
1. Add `gh`, `docker` plugins
2. Test with 2-3 colleagues
3. Gather feedback

### 9.3 Public (Month 1)
1. Publish to GitHub
2. Submit PRs to oh-my-zsh (individual plugins)
3. Blog post / Show HN

## 10. Future Roadmap

### 10.1 Phase 2: More Tools
- `kubectl` (k8s ecosystem)
- `terraform` / `pulumi` (IaC)
- `npm` / `pnpm` / `yarn` (package managers)
- `vercel` / `netlify` (hosting)

### 10.2 Phase 3: AI Integration
- Natural language to alias: "deploy my worker" → `wrangler-deploy-worker`
- Context-aware suggestions based on directory

### 10.3 Phase 4: Upstream
- All plugins in oh-my-zsh main repo
- Shellographer becomes "best practices" documentation

## 11. Appendix

### 11.1 Alias Naming Cheat Sheet

| Service | Resource | Actions |
|---------|----------|---------|
| wrangler | worker, kv, r2, secret, d1 | create, deploy, list, get, put, delete, tail |
| gh | pr, issue, repo, workflow, release | create, list, view, checkout, merge, close |
| docker | container, image, network, volume | list, build, run, exec, stop, rm |
| doctl | droplet, k8s, db, app | list, create, delete, resize |

### 11.2 Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-20 | Individual plugins vs monolith | Follows oh-my-zsh conventions |
| 2026-03-20 | `<service>-<action>-<resource>` | Tab-discoverable, semantic |
| 2026-03-20 | Conflict detection required | Never break .zshrc (P0) |
| 2026-03-20 | 6 tools for MVP | Quality over quantity |

---

**Version:** 1.0 (Expanded)
**Last Updated:** 2026-03-20
**Status:** Draft
