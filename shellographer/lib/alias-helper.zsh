# shellographer/lib/alias-helper.zsh
# Safe alias creation with conflict detection

# Debug mode: set SHELLOGRAPHER_DEBUG=1 to see skip messages
typeset -g SHELLOGRAPHER_DEBUG=${SHELLOGRAPHER_DEBUG:-0}

# In-memory registry for caps discovery (lazy file write)
# Note: caps() function is in lib/caps.zsh
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
  # The caps() function (in lib/caps.zsh) will read this
  [[ -n $desc ]] && _SHELLOGRAPHER_REGISTRY[$name]=$desc
  
  (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Created: $name" >&2
  
  return 0
}
