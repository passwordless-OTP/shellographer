# Shellographer MVP PRD (Production Ready)

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
- Load fast (no startup penalty)

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
| `gh-pr-create` | `gh pr create` | `gh-<Tab>` → `gh-pr-<Tab>` |
| `docker-container-list` | `docker ps` | `docker-<Tab>` |

### 2.3 Naming Rules
1. **Service name first**: Full CLI name, not abbreviation
2. **Action second**: Verb describing operation
3. **Resource third**: Noun being operated on
4. **Hyphen-separated**: Always use `-`
5. **No abbreviations**: Full words only

## 3. Architecture

### 3.1 Overview
Shellographer is a **single-directory oh-my-zsh plugin**. All code lives in `~/.oh-my-zsh/custom/plugins/shellographer/`.

```
~/.oh-my-zsh/custom/plugins/
└── shellographer/
    ├── shellographer.plugin.zsh      # Main loader (with guards)
    ├── README.md
    ├── lib/
    │   ├── alias-helper.zsh          # Safe alias creation
    │   └── cache-helper.zsh          # Async caching with locks
    └── plugins/
        ├── wrangler/
        │   └── wrangler.plugin.zsh
        ├── gh/
        ├── docker/
        └── ...
```

### 3.2 Install
```bash
git clone https://github.com/passwordless-OTP/shellographer.git \
  ~/.oh-my-zsh/custom/plugins/shellographer
```

```zsh
# ~/.zshrc
plugins=(shellographer)
```

### 3.3 Why `custom/plugins/`?
- `custom/` is git-ignored → survives oh-my-zsh updates
- Loaded before core plugins → can override if needed
- Standard oh-my-zsh convention

## 4. Implementation

### 4.1 Core Library: `lib/alias-helper.zsh`

**Requirements:**
- No startup file I/O (memory-only during init)
- Debug mode for troubleshooting
- Parameter validation
- Clear conflict feedback

```zsh
# lib/alias-helper.zsh

# Debug mode (set SHELLOGRAPHER_DEBUG=1 to enable)
typeset -g SHELLOGRAPHER_DEBUG=${SHELLOGRAPHER_DEBUG:-0}

# In-memory registry for caps (lazy file write)
typeset -gA _SHELLOGRAPHER_REGISTRY

# _shellographer_alias <name> <command> [description]
# Returns: 0=created, 1=skipped, 2=error
_shellographer_alias() {
  local name=$1 cmd=$2 desc=${3:-}
  
  # Validation
  if [[ -z "$name" ]]; then
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Error: empty alias name" >&2
    return 2
  fi
  
  if [[ -z "$cmd" ]]; then
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Error: empty command for $name" >&2
    return 2
  fi
  
  # Conflict detection with feedback
  if (( $+functions[$name] )); then
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Skip: $name (function exists)" >&2
    return 1
  fi
  
  if (( $+aliases[$name] )); then
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Skip: $name (alias exists)" >&2
    return 1
  fi
  
  if (( $+commands[$name] )); then
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Skip: $name (command exists)" >&2
    return 1
  fi
  
  # Create alias
  alias "$name"="$cmd"
  
  # Register in memory (file write deferred to caps command)
  [[ -n $desc ]] && _SHELLOGRAPHER_REGISTRY[$name]=$desc
  
  return 0
}

# _shellographer_caps_write - called by caps command, not at startup
_shellographer_caps_write() {
  local registry_file="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer/registry"
  mkdir -p "${registry_file:h}"
  
  # Write from memory to file
  for name desc in "${(@kv)_SHELLOGRAPHER_REGISTRY}"; do
    print "$name:$desc"
  done >| "$registry_file"
}
```

### 4.2 Cache Helper: `lib/cache-helper.zsh`

**Requirements:**
- Lock files prevent race conditions
- Async refresh with background jobs
- Stale-while-revalidate pattern
- No blocking on cache miss

```zsh
# lib/cache-helper.zsh

typeset -gA _SHELLOGRAPHER_CACHE_PID

# _shellographer_cache <name> <ttl_seconds> <command>
_shellographer_cache() {
  local name=$1 ttl=$2 cmd=$3
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer"
  local cache_file="$cache_dir/$name"
  local lock_file="$cache_dir/$name.lock"
  
  mkdir -p "$cache_dir"
  
  # Check cache freshness
  if [[ -f "$cache_file" && ! -f "$lock_file" ]]; then
    local mod_time=$(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0)
    local age=$(( $(date +%s) - mod_time ))
    
    if (( age < ttl )); then
      cat "$cache_file" 2>/dev/null
      return 0
    fi
    
    # Expired - trigger refresh in background with lock
    if [[ ! -f "$lock_file" ]]; then
      touch "$lock_file"
      (
        eval "$cmd" >| "$cache_file" 2>/dev/null
        rm -f "$lock_file"
      ) &!
      _SHELLOGRAPHER_CACHE_PID[$name]=$!
    fi
  fi
  
  # Return stale data if available
  [[ -f "$cache_file" ]] && cat "$cache_file" 2>/dev/null
  return 0
}
```

### 4.3 Main Loader: `shellographer.plugin.zsh`

**Requirements:**
- Guard against double-loading
- Explicit plugin selection (no auto-discovery for MVP)
- Graceful degradation if lib files missing
- No assumptions about loading order

```zsh
# shellographer.plugin.zsh

# Guard: Don't load twice
(( $+_SHELLOGRAPHER_LOADED )) && return 0
typeset -gr _SHELLOGRAPHER_LOADED=1

# Get plugin directory (robust)
0=${(%):-%N}
local _sdir=${0:A:h}

# Load core libraries (optional - plugins have fallbacks)
[[ -f "$_sdir/lib/alias-helper.zsh" ]] && source "$_sdir/lib/alias-helper.zsh"
[[ -f "$_sdir/lib/cache-helper.zsh" ]] && source "$_sdir/lib/cache-helper.zsh"

# Load configured plugins (explicit list for MVP)
# Users can override: SHELLOGRAPHER_PLUGINS="wrangler gh docker"
local _plugins=(${(s: :)SHELLOGRAPHER_PLUGINS:-wrangler gh})

for _plugin in $_plugins; do
  local _plugin_file="$_sdir/plugins/$_plugin/$_plugin.plugin.zsh"
  
  # Check if already loaded by this script
  local _loaded_var="_SHELLOGRAPHER_PLUGIN_${(U)_plugin}"
  (( ${(P)+_loaded_var} )) && continue
  
  if [[ -f "$_plugin_file" ]]; then
    typeset -g "${_loaded_var}=1"
    source "$_plugin_file"
  else
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Warning: Plugin '$_plugin' not found" >&2
  fi
done

unset _sdir _plugin _plugin_file _plugins _loaded_var
```

### 4.4 Plugin Template

**Requirements:**
- Works standalone or with shellographer lib
- Adds fpath before returning
- Defers compdef until compinit is available
- Guard against missing CLI

```zsh
# plugins/wrangler/wrangler.plugin.zsh

0=${(%):-%N}
local _pdir=${0:A:h}

# Add completions to fpath (do this early)
fpath+=("$_pdir")

# Guard: CLI not installed - skip aliases but keep completions
if (( ! $+commands[wrangler] )); then
  unset _pdir
  return 0
fi

# Load shellographer helpers if available (best effort)
if (( ! $+functions[_shellographer_alias] )); then
  local _helper="${_pdir:h:h}/lib/alias-helper.zsh"
  [[ -f "$_helper" ]] && source "$_helper"
fi

# Define aliases
local _aliases=(
  "wrangler-dev-server:wrangler dev:Start local dev server"
  "wrangler-deploy-worker:wrangler deploy:Deploy worker to Cloudflare"
  "wrangler-kv-list:wrangler kv:list:List KV namespaces"
)

for _entry in $_aliases; do
  local _parts=(${(s/:/)_entry})
  local _name=$_parts[1] _cmd=$_parts[2] _desc=$_parts[3]
  
  if (( $+functions[_shellographer_alias] )); then
    _shellographer_alias "$_name" "$_cmd" "$_desc"
  else
    # Fallback: manual conflict detection
    (( $+functions[$_name] || $+aliases[$_name] )) || alias "$_name=$_cmd"
  fi
done

# Register completions (only if compinit has run)
if (( $+functions[compdef] )); then
  compdef '_wrangler_complete' wrangler-dev-server 2>/dev/null || true
fi

unset _pdir _helper _aliases _entry _parts _name _cmd _desc
```

## 5. Performance Requirements

### 5.1 Startup Time
- **Target:** < 50ms for 3 plugins
- **Method:** No file I/O during init, lazy loading

### 5.2 Memory
- **Target:** < 500KB for registry
- **Method:** Sparse arrays, on-demand caching

### 5.3 Completion Latency
- **Target:** < 100ms for cached data
- **Target:** < 300ms for fresh data
- **Method:** Stale-while-revalidate caching

## 6. Testing

### 6.1 Test Structure
```
tests/
├── test_alias_helper.zsh
├── test_cache_helper.zsh
└── run_all.zsh
```

### 6.2 Key Test Cases
1. Alias creation with no conflict
2. Alias skipped when function exists
3. Alias skipped when alias exists
4. Cache hit returns immediately
5. Cache miss triggers background refresh
6. Lock file prevents duplicate refreshes
7. Plugin loads without shellographer lib
8. No errors when CLI not installed

### 6.3 CI Integration
```yaml
# .github/workflows/test.yml
- Run on: zsh 5.8, 5.9
- Test: source ~/.zshrc exits 0
- Test: no alias collisions
- Test: tab completion works
```

## 7. Anti-Goals

| Anti-Goal | Why | Alternative |
|-----------|-----|-------------|
| Auto-discovery of plugins | Slows startup | Explicit `SHELLOGRAPHER_PLUGINS` |
| Cache writes on startup | I/O blocking | Lazy write only for caps |
| Silent failures | Hard to debug | `SHELLOGRAPHER_DEBUG=1` mode |
| 22 tools for MVP | Quality loss | 3 solid tools (wrangler, gh, docker) |
| Replacing oh-my-zsh | Ecosystem friction | Work within it |

## 8. Success Criteria

- [ ] `source ~/.zshrc` exits 0
- [ ] Startup time < 50ms
- [ ] `wrangler-<Tab>` shows 5+ commands
- [ ] User's existing functions preserved
- [ ] Works without shellographer lib (standalone plugins)
- [ ] Debug mode shows useful output

## 9. Release Checklist

- [ ] All tests pass
- [ ] Documentation complete
- [ ] Install script tested on fresh system
- [ ] Performance benchmarks met
- [ ] GitHub release tagged

---

**Version:** 2.0 (Production Ready)
**Status:** Ready for implementation
