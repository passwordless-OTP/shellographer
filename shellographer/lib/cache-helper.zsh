# shellographer/lib/cache-helper.zsh
# Async caching with lock files for completion data

# Track background cache refresh PIDs
typeset -gA _SHELLOGRAPHER_CACHE_PID

# _shellographer_cache <name> <ttl_seconds> <command>
# Returns cached data, triggers async refresh if expired
# Uses stale-while-revalidate pattern
_shellographer_cache() {
  local name=$1 ttl=$2 cmd=$3
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer"
  local cache_file="$cache_dir/$name"
  local lock_file="$cache_dir/$name.lock"
  
  # Ensure cache directory exists
  mkdir -p "$cache_dir"
  
  # Check if cache exists and is fresh
  if [[ -f "$cache_file" && ! -f "$lock_file" ]]; then
    local mod_time age
    
    # Get modification time (macOS/BSD vs Linux)
    if [[ "$OSTYPE" == darwin* ]]; then
      mod_time=$(stat -f%m "$cache_file" 2>/dev/null)
    else
      mod_time=$(stat -c%Y "$cache_file" 2>/dev/null)
    fi
    
    mod_time=${mod_time:-0}
    age=$(( $(date +%s) - mod_time ))
    
    # Cache hit - return immediately
    if (( age < ttl )); then
      cat "$cache_file" 2>/dev/null
      return 0
    fi
    
    # Cache expired - trigger async refresh with lock
    if [[ ! -f "$lock_file" ]]; then
      touch "$lock_file"
      (
        eval "$cmd" >| "$cache_file" 2>/dev/null
        rm -f "$lock_file"
      ) &!
      _SHELLOGRAPHER_CACHE_PID[$name]=$!
    fi
  fi
  
  # Return stale data if available, empty otherwise
  if [[ -f "$cache_file" ]]; then
    cat "$cache_file" 2>/dev/null
    return 0
  fi
  
  # No cache - run command synchronously
  local output
  output=$(eval "$cmd" 2>/dev/null)
  print -n "$output" >| "$cache_file"
  print "$output"
  return 0
}

# _shellographer_cache_invalidate <name>
# Force cache refresh on next call
_shellographer_cache_invalidate() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer"
  local cache_file="$cache_dir/$1"
  local lock_file="$cache_dir/$1.lock"
  
  rm -f "$cache_file" "$lock_file"
}

# _shellographer_cache_clear
# Clear all cached data
_shellographer_cache_clear() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer"
  
  if [[ -d "$cache_dir" ]]; then
    rm -rf "$cache_dir"
    (( ${+SHELLOGRAPHER_DEBUG} && SHELLOGRAPHER_DEBUG )) && print "[shellographer] Cache cleared" >&2
  fi
}

# _shellographer_cache_status
# Show cache statistics (for debugging)
_shellographer_cache_status() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/shellographer"
  
  if [[ ! -d "$cache_dir" ]]; then
    print "Cache directory does not exist"
    return 0
  fi
  
  print "Cache directory: $cache_dir"
  print ""
  
  local file
  for file in "$cache_dir"/*(.N); do
    [[ "$file" == *.lock ]] && continue
    
    local name=${file:t}
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    local mod_time
    
    if [[ "$OSTYPE" == darwin* ]]; then
      mod_time=$(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null)
    else
      mod_time=$(stat -c%y "$file" 2>/dev/null | cut -d. -f1)
    fi
    
    local locked=""
    [[ -f "$file.lock" ]] && locked=" [refreshing]"
    
    printf "%-30s %6s bytes  %s%s\n" "$name" "$size" "${mod_time:-unknown}" "$locked"
  done
  
  if (( ${#_SHELLOGRAPHER_CACHE_PID} > 0 )); then
    print ""
    print "Background jobs:"
    local name pid
    for name pid in "${(@kv)_SHELLOGRAPHER_CACHE_PID}"; do
      if kill -0 "$pid" 2>/dev/null; then
        print "  $name: PID $pid (running)"
      else
        print "  $name: PID $pid (finished)"
      fi
    done
  fi
}
