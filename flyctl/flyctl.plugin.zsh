# Fly.io CLI (flyctl) - Comprehensive completions
# https://fly.io/

if (( ! $+commands[flyctl] )); then
  return
fi

# ============================================================
# CACHE AND STATE MANAGEMENT
# ============================================================

_flyctl_cache_dir="${ZSH_CACHE_DIR}/flyctl"
mkdir -p "$_flyctl_cache_dir"

# Get apps (cached)
_flyctl_apps() {
  local cache_file="$_flyctl_cache_dir/apps"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    flyctl apps list --json 2>/dev/null | \
      python3 -c "import json,sys; [print(f\"{a['Name']}:{a.get('Organization',{}).get('Name','')} [{a['Status']}]\") for a in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get regions (cached)
_flyctl_regions() {
  local cache_file="$_flyctl_cache_dir/regions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 3600 ]]; then
    flyctl platform regions --json 2>/dev/null | \
      python3 -c "import json,sys; [print(f\"{r['Code']}:{r['Name']} ({r['GatewayAvailable'] and 'gateway' or 'no gateway'})\") for r in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get organizations (cached)
_flyctl_orgs() {
  local cache_file="$_flyctl_cache_dir/orgs"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    flyctl orgs list --json 2>/dev/null | \
      python3 -c "import json,sys; [print(f\"{o['Name']}:{o.get('Type','')}\") for o in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get volumes (cached)
_flyctl_volumes() {
  local cache_file="$_flyctl_cache_dir/volumes"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    flyctl volumes list --json 2>/dev/null | \
      python3 -c "import json,sys; [print(f\"{v['id']}:{v.get('name','')} ({v['size_gb']}GB) [{v['state']}]\") for v in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get machines (cached)
_flyctl_machines() {
  local cache_file="$_flyctl_cache_dir/machines"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    flyctl machines list --json 2>/dev/null | \
      python3 -c "import json,sys; [print(f\"{m['id']}:{m.get('name','')} [{m['state']}]\") for m in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get Postgres clusters (cached)
_flyctl_postgres() {
  local cache_file="$_flyctl_cache_dir/postgres"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    flyctl postgres list --json 2>/dev/null | \
      python3 -c "import json,sys; [print(f\"{p['Name']}:{p.get('Organization','')} [{p['Status']}]\") for p in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get Redis databases (cached)
_flyctl_redis() {
  local cache_file="$_flyctl_cache_dir/redis"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    flyctl redis list --json 2>/dev/null | \
      python3 -c "import json,sys; [print(f\"{r['Name']}:{r.get('Organization','')} [{r['Status']}]\") for r in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get WireGuard peers (cached)
_flyctl_wireguard() {
  local cache_file="$_flyctl_cache_dir/wireguard"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    flyctl wireguard list --json 2>/dev/null | \
      python3 -c "import json,sys; [print(f\"{w['Name']}:{w.get('Region','')}\") for w in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get static IPs (cached)
_flyctl_ips() {
  local cache_file="$_flyctl_cache_dir/ips"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    flyctl ips list --json 2>/dev/null | \
      python3 -c "import json,sys; [print(f\"{i['Address']}:{i['Type']} ({i.get('Region','')})\") for i in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get secrets (cached - names only)
_flyctl_secrets() {
  local cache_file="$_flyctl_cache_dir/secrets"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    flyctl secrets list --json 2>/dev/null | \
      python3 -c "import json,sys; [print(s['Name']) for s in json.load(sys.stdin)]" 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Known Fly.io regions (fallback)
_flyctl_regions_fallback() {
  local regions=(
    'ams:Amsterdam, Netherlands'
    'cdg:Paris, France'
    'dfw:Dallas, Texas (US)'
    'ewr:Secaucus, NJ (US)'
    'fra:Frankfurt, Germany'
    'gru:São Paulo, Brazil'
    'hkg:Hong Kong'
    'iad:Ashburn, Virginia (US)'
    'jnb:Johannesburg, South Africa'
    'lax:Los Angeles, California (US)'
    'lhr:London, United Kingdom'
    'maa:Chennai (Madras), India'
    'mad:Madrid, Spain'
    'mia:Miami, Florida (US)'
    'nrt:Tokyo, Japan'
    'ord:Chicago, Illinois (US)'
    'otp:Bucharest, Romania'
    'phx:Phoenix, Arizona (US)'
    'qro:Querétaro, Mexico'
    'scl:Santiago, Chile'
    'sea:Seattle, Washington (US)'
    'sin:Singapore'
    'sjc:San Jose, California (US)'
    'syd:Sydney, Australia'
    'waw:Warsaw, Poland'
    'yul:Montreal, Canada'
    'yyz:Toronto, Canada'
  )
  print -l "${regions[@]}"
}

# VM sizes
_flyctl_vm_sizes() {
  local sizes=(
    'shared-cpu-1x:Shared CPU (1x) - 256MB'
    'shared-cpu-2x:Shared CPU (2x) - 512MB'
    'shared-cpu-4x:Shared CPU (4x) - 1GB'
    'shared-cpu-8x:Shared CPU (8x) - 2GB'
    'dedicated-cpu-1x:Dedicated CPU (1x) - 2GB'
    'dedicated-cpu-2x:Dedicated CPU (2x) - 4GB'
    'dedicated-cpu-4x:Dedicated CPU (4x) - 8GB'
    'dedicated-cpu-8x:Dedicated CPU (8x) - 16GB'
    'performance-1x:Performance (1x) - 2GB'
    'performance-2x:Performance (2x) - 4GB'
    'performance-4x:Performance (4x) - 8GB'
    'performance-8x:Performance (8x) - 16GB'
    'performance-16x:Performance (16x) - 32GB'
    'a100-40gb:A100 (40GB) - GPU'
    'a100-80gb:A100 (80GB) - GPU'
    'l40s:L40S - GPU'
  )
  print -l "${sizes[@]}"
}

# Postgres configurations
_flyctl_postgres_configs() {
  local configs=(
    'development:Development (single node)'
    'high-availability:High Availability (2 nodes)'
    'production:Production (3+ nodes)'
    'stolon:Stolon (legacy)'
    'flex:Flex (new)'
  )
  print -l "${configs[@]}"
}

# ============================================================
# MAIN COMPLETION FUNCTION
# ============================================================

_flyctl() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # Global options
  if [[ "$cur" == -* ]] && (( CURRENT == 2 )); then
    _flyctl_global_options
    return
  fi
  
  # First level - commands
  if (( CURRENT == 2 )); then
    if [[ "$cur" != -* ]]; then
      _flyctl_commands
    else
      _flyctl_global_options
    fi
    return
  fi
  
  local cmd=$words[2]
  
  # Complete based on command
  case "$cmd" in
    apps)
      _flyctl_apps_completion
      ;;
    deploy|launch)
      _flyctl_deploy_completion
      ;;
    status|info)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--config[Config]:file:_files'
      ;;
    machines)
      _flyctl_machines_completion
      ;;
    volumes)
      _flyctl_volumes_completion
      ;;
    postgres)
      _flyctl_postgres_completion
      ;;
    redis)
      _flyctl_redis_completion
      ;;
    regions)
      _flyctl_regions_completion
      ;;
    autoscale)
      _flyctl_autoscale_completion
      ;;
    certs)
      _flyctl_certs_completion
      ;;
    consul)
      _flyctl_consul_completion
      ;;
    dashboard)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--browser[Open browser]' \
        '--no-browser[No browser]'
      ;;
    dig)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--ipv4[IPv4 only]' \
        '--ipv6[IPv6 only]' \
        '*:hostname: '
      ;;
    doctor)
      _arguments \
        '--verbose[Verbose]' \
        '--no-color[No color]'
      ;;
    ips)
      _flyctl_ips_completion
      ;;
    logs)
      _flyctl_logs_completion
      ;;
    open)
      _arguments \
        '--app[App]:app:_flyctl_apps'
      ;;
    orgs)
      _flyctl_orgs_completion
      ;;
    ping)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--region[Region]:region:_flyctl_regions' \
        '--verbose[Verbose]'
      ;;
    platform)
      _flyctl_platform_completion
      ;;
    proxy)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--remote-host[Remote host]:host: ' \
        '--remote-port[Remote port]:port: ' \
        '--local-port[Local port]:port: ' \
        '--quiet[Quiet]'
      ;;
    releases)
      _flyctl_releases_completion
      ;;
    secrets)
      _flyctl_secrets_completion
      ;;
    services)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--json[JSON output]'
      ;;
    sftp)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--region[Region]:region:_flyctl_regions' \
        '--machine[MACHINE]:machine:_flyctl_machines' \
        '*:path: '
      ;;
    ssh)
      _flyctl_ssh_completion
      ;;
    storage)
      _flyctl_storage_completion
      ;;
    turboku)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--org[Org]:org:_flyctl_orgs' \
        '--name[Name]:name: ' \
        '--region[Region]:region:_flyctl_regions'
      ;;
    version)
      # No options
      ;;
    wireguard)
      _flyctl_wireguard_completion
      ;;
    agent)
      _arguments \
        'ping:Ping' \
        'restart:Restart' \
        'start:Start' \
        'stop:Stop' \
        'run:Run'
      ;;
    auth)
      _flyctl_auth_completion
      ;;
    config)
      _flyctl_config_completion
      ;;
    history)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--json[JSON]'
      ;;
    image)
      _flyctl_image_completion
      ;;
    settings)
      _arguments \
        'analytics:Analytics' \
        'autoupdate:Auto-update'
      ;;
    tokens)
      _flyctl_tokens_completion
      ;;
    *)
      _files
      ;;
  esac
}

_flyctl_global_options() {
  local -a options
  options=(
    '--access-token[Access token]:token: '
    '-t[Access token]:token: '
    '--app[App name]:app:_flyctl_apps'
    '-a[App name]:app:_flyctl_apps'
    '--config[Config file]:file:_files'
    '-c[Config file]:file:_files'
    '--debug[Debug mode]'
    '--verbose[Verbose output]'
    '--quiet[Quiet mode]'
    '-q[Quiet mode]'
    '--json[JSON output]'
    '-j[JSON output]'
    '--help[Show help]'
    '-h[Show help]'
    '--org[Organization]:org:_flyctl_orgs'
    '-o[Organization]:org:_flyctl_orgs'
  )
  _describe -t options "flyctl options" options
}

_flyctl_commands() {
  local -a commands
  commands=(
    'agent:Fly agent'
    'apps:App management'
    'auth:Authentication'
    'autoscale:Autoscaling'
    'certs:Certificates'
    'config:Configuration'
    'consul:Consul'
    'dashboard:Dashboard'
    'deploy:Deploy app'
    'destroy:Destroy app'
    'dig:DNS debugging'
    'doctor:Troubleshoot'
    'history:History'
    'image:Image management'
    'info:App info'
    'ips:IP addresses'
    'launch:Launch app'
    'logs:View logs'
    'machine:Machine management'
    'mpg:Managed Postgres'
    'open:Open browser'
    'orgs:Organizations'
    'ping:Ping app'
    'platform:Platform info'
    'postgres:Postgres'
    'proxy:Proxy to app'
    'redis:Redis'
    'regions:Regions'
    'releases:Releases'
    'restart:Restart app'
    'resume:Resume app'
    'scale:Scale app'
    'secrets:Secrets'
    'services:Services'
    'settings:Settings'
    'sftp:SFTP'
    'ssh:SSH'
    'status:App status'
    'storage:Storage'
    'suspend:Suspend app'
    'tokens:Tokens'
    'turboku:Heroku migrator'
    'version:Version'
    'vm:VM commands'
    'volume:Volumes'
    'wireguard:WireGuard'
  )
  _describe -t commands "flyctl commands" commands
}

# Apps completions
_flyctl_apps_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create app'
      'destroy:Destroy app'
      'list:List apps'
      'move:Move app'
      'open:Open app'
      'releases:Releases'
      'rename:Rename app'
      'restart:Restart app'
      'resume:Resume app'
      'set-status:Set status'
      'suspend:Suspend app'
    )
    _describe -t commands "apps commands" commands
    return
  fi
  
  local action=$words[3]
  
  case "$action" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--org[Org]:org:_flyctl_orgs' \
        '--network[Network]:network: ' \
        '--generate-name[Generate name]' \
        '--consul[Enable Consul]' \
        '--shared[Shared]' \
        '--secrets[Secrets]:secrets: ' \
        '--dockerfile[Dockerfile]:file:_files' \
        '--image[Image]:image: ' \
        '--builder[Builder]:builder: ' \
        '--import[Import]:file:_files' \
        '--machines[Machines]' \
        '--nomad[Nomad]' \
        '--dockerignore-from-gitignore[Dockerignore from gitignore]'
      ;;
    destroy|move|rename|restart|resume|suspend|open|set-status)
      _arguments \
        '--yes[Skip confirm]' \
        '-y[Skip confirm]' \
        '*:app:_flyctl_apps'
      ;;
    releases)
      _arguments \
        '--image[Show image]' \
        '*:app:_flyctl_apps'
      ;;
    list)
      _arguments \
        '--org[Org filter]:org:_flyctl_orgs' \
        '--status[Status filter]:status: ' \
        '--json[JSON]'
      ;;
  esac
}

_flyctl_apps() {
  local apps=(${(f)"$(_flyctl_apps)"})
  _describe -t apps "apps" apps
}

# Deploy completion
_flyctl_deploy_completion() {
  _arguments \
    '--app[App]:app:_flyctl_apps' \
    '-a[App]:app:_flyctl_apps' \
    '--config[Config]:file:_files' \
    '-c[Config]:file:_files' \
    '--dockerfile[Dockerfile]:file:_files' \
    '--image[Image]:image: ' \
    '--image-label[Image label]:label: ' \
    '--build-arg[Build args]:args: ' \
    '--build-target[Target]:target: ' \
    '--build-pack[Buildpack]:pack: ' \
    '--builder[Builder]:builder: ' \
    '--remote-only[Remote build only]' \
    '--local-only[Local build only]' \
    '--push[Push image]' \
    '--no-push[No push]' \
    '--detach[Detach]' \
    '--strategy[Strategy]:strategy:(rolling immediate canary bluegreen)' \
    '--env[Env vars]:envs: ' \
    '--env-from-file[Env file]:file:_files' \
    '--vm-size[VM size]:size:_flyctl_vm_sizes' \
    '--vm-cpus[CPUs]:count: ' \
    '--vm-memory[Memory]:memory: ' \
    '--region[Region]:region:_flyctl_regions' \
    '--regions[Regions]:regions: ' \
    '--process-group[Process group]:group: ' \
    '--no-cache[No cache]' \
    '--no-public-ips[No public IPs]' \
    '--always-use-builtin-volumes[Builtin volumes]' \
    '--build-secret[Build secrets]:secrets: ' \
    '--volume[Volume]:volume:_flyctl_volumes' \
    '--lease-timeout[Lease timeout]:duration: ' \
    '--wait-timeout[Wait timeout]:duration: ' \
    '--smoke-checks[Smoke checks]:count: ' \
    '--max-unavailable[Max unavailable]:count: ' \
    '--release-command-timeout[Release timeout]:duration: ' \
    '--no-release-command-timeout[No release timeout]' \
    '--max-running[Max running]:count: ' \
    '--release-command-max-concurrent[Max concurrent]:count: ' \
    '--wait[Wait]' \
    '--no-wait[No wait]' \
    '--ha[High availability]' \
    '--no-ha[No HA]' \
    '--console[Console]' \
    '--no-console[No console]' \
    '--provision-extensions[Provision extensions]' \
    '--update-extensions-only[Update extensions]' \
    '--auto-confirm[Auto confirm]'
}

# Machines completion
_flyctl_machines_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'api-proxy:API proxy'
      'clone:Clone machine'
      'cordon:Cordon machine'
      'destroy:Destroy machine'
      'exec:Exec on machine'
      'kill:Kill machine'
      'launch:Launch machine'
      'leases:Machine leases'
      'list:List machines'
      'notes:Machine notes'
      'restart:Restart machine'
      'run:Run machine'
      'start:Start machine'
      'status:Machine status'
      'stop:Stop machine'
      'uncordon:Uncordon'
      'update:Update machine'
    )
    _describe -t commands "machines commands" commands
    return
  fi
  
  local action=$words[3]
  
  case "$action" in
    launch|run|clone)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--name[Name]:name: ' \
        '--region[Region]:region:_flyctl_regions' \
        '--vm-size[Size]:size:_flyctl_vm_sizes' \
        '--vm-cpus[CPUs]:count: ' \
        '--vm-memory[Memory]:memory: ' \
        '--dockerfile[Dockerfile]:file:_files' \
        '--image[Image]:image: ' \
        '--command[Command]:cmd: ' \
        '--entrypoint[Entrypoint]:entry: ' \
        '--env[Env]:envs: ' \
        '--port[Ports]:ports: ' \
        '--file-local[Local files]:files: ' \
        '--file-literal[Literal files]:files: ' \
        '--file-secret[Secret files]:files: ' \
        '--volume[Volume]:vol:_flyctl_volumes' \
        '--ls-volume[LS volume]:vol: ' \
        '--process-group[Process group]:group: ' \
        '--schedule[Schedule]:schedule: ' \
        '--metadata[Metadata]:meta: ' \
        '--skip-start[Skip start]' \
        '--id[ID]:id: ' \
        '--from-snapshot[Snapshot]:snap: ' \
        '--host-dedication-id[Dedication]:id: '
      ;;
    destroy|kill|restart|start|stop|status|update|exec|notes|leases|cordon|uncordon)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--force[Force]' \
        '--select[Select]' \
        '--wait-timeout[Timeout]:duration: ' \
        '-i[Instance]:id: ' \
        '*:machine:_flyctl_machines'
      ;;
    list)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--quiet[Quiet]' \
        '-q[Quiet]' \
        '--json[JSON]' \
        '-j[JSON]'
      ;;
  esac
}

_flyctl_machines() {
  local machines=(${(f)"$(_flyctl_machines)"})
  _describe -t machines "machines" machines
}

# Volumes completion
_flyctl_volumes_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create volume'
      'destroy:Destroy volume'
      'extend:Extend volume'
      'fork:Fork volume'
      'list:List volumes'
      'show:Show volume'
      'snapshots:Snapshots'
    )
    _describe -t commands "volumes commands" commands
    return
  fi
  
  local action=$words[3]
  
  case "$action" in
    create)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--region[Region]:region:_flyctl_regions' \
        '-r[Region]:region:_flyctl_regions' \
        '--size[Size GB]:size: ' \
        '--snapshot[Snapshot]:snap: ' \
        '--fs-type[Filesystem]:fs:(ext4 xfs)' \
        '--encrypted[Encrypted]' \
        '--no-encrypted[Not encrypted]' \
        '--machines[Machines only]' \
        '-m[Machines only]' \
        '--require-unique-zone[Unique zone]' \
        '--count[Count]:count: ' \
        '--name[Name]:name: ' \
        '*:name: '
      ;;
    destroy|extend|fork|show|snapshots)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--yes[Skip confirm]' \
        '-y[Skip confirm]' \
        '*:volume:_flyctl_volumes'
      ;;
    list)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--json[JSON]'
      ;;
  esac
}

_flyctl_volumes() {
  local volumes=(${(f)"$(_flyctl_volumes)"})
  _describe -t volumes "volumes" volumes
}

# Postgres completion
_flyctl_postgres_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'attach:Attach'
      'barman:Backups (barman)'
      'config:Config'
      'connect:Connect'
      'create:Create'
      'db:Database'
      'detach:Detach'
      'events:Events'
      'failover:Failover'
      'list:List'
      'regions:Regions'
      'restart:Restart'
      'users:Users'
    )
    _describe -t commands "postgres commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--org[Org]:org:_flyctl_orgs' \
        '--region[Region]:region:_flyctl_regions' \
        '--config-uid[Config]:config: ' \
        '--initial-cluster-size[Cluster size]:size: ' \
        '--vm-size[VM size]:size:_flyctl_vm_sizes' \
        '--volume-size[Volume]:size: ' \
        '--memory[Memory]:memory: ' \
        '--password[Password]:pass: ' \
        '--password-stdin[Password from stdin]' \
        '--snapshot-id[Snapshot]:id: ' \
        '--fork-from[Fork from]:from: ' \
        '--image-ref[Image]:ref: ' \
        '--autostart[Autostart]' \
        '--no-autostart[No autostart]' \
        '--ha[High availability]' \
        '--no-ha[No HA]' \
        '--machines[Machines]' \
        '--nomad[Nomad]' \
        '--stolon[Stolon]' \
        '--flex[Flex]'
      ;;
    attach|detach|connect|failover|restart|db|users|regions|config|events|barman)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '--yes[Skip confirm]' \
        '-y[Skip confirm]' \
        '--managed[Managed]' \
        '--cluster[Cluster]:cluster:_flyctl_postgres_clusters' \
        '*:postgres:_flyctl_postgres_clusters'
      ;;
    list)
      _arguments \
        '--org[Org]:org:_flyctl_orgs' \
        '--json[JSON]'
      ;;
  esac
}

_flyctl_postgres_clusters() {
  local clusters=(${(f)"$(_flyctl_postgres)"})
  _describe -t clusters "postgres clusters" clusters
}

# Redis completion
_flyctl_redis_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create'
      'dashboard:Dashboard'
      'destroy:Destroy'
      'list:List'
      'plans:Plans'
      'proxy:Proxy'
      'regions:Regions'
      'reset:Reset'
      'status:Status'
      'update:Update'
    )
    _describe -t commands "redis commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--org[Org]:org:_flyctl_orgs' \
        '--region[Region]:region:_flyctl_regions' \
        '--plan[Plan]:plan: ' \
        '--eviction[Eviction]' \
        '--no-eviction[No eviction]'
      ;;
    destroy|status|update|reset|proxy|dashboard)
      _arguments \
        '--yes[Skip confirm]' \
        '-y[Skip confirm]' \
        '*:redis:_flyctl_redis'
      ;;
    list)
      _arguments \
        '--org[Org]:org:_flyctl_orgs' \
        '--json[JSON]'
      ;;
  esac
}

_flyctl_redis() {
  local redis=(${(f)"$(_flyctl_redis)"})
  _describe -t redis "redis databases" redis
}

# Regions completion
_flyctl_regions_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'add:Add region'
      'backup:Backup regions'
      'list:List regions'
      'remove:Remove region'
      'set:Set regions'
    )
    _describe -t commands "regions commands" commands
    return
  fi
  
  _arguments \
    '--app[App]:app:_flyctl_apps' \
    '-a[App]:app:_flyctl_apps' \
    '--group[Group]:group: ' \
    '-g[Group]:group: ' \
    '--yes[Skip confirm]' \
    '-y[Skip confirm]' \
    '*:region:_flyctl_regions'
}

_flyctl_regions() {
  local regions=(${(f)"$(_flyctl_regions)"})
  if [[ ${#regions[@]} -eq 0 ]]; then
    regions=(${(f)"$(_flyctl_regions_fallback)"})
  fi
  _describe -t regions "regions" regions
}

# Autoscale completion
_flyctl_autoscale_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'disable:Disable'
      'set:Set'
      'show:Show'
    )
    _describe -t commands "autoscale commands" commands
    return
  fi
  
  local action=$words[3]
  
  case "$action" in
    set)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--min-count[Min]:count: ' \
        '--max-count[Max]:count: '
      ;;
    disable|show)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps'
      ;;
  esac
}

# Certs completion
_flyctl_certs_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'add:Add certificate'
      'check:Check certificate'
      'delete:Delete certificate'
      'list:List certificates'
      'show:Show certificate'
    )
    _describe -t commands "certs commands" commands
    return
  fi
  
  _arguments \
    '--app[App]:app:_flyctl_apps' \
    '-a[App]:app:_flyctl_apps' \
    '--hostname[Hostname]:host: ' \
    '-n[Hostname]:host: ' \
    '--yes[Skip confirm]' \
    '-y[Skip confirm]' \
    '--check[Check]' \
    '--cerfile[Cert file]:file:_files' \
    '--keyfile[Key file]:file:_files' \
    '--chain[Chain file]:file:_files' \
    '*:cert: '
}

# Consul completion
_flyctl_consul_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'attach:Attach'
      'detach:Detach'
      'list:List'
    )
    _describe -t commands "consul commands" commands
    return
  fi
  
  _arguments \
    '--app[App]:app:_flyctl_apps' \
    '-a[App]:app:_flyctl_apps' \
    '--org[Org]:org:_flyctl_orgs' \
    '-o[Org]:org:_flyctl_orgs' \
    '*:consul: '
}

# IPs completion
_flyctl_ips_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'allocate:Allocate'
      'allocate-v6:Allocate IPv6'
      'list:List IPs'
      'private:Private IPs'
      'release:Release IP'
    )
    _describe -t commands "ips commands" commands
    return
  fi
  
  local action=$words[3]
  
  case "$action" in
    allocate|allocate-v6)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--region[Region]:region:_flyctl_regions' \
        '--yes[Skip confirm]' \
        '-y[Skip confirm]' \
        '--shared[Shared]' \
        '--no-shared[Not shared]'
      ;;
    release)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--yes[Skip confirm]' \
        '-y[Skip confirm]' \
        '*:ip:_flyctl_ips'
      ;;
    list|private)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--json[JSON]'
      ;;
  esac
}

_flyctl_ips() {
  local ips=(${(f)"$(_flyctl_ips)"})
  _describe -t ips "IPs" ips
}

# Logs completion
_flyctl_logs_completion() {
  _arguments \
    '--app[App]:app:_flyctl_apps' \
    '-a[App]:app:_flyctl_apps' \
    '--instance[Instance]:instance:_flyctl_machines' \
    '-i[Instance]:instance:_flyctl_machines' \
    '--region[Region]:region:_flyctl_regions' \
    '-r[Region]:region:_flyctl_regions' \
    '--no-tail[No tail]' \
    '-n[No tail]' \
    '--verbose[Verbose]' \
    '-v[Verbose]' \
    '--json[JSON]' \
    '-j[JSON]'
}

# Orgs completion
_flyctl_orgs_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create'
      'delete:Delete'
      'invite:Invite'
      'list:List'
      'remove:Remove'
      'revoke:Revoke'
      'show:Show'
    )
    _describe -t commands "orgs commands" commands
    return
  fi
  
  local action=$words[3]
  
  case "$action" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--personal[Personal]'
      ;;
    delete|show|invite|remove|revoke)
      _arguments \
        '--org[Org]:org:_flyctl_orgs' \
        '-o[Org]:org:_flyctl_orgs' \
        '--yes[Skip confirm]' \
        '-y[Skip confirm]' \
        '--email[Email]:email: ' \
        '-e[Email]:email: ' \
        '--user[User]:user: ' \
        '-u[User]:user: ' \
        '*:org:_flyctl_orgs'
      ;;
    list)
      _arguments \
        '--json[JSON]'
      ;;
  esac
}

_flyctl_orgs() {
  local orgs=(${(f)"$(_flyctl_orgs)"})
  _describe -t orgs "organizations" orgs
}

# Platform completion
_flyctl_platform_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'regions:Regions'
      'status:Status'
      'vm-sizes:VM sizes'
      'vmsizes:VM sizes'
    )
    _describe -t commands "platform commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    regions)
      _arguments \
        '--json[JSON]' \
        '*:region:_flyctl_regions'
      ;;
    vm-sizes|vmsizes)
      _arguments \
        '--json[JSON]' \
        '*:size:_flyctl_vm_sizes'
      ;;
    status)
      _arguments \
        '--json[JSON]'
      ;;
  esac
}

# Releases completion
_flyctl_releases_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'list:List releases'
      'notes:Release notes'
    )
    _describe -t commands "releases commands" commands
    return
  fi
  
  _arguments \
    '--app[App]:app:_flyctl_apps' \
    '-a[App]:app:_flyctl_apps' \
    '--image[Show image]' \
    '--json[JSON]' \
    '*:release: '
}

# Secrets completion
_flyctl_secrets_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'deploy:Deploy secrets'
      'import:Import secrets'
      'list:List secrets'
      'set:Set secret'
      'unset:Unset secret'
    )
    _describe -t commands "secrets commands" commands
    return
  fi
  
  local action=$words[3]
  
  case "$action" in
    set)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--stage[Stage only]' \
        '-s[Stage only]' \
        '--detach[Detach]' \
        '-d[Detach]' \
        '--verbose[Verbose]' \
        '--from-literal[From literal]:literals: ' \
        '--from-file[From file]:files:_files' \
        '-f[From file]:files:_files' \
        '--from-yaml[From YAML]:yaml:_files' \
        '--yaml[From YAML]:yaml:_files' \
        '*:name: '
      ;;
    unset)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--stage[Stage only]' \
        '-s[Stage only]' \
        '--detach[Detach]' \
        '-d[Detach]' \
        '--verbose[Verbose]' \
        '*:secret:_flyctl_secrets'
      ;;
    deploy)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--stage[Stage only]' \
        '-s[Stage only]' \
        '--detach[Detach]' \
        '-d[Detach]' \
        '--verbose[Verbose]'
      ;;
    import)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--stage[Stage only]' \
        '-s[Stage only]' \
        '--detach[Detach]' \
        '-d[Detach]' \
        '--verbose[Verbose]' \
        '*:file:_files'
      ;;
    list)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--stage[Stage only]' \
        '-s[Stage only]' \
        '--verbose[Verbose]'
      ;;
  esac
}

_flyctl_secrets() {
  local secrets=(${(f)"$(_flyctl_secrets)"})
  _describe -t secrets "secrets" secrets
}

# SSH completion
_flyctl_ssh_completion() {
  _arguments \
    '--app[App]:app:_flyctl_apps' \
    '-a[App]:app:_flyctl_apps' \
    '--machine[MACHINE]:machine:_flyctl_machines' \
    '-s[MACHINE]:machine:_flyctl_machines' \
    '--region[Region]:region:_flyctl_regions' \
    '-r[Region]:region:_flyctl_regions' \
    '--command[Command]:cmd: ' \
    '-C[Command]:cmd: ' \
    '--pty[Allocate PTY]' \
    '-t[Allocate PTY]' \
    '--select[Select]' \
    '-s[Select]' \
    '--quiet[Quiet]' \
    '-q[Quiet]' \
    '--user[User]:user: ' \
    '-u[User]:user: ' \
    '--identity[Identity]:file:_files' \
    '-i[Identity]:file:_files' \
    '--agent-forwarding[Agent forwarding]' \
    '-A[Agent forwarding]' \
    '--disable-pty[Disable PTY]' \
    '-T[Disable PTY]' \
    '--probe[Probe]' \
    '-p[Probe]' \
    '--wait-timeout[Timeout]:duration: ' \
    '-w[Timeout]:duration: ' \
    '--verbose[Verbose]' \
    '-v[Verbose]' \
    '-vv[Very verbose]' \
    '*:command: '
}

# Storage completion
_flyctl_storage_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create'
      'destroy:Destroy'
      'list:List'
      'show:Show'
      'update:Update'
    )
    _describe -t commands "storage commands" commands
    return
  fi
  
  local action=$words[3]
  
  case "$action" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--org[Org]:org:_flyctl_orgs' \
        '-o[Org]:org:_flyctl_orgs' \
        '--region[Region]:region:_flyctl_regions' \
        '-r[Region]:region:_flyctl_regions'
      ;;
    destroy|show|update)
      _arguments \
        '--org[Org]:org:_flyctl_orgs' \
        '-o[Org]:org:_flyctl_orgs' \
        '--yes[Skip confirm]' \
        '-y[Skip confirm]' \
        '*:storage: '
      ;;
    list)
      _arguments \
        '--org[Org]:org:_flyctl_orgs' \
        '-o[Org]:org:_flyctl_orgs' \
        '--json[JSON]'
      ;;
  esac
}

# WireGuard completion
_flyctl_wireguard_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create'
      'list:List'
      'remove:Remove'
      'reset:Reset'
      'token:Token'
      'websockets:WebSockets'
    )
    _describe -t commands "wireguard commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--org[Org]:org:_flyctl_orgs' \
        '--region[Region]:region:_flyctl_regions' \
        '--hostname[Hostname]:host: '
      ;;
    remove|reset|token)
      _arguments \
        '--org[Org]:org:_flyctl_orgs' \
        '--name[Name]:name: ' \
        '*:peer:_flyctl_wireguard'
      ;;
    list)
      _arguments \
        '--org[Org]:org:_flyctl_orgs' \
        '--json[JSON]'
      ;;
    websockets)
      _arguments \
        'enable:Enable' \
        'disable:Disable' \
        'status:Status' \
        '--org[Org]:org:_flyctl_orgs'
      ;;
  esac
}

_flyctl_wireguard() {
  local peers=(${(f)"$(_flyctl_wireguard)"})
  _describe -t peers "wireguard peers" peers
}

# Auth completion
_flyctl_auth_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'docker:Docker'
      'login:Login'
      'logout:Logout'
      'signup:Signup'
      'token:Token'
      'whoami:Whoami'
    )
    _describe -t commands "auth commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    login)
      _arguments \
        '--email[Email]:email: ' \
        '--password[Password]:pass: ' \
        '--otp[OTP]:otp: ' \
        '--interactive[Interactive]' \
        '-i[Interactive]' \
        '--browser-only[Browser only]' \
        '-b[Browser only]' \
        '--hostname[Hostname]:host: '
      ;;
    logout)
      _arguments \
        '--clean-cache[Clean cache]'
      ;;
    token)
      _arguments \
        'create:Create' \
        'list:List' \
        'revoke:Revoke' \
        'show:Show' \
        'update:Update'
      ;;
    docker)
      _arguments \
        'login:Login' \
        'logout:Logout'
      ;;
  esac
}

# Config completion
_flyctl_config_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'env:Environment'
      'save:Save'
      'show:Show'
      'validate:Validate'
    )
    _describe -t commands "config commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    env)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--env[Env]:envs: ' \
        '-e[Env]:envs: ' \
        '--local[Local]' \
        '-l[Local]' \
        '--docker[Docker]' \
        '-d[Docker]' \
        '--override[Override]' \
        '-o[Override]'
      ;;
    save)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--config[Config]:file:_files' \
        '-c[Config]:file:_files' \
        '--yes[Skip confirm]' \
        '-y[Skip confirm]'
      ;;
    show)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--config[Config]:file:_files' \
        '-c[Config]:file:_files'
      ;;
    validate)
      _arguments \
        '--app[App]:app:_flyctl_apps' \
        '-a[App]:app:_flyctl_apps' \
        '--config[Config]:file:_files' \
        '-c[Config]:file:_files' \
        '--site[Site]:site:(dev ha)'
      ;;
  esac
}

# Image completion
_flyctl_image_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'label:Label'
      'show:Show'
      'update:Update'
    )
    _describe -t commands "image commands" commands
    return
  fi
  
  _arguments \
    '--app[App]:app:_flyctl_apps' \
    '-a[App]:app:_flyctl_apps' \
    '--config[Config]:file:_files' \
    '-c[Config]:file:_files' \
    '--image[Image]:ref: ' \
    '-i[Image]:ref: ' \
    '--label[Label]:label: ' \
    '-l[Label]:label: ' \
    '--digest[Digest]:digest: ' \
    '--local[Local only]' \
    '--remote[Remote only]' \
    '--json[JSON]'
}

# Tokens completion
_flyctl_tokens_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create'
      'list:List'
      'revoke:Revoke'
      'show:Show'
      'update:Update'
    )
    _describe -t commands "tokens commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--org[Org]:org:_flyctl_orgs' \
        '-o[Org]:org:_flyctl_orgs' \
        '--expiry[Expiry]:duration: ' \
        '--json[JSON]'
      ;;
    revoke)
      _arguments \
        '--id[ID]:id: ' \
        '*:token: '
      ;;
    list|show|update)
      _arguments \
        '--json[JSON]' \
        '*:token: '
      ;;
  esac
}

# Register completion
compdef _flyctl flyctl
compdef _flyctl fly

# ============================================================
# ALIASES
# ============================================================

alias fly='flyctl'
alias flyapps='flyctl apps list'
alias flyapp='flyctl apps show'
alias flydeploy='flyctl deploy'
alias flylogs='flyctl logs'
alias flystatus='flyctl status'
alias flyssh='flyctl ssh console'
alias flymachine='flyctl machines list'
alias flyvol='flyctl volumes list'
alias flypg='flyctl postgres list'
alias flyredis='flyctl redis list'
alias flyregions='flyctl platform regions'
alias flyorgs='flyctl orgs list'
alias flyips='flyctl ips list'

# Helper functions
flyconsole() {
  local app="${1:-$(flyctl info --json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)['Name'])" 2>/dev/null)}"
  [[ -n "$app" ]] && flyctl ssh console --app "$app"
}

flydb() {
  local pg="${1:-$(flyctl postgres list --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['Name'] if d else '')" 2>/dev/null)}"
  [[ -n "$pg" ]] && flyctl postgres connect --app "$pg"
}
