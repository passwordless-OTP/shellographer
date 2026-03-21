# shellographer/plugins/wrangler/wrangler.plugin.zsh
# Wrangler CLI aliases and completions

0=${(%):-%N}
local _pdir=${0:A:h}

# Add completions to fpath
fpath+=("$_pdir")

# Guard: Skip if wrangler not installed
if (( ! $+commands[wrangler] )); then
  unset _pdir
  return 0
fi

# Load shellographer helpers if available
if (( ! $+functions[_shellographer_alias] )); then
  local _helper="${_pdir:h:h}/lib/alias-helper.zsh"
  [[ -f "$_helper" ]] && source "$_helper"
fi

# Define aliases
local _aliases=(
  "wrangler-dev-server:wrangler dev:Start local dev server"
  "wrangler-deploy-worker:wrangler deploy:Deploy worker to Cloudflare"
  "wrangler-kv-list:wrangler kv:list:List KV namespaces"
  "wrangler-kv-get:wrangler kv:key get:Get KV value"
  "wrangler-kv-put:wrangler kv:key put:Put KV value"
  "wrangler-r2-list:wrangler r2:buckets list:List R2 buckets"
  "wrangler-tail:wrangler tail:Stream worker logs"
  "wrangler-secrets-list:wrangler secret list:List worker secrets"
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

# Completion functions (basic - can be enhanced later)
_wrangler_complete_namespaces() {
  local cache_key="wrangler/namespaces"
  local cmd="wrangler kv:namespace list --json 2>/dev/null | jq -r '.[].id'"
  
  if (( $+functions[_shellographer_cache] )); then
    _shellographer_cache "$cache_key" 300 "$cmd"
  fi
}

# Register completions if compinit available
if (( $+functions[compdef] )); then
  # Basic completions - just command names for now
  compdef '_path_files -/' wrangler-dev-server 2>/dev/null || true
fi

unset _pdir _helper _aliases _entry _parts _name _cmd _desc
