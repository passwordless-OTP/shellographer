# caps - minimal alias discovery
# Usage: caps [service]
#
# Discover available aliases by service:
#   caps              List all services
#   caps docker       List docker aliases
#   caps wrangler     List wrangler aliases

caps() {
  local cache=${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}
  local idx=$cache/caps/idx
  local plugins=${ZSH:-$HOME/.oh-my-zsh}/plugins
  [[ $idx -nt $plugins ]] || {
    mkdir -p $cache/caps
    awk -F'=' '/^# caps:category/{gsub(/ /,"",$2); c=$2} /^alias [a-z]/{if(c){n=$1; gsub(/.*alias /,"",n); s=FILENAME; gsub(/.*\/|\.plugin\.zsh/,"",s); print s,c,n; c=""}}' $plugins/*/*.plugin.zsh 2>/dev/null >$idx
  }
  [[ $1 ]] && grep "^$1" $idx 2>/dev/null | column -t || cut -d' ' -f1 $idx 2>/dev/null | sort -u | column
}
