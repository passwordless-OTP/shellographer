# shellographer/lib/caps.zsh
# Command discovery for shellographer

# _shellographer_caps_write - persist registry to file
# Called by caps command, never at startup (lazy write)
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
#   caps          - List all services
#   caps wrangler - List commands for service
caps() {
  local service=${1:-}
  local registry_file="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer/registry"
  
  # Lazy write before reading (only if registry exists and has entries)
  if (( ${+_SHELLOGRAPHER_REGISTRY} )) && (( $#_SHELLOGRAPHER_REGISTRY > 0 )); then
    _shellographer_caps_write
  fi
  
  if [[ -z "$service" ]]; then
    # List all services (first part of alias name)
    if [[ -f "$registry_file" ]]; then
      cut -d: -f1 "$registry_file" | cut -d- -f1 | sort -u
    fi
  else
    # List commands for specific service
    if [[ -f "$registry_file" ]]; then
      grep "^${service}-" "$registry_file" 2>/dev/null | column -t -s:
    fi
  fi
}

# caps-clear - Clear discovery cache
caps-clear() {
  local registry_file="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer/registry"
  
  if [[ -f "$registry_file" ]]; then
    rm -f "$registry_file"
    (( ${+SHELLOGRAPHER_DEBUG} && SHELLOGRAPHER_DEBUG )) && print "[shellographer] Caps cache cleared" >&2
  fi
  
  # Also clear in-memory registry (if it exists)
  if (( ${+_SHELLOGRAPHER_REGISTRY} )); then
    _SHELLOGRAPHER_REGISTRY=()
  fi
}
