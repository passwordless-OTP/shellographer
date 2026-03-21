# shellographer/lib/alias-helper.zsh
# Safe alias creation with conflict detection

# Debug mode: set SHELLOGRAPHER_DEBUG=1 to see skip messages
typeset -g SHELLOGRAPHER_DEBUG=${SHELLOGRAPHER_DEBUG:-0}

# In-memory registry for caps discovery (lazy file write)
typeset -gA _SHELLOGRAPHER_REGISTRY

# _shellographer_alias <name> <command> [description]
# Creates alias only if no conflicts
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
  
  # Conflict detection with debug output
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
  
  # Register for caps (memory only - lazy file write)
  [[ -n $desc ]] && _SHELLOGRAPHER_REGISTRY[$name]=$desc
  
  (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Created: $name" >&2
  
  return 0
}

# _shellographer_caps_write - called by caps command, never at startup
_shellographer_caps_write() {
  local registry_file="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer/registry"
  
  # Create directory if needed
  mkdir -p "${registry_file:h}"
  
  # Write from memory to file
  for name desc in "${(@kv)_SHELLOGRAPHER_REGISTRY}"; do
    print "$name:$desc"
  done >| "$registry_file"
}

# caps - Command discovery
# Usage: caps [service]
caps() {
  local registry_file="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer/registry"
  
  # Lazy write before reading
  if (( $#_SHELLOGRAPHER_REGISTRY > 0 )); then
    _shellographer_caps_write
  fi
  
  if [[ -z "$1" ]]; then
    # List all services
    if [[ -f "$registry_file" ]]; then
      cut -d: -f1 "$registry_file" | cut -d- -f1 | sort -u
    fi
  else
    # List commands for service
    if [[ -f "$registry_file" ]]; then
      grep "^$1-" "$registry_file" 2>/dev/null | column -t -s:
    fi
  fi
}
