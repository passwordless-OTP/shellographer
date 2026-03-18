# Wrangler - Cloudflare Workers CLI completions
# https://developers.cloudflare.com/workers/wrangler/
# ============================================================================

(( $+commands[wrangler] )) || return

# ============================================================================
# WRANGLER CONFIGURATION PARSING
# ============================================================================

# Find wrangler.toml or wrangler.json
_wrangler_find_config() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/wrangler.toml" ]] && { echo "$dir/wrangler.toml"; return }
    [[ -f "$dir/wrangler.json" ]] && { echo "$dir/wrangler.json"; return }
    dir=$(dirname "$dir")
  done
}

# Parse environments from wrangler.toml
_wrangler_envs() {
  local config=$(_wrangler_find_config)
  [[ -z "$config" ]] && return
  
  local -a envs
  if [[ "$config" == *.json ]]; then
    envs=($(cat "$config" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("\n".join(d.get("env", {}).keys()))' 2>/dev/null))
  else
    # Parse TOML env sections
    envs=($(grep -E '^\[env\.' "$config" 2>/dev/null | sed 's/\[env\.//;s/\]//'))
  fi
  
  # Add default empty environment
  echo ""
  for env in $envs; do
    echo "$env"
  done
}

# Parse scripts/entry points from wrangler.toml
_wrangler_scripts() {
  local config=$(_wrangler_find_config)
  [[ -z "$config" ]] && return
  
  local main_script=""
  if [[ "$config" == *.json ]]; then
    main_script=$(cat "$config" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("main", ""))' 2>/dev/null)
  else
    main_script=$(grep -E '^main\s*=' "$config" 2>/dev/null | head -1 | sed 's/.*=\s*["\']\([^"\']*\)["\'].*/\1/')
  fi
  
  [[ -n "$main_script" ]] && echo "worker:$main_script"
  
  # List other JS/TS files in src/
  if [[ -d src ]]; then
    for f in src/*.ts src/*.js src/*.tsx src/*.jsx; do
      [[ -f "$f" ]] && echo "$f"
    done
  fi
}

# Parse KV namespaces
_wrangler_kv_namespaces() {
  local config=$(_wrangler_find_config)
  [[ -z "$config" ]] && return
  
  if [[ "$config" == *.json ]]; then
    cat "$config" | python3 -c 'import json,sys; d=json.load(sys.stdin); [print(f"{n.get(\"binding\", \"\")}:{n.get(\"id\", \"\")}") for n in d.get("kv_namespaces", [])]' 2>/dev/null
  else
    # Parse TOML - extract kv_namespaces array
    python3 << PYEOF 2>/dev/null
import tomllib, sys
with open("$config", "rb") as f:
    data = tomllib.load(f)
    for ns in data.get("kv_namespaces", []):
        binding = ns.get("binding", "")
        id_val = ns.get("id", "")
        preview_id = ns.get("preview_id", "")
        print(f"{binding}:{id_val}")
PYEOF
  fi
}

# Parse D1 databases
_wrangler_d1_databases() {
  local config=$(_wrangler_find_config)
  [[ -z "$config" ]] && return
  
  if [[ "$config" == *.json ]]; then
    cat "$config" | python3 -c 'import json,sys; d=json.load(sys.stdin); [print(f"{db.get(\"binding\", \"\")}:{db.get(\"database_name\", \"\")}:{db.get(\"database_id\", \"\")}") for db in d.get("d1_databases", [])]' 2>/dev/null
  else
    python3 << PYEOF 2>/dev/null
import tomllib, sys
with open("$config", "rb") as f:
    data = tomllib.load(f)
    for db in data.get("d1_databases", []):
        binding = db.get("binding", "")
        name = db.get("database_name", "")
        db_id = db.get("database_id", "")
        print(f"{binding}:{name}:{db_id}")
PYEOF
  fi
}

# Parse R2 buckets
_wrangler_r2_buckets() {
  local config=$(_wrangler_find_config)
  [[ -z "$config" ]] && return
  
  if [[ "$config" == *.json ]]; then
    cat "$config" | python3 -c 'import json,sys; d=json.load(sys.stdin); [print(f"{b.get(\"binding\", \"\")}:{b.get(\"bucket_name\", \"\")}") for b in d.get("r2_buckets", [])]' 2>/dev/null
  else
    python3 << PYEOF 2>/dev/null
import tomllib, sys
with open("$config", "rb") as f:
    data = tomllib.load(f)
    for bucket in data.get("r2_buckets", []):
        binding = bucket.get("binding", "")
        name = bucket.get("bucket_name", "")
        print(f"{binding}:{name}")
PYEOF
  fi
}

# Get routes from wrangler.toml
_wrangler_routes() {
  local config=$(_wrangler_find_config)
  [[ -z "$config" ]] && return
  
  if [[ "$config" == *.json ]]; then
    cat "$config" | python3 -c 'import json,sys; d=json.load(sys.stdin); [print(r) for r in d.get("routes", [])]' 2>/dev/null
  else
    # Parse routes array from TOML
    python3 << PYEOF 2>/dev/null
import tomllib, sys
with open("$config", "rb") as f:
    data = tomllib.load(f)
    for route in data.get("routes", []):
        if isinstance(route, str):
            print(route)
        elif isinstance(route, dict):
            print(f"{route.get('pattern', '')} -> {route.get('script', '')}")
PYEOF
  fi
}

# ============================================================================
# CLOUDFLARE API COMPLETIONS (cached)
# ============================================================================

_wrangler_cache_dir="${ZSH_CACHE_DIR}/wrangler"
mkdir -p "$_wrangler_cache_dir"

# List Cloudflare accounts
_wrangler_accounts() {
  local cache="$_wrangler_cache_dir/accounts"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache" 2>/dev/null || stat -c%Y "$cache" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache" || $fresh -gt 3600 ]]; then
    wrangler account list 2>/dev/null | grep -E '^│' | awk -F'│' '{print $3 ":" $2}' | sed 's/ //g' >| "$cache" &|
  fi
  
  [[ -f "$cache" ]] && cat "$cache"
}

# List deployed worker scripts
_wrangler_deployed_scripts() {
  local cache="$_wrangler_cache_dir/scripts"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache" 2>/dev/null || stat -c%Y "$cache" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache" || $fresh -gt 300 ]]; then
    wrangler deploy --dry-run 2>/dev/null || true
    # Fallback: try to list from API
    wrangler kv:namespace list 2>/dev/null | head -1 || true
  fi
  
  [[ -f "$cache" ]] && cat "$cache"
}

# List KV namespace IDs (for commands that need ID not binding)
_wrangler_kv_ids() {
  _wrangler_kv_namespaces | cut -d: -f2
}

# ============================================================================
# COMPLETION FUNCTIONS
# ============================================================================

# Complete wrangler environments
_wrangler_complete_envs() {
  local -a envs=(${(f)"$(_wrangler_envs)"})
  _describe -t envs "environments" envs
}

# Complete wrangler scripts
_wrangler_complete_scripts() {
  local -a scripts=(${(f)"$(_wrangler_scripts)"})
  _describe -t scripts "scripts" scripts
}

# Complete KV namespaces
_wrangler_complete_kv_namespaces() {
  local -a namespaces=(${(f)"$(_wrangler_kv_namespaces)"})
  _describe -t namespaces "KV namespaces" namespaces
}

# Complete KV namespace IDs
_wrangler_complete_kv_ids() {
  local -a ids=(${(f)"$(_wrangler_kv_ids)"})
  compadd $ids
}

# Complete D1 databases
_wrangler_complete_d1() {
  local -a dbs=(${(f)"$(_wrangler_d1_databases)"})
  _describe -t dbs "D1 databases" dbs
}

# Complete R2 buckets
_wrangler_complete_r2() {
  local -a buckets=(${(f)"$(_wrangler_r2_buckets)"})
  _describe -t buckets "R2 buckets" buckets
}

# Complete routes
_wrangler_complete_routes() {
  local -a routes=(${(f)"$(_wrangler_routes)"})
  _describe -t routes "routes" routes
}

# Complete local files (for script paths)
_wrangler_complete_files() {
  _files -g '*.ts' -g '*.js' -g '*.tsx' -g '*.jsx' -g '*.wasm'
}

# Complete compatibility dates
_wrangler_complete_compatibility_dates() {
  local -a dates
  local current_year=$(date +%Y)
  local current_month=$(date +%m)
  
  # Generate recent dates (Cloudflare usually supports last 2 years)
  for year in $((current_year)) $((current_year-1)); do
    for month in {01..12}; do
      if [[ $year -lt $current_year || $month -le $current_month ]]; then
        dates+=("$year-$month-01")
      fi
    done
  done
  
  compadd $dates
}

# Complete log levels
_wrangler_complete_log_levels() {
  local -a levels=("debug" "info" "log" "warn" "error")
  compadd $levels
}

# Main wrangler completion
_wrangler_completion() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local -a wrangler_cmds=(
    "dev:Start local development server"
    "deploy:Deploy your Worker to Cloudflare"
    "publish:Publish your Worker (deprecated, use deploy)"
    "tail:Start a tailing session for logs"
    "kv:Key-value storage management"
    "r2:Object storage management"
    "d1:Database management"
    "queues:Queue management"
    "pages:Pages project management"
    "secrets:Secret management"
    "versions:Worker versions management"
    "triggers:Trigger management"
    "subdomain:Configure worker subdomain"
    "route:Route management"
    "login:Authenticate with Cloudflare"
    "logout:Logout from Cloudflare"
    "whoami:Show current user"
    "status:Check authentication status"
    "docs:Open docs in browser"
    "init:Create new project"
    "generate:Generate new project from template"
    "config:Configuration management"
    "types:Generate types from bindings"
  )
  
  _arguments -C \
    '(-h --help)'{-h,--help}'[Show help]' \
    '(-v --version)'{-v,--version}'[Show version]' \
    '(-c --config)'{-c,--config}'[Path to config]:config:_files' \
    '(-e --env)'{-e,--env}'[Environment]:env:_wrangler_complete_envs' \
    '--compatibility-date[Compatibility date]:date:_wrangler_complete_compatibility_dates' \
    '--compatibility-flags[Compatibility flags]:flags:' \
    '1: :->command' \
    '*:: :->args'
  
  case "$state" in
    command)
      _describe -t commands "wrangler commands" wrangler_cmds
      ;;
    args)
      local cmd=$line[1]
      local subcmd=$line[2]
      
      case "$cmd" in
        dev)
          _arguments \
            '(-h --help)'{-h,--help}'[Show help]' \
            '--local[Run locally]' \
            '--remote[Run with remote resources]' \
            '--ip[IP address]:ip:' \
            '(-p --port)'{-p,--port}'[Port]:port:' \
            '--inspector-port[DevTools port]:port:' \
            '--routes[Routes]:routes:' \
            '--host[Host]:host:' \
            '1:script:_wrangler_complete_scripts' \
            '*:: :_wrangler_complete_files'
          ;;
        deploy|publish)
          _arguments \
            '(-h --help)'{-h,--help}'[Show help]' \
            '--dry-run[Show what would be deployed]' \
            '--minify[Minify script]' \
            '--no-bundle[Disable bundling]' \
            '--keep-vars[Keep existing vars]' \
            '--triggers[Deploy triggers only]' \
            '--routes[Deploy routes only]' \
            '--no-routes[Skip routes]' \
            '1:script:_wrangler_complete_scripts' \
            '*: :_files'
          ;;
        kv)
          if (( CURRENT == 2 )); then
            local -a kv_cmds=(
              "namespace:Manage namespaces"
              "key:Manage key-value pairs"
              "bulk:Bulk operations"
            )
            _describe -t kv_cmds "KV commands" kv_cmds
          else
            case "$subcmd" in
              namespace)
                if (( CURRENT == 3 )); then
                  local -a ns_cmds=("list:List namespaces" "create:Create namespace" "delete:Delete namespace")
                  _describe -t ns_cmds "namespace commands" ns_cmds
                fi
                ;;
              key)
                if (( CURRENT == 3 )); then
                  local -a key_cmds=("get:Get value" "put:Set value" "delete:Delete key" "list:List keys")
                  _describe -t key_cmds "key commands" key_cmds
                else
                  case "$line[3]" in
                    get|put|delete|list)
                      _arguments \
                        '--binding[Binding name]:binding:_wrangler_complete_kv_namespaces' \
                        '--namespace-id[Namespace ID]:id:_wrangler_complete_kv_ids' \
                        '--env[Environment]:env:_wrangler_complete_envs' \
                        '--preview[Use preview namespace]' \
                        ':key:'
                      ;;
                  esac
                fi
                ;;
            esac
          fi
          ;;
        d1)
          if (( CURRENT == 2 )); then
            local -a d1_cmds=(
              "create:Create database"
              "list:List databases"
              "delete:Delete database"
              "backup:Backup operations"
              "execute:Execute SQL"
              "migrations:Manage migrations"
            )
            _describe -t d1_cmds "D1 commands" d1_cmds
          else
            _arguments \
              '--name[Database name]:name:_wrangler_complete_d1' \
              '--database-id[Database ID]:id:' \
              '--env[Environment]:env:_wrangler_complete_envs' \
              ': :'
          fi
          ;;
        r2)
          if (( CURRENT == 2 )); then
            local -a r2_cmds=(
              "bucket:Manage buckets"
              "object:Manage objects"
            )
            _describe -t r2_cmds "R2 commands" r2_cmds
          else
            case "$subcmd" in
              bucket)
                if (( CURRENT == 3 )); then
                  local -a bucket_cmds=("create:Create bucket" "delete:Delete bucket" "list:List buckets")
                  _describe -t bucket_cmds "bucket commands" bucket_cmds
                fi
                ;;
              object)
                _arguments \
                  '--bucket[Bucket name]:bucket:_wrangler_complete_r2' \
                  '--prefix[Key prefix]:prefix:' \
                  ': :'
                ;;
            esac
          fi
          ;;
        pages)
          if (( CURRENT == 2 )); then
            local -a pages_cmds=(
              "dev:Start dev server"
              "deploy:Deploy project"
              "project:Manage project"
            )
            _describe -t pages_cmds "Pages commands" pages_cmds
          fi
          ;;
        queues)
          if (( CURRENT == 2 )); then
            local -a queue_cmds=(
              "create:Create queue"
              "list:List queues"
              "delete:Delete queue"
              "consumer:Manage consumers"
            )
            _describe -t queue_cmds "Queue commands" queue_cmds
          fi
          ;;
        secrets)
          if (( CURRENT == 2 )); then
            local -a secret_cmds=("put:Set secret" "delete:Delete secret" "list:List secrets")
            _describe -t secret_cmds "secret commands" secret_cmds
          else
            _arguments \
              '--name[Secret name]:name:' \
              '--env[Environment]:env:_wrangler_complete_envs' \
              ': :'
          fi
          ;;
        tail)
          _arguments \
            '(-h --help)'{-h,--help}'[Show help]' \
            '--format[Output format]:format:(pretty json)' \
            '--status[Filter by status]:status:(ok error canceled)' \
            '--ip[Filter by IP]:ip:' \
            '--search[Search term]:term:' \
            '--debug[Debug mode]' \
            '--legacy[Legacy tail]' \
            '1:script:_wrangler_complete_scripts'
          ;;
        init|generate)
          _arguments \
            '--name[Project name]:name:' \
            '--template[Template]:template:' \
            '--type[Project type]:type:(webpack rust javascript typescript)' \
            '*: :_files -/'
          ;;
        *)
          _files
          ;;
      esac
      ;;
  esac
}

compdef _wrangler_completion wrangler

# ============================================================================
# WRANGLER ALIASES
# ============================================================================

# caps:category=core
# caps:desc=Start development server
alias wd='wrangler dev'

# caps:category=deployment
# caps:desc=Deploy worker to Cloudflare
alias wdeploy='wrangler deploy'

# caps:category=deployment
# caps:desc=Dry run deployment
alias wdry='wrangler deploy --dry-run'
alias wpub='wrangler publish'
alias wtail='wrangler tail'
alias wkv='wrangler kv'
alias wkvns='wrangler kv namespace'
alias wkvkey='wrangler kv key'
alias wd1='wrangler d1'
alias wr2='wrangler r2'
alias wsecret='wrangler secret'
alias wwho='wrangler whoami'
alias wstat='wrangler status'

# Development shortcuts
alias wdev='wrangler dev --local'
alias wdevr='wrangler dev --remote'
alias wdeploy='wrangler deploy'
alias wdry='wrangler deploy --dry-run'

# KV shortcuts
# caps:category=data
# caps:desc=List KV namespaces
alias wkvlist='wrangler kv namespace list'

# caps:category=data
# caps:desc=List D1 databases
alias wd1list='wrangler d1 list'
alias wkvd='wrangler kv namespace delete'
alias wkvget='wrangler kv key get'
alias wkvput='wrangler kv key put'
alias wkvdel='wrangler kv key delete'

# D1 shortcuts
alias wd1list='wrangler d1 list'
alias wd1c='wrangler d1 create'
alias wd1d='wrangler d1 delete'
alias wd1sql='wrangler d1 execute'

# Pages shortcuts
alias wpages='wrangler pages'
alias wpagesd='wrangler pages dev'
alias wpagesp='wrangler pages deploy'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Quick deploy with message
wdeploy-msg() {
  local msg="${1:-Deploy from $(date +%Y-%m-%d\ %H:%M)}"
  wrangler deploy --message "$msg"
}

# Create D1 migration
wd1-migrate() {
  local name="${1:-migration_$(date +%Y%m%d_%H%M%S)}"
  wrangler d1 migrations create "$name"
}

# List KV keys in a namespace
wkv-keys() {
  local binding="$1"
  local prefix="${2:-}"
  [[ -z "$binding" ]] && { echo "Usage: wkv-keys <binding> [prefix]"; return 1 }
  
  if [[ -n "$prefix" ]]; then
    wrangler kv key list --binding="$binding" --prefix="$prefix"
  else
    wrangler kv key list --binding="$binding"
  fi
}

# Export D1 database to SQL
wd1-export() {
  local db_name="$1"
  local output="${2:-${db_name}_$(date +%Y%m%d).sql}"
  [[ -z "$db_name" ]] && { echo "Usage: wd1-export <database-name> [output.sql]"; return 1 }
  
  wrangler d1 export "$db_name" --output="$output"
  echo "Exported to $output"
}

# Quick tail with search
wtail-search() {
  local term="$1"
  [[ -z "$term" ]] && { echo "Usage: wtail-search <search-term>"; return 1 }
  wrangler tail --search="$term"
}

# Show wrangler config info
winfo() {
  local config=$(_wrangler_find_config)
  if [[ -n "$config" ]]; then
    echo "=== Wrangler Config ==="
    echo "Config file: $config"
    echo ""
    echo "=== Environments ==="
    _wrangler_envs | grep -v '^$' || echo "(default only)"
    echo ""
    echo "=== KV Namespaces ==="
    _wrangler_kv_namespaces || echo "(none defined)"
    echo ""
    echo "=== D1 Databases ==="
    _wrangler_d1_databases || echo "(none defined)"
    echo ""
    echo "=== R2 Buckets ==="
    _wrangler_r2_buckets || echo "(none defined)"
  else
    echo "No wrangler.toml/wrangler.json found"
    return 1
  fi
}

# Initialize wrangler project with common setup
winit() {
  local name="${1:-$(basename $PWD)}"
  local type="${2:-typescript}"
  
  wrangler init "$name" --type "$type"
  
  # Create common directories
  mkdir -p src tests
  
  echo ""
  echo "Created wrangler project: $name"
  echo "Run 'wrangler dev' to start development"
}
