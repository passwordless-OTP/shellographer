# DigitalOcean CLI (doctl) - Enhanced completions
# Author: https://github.com/HalisCz
# Enhanced with dynamic resource completions

if (( ! $+commands[doctl] )); then
  return
fi

# ============================================================
# CACHE AND STATE MANAGEMENT
# ============================================================

_doctl_cache_dir="${ZSH_CACHE_DIR}/doctl"
mkdir -p "$_doctl_cache_dir"

# Get droplets (cached)
_doctl_droplets() {
  local cache_file="$_doctl_cache_dir/droplets"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    doctl compute droplet list --format ID,Name,PublicIPv4,Status --no-header 2>/dev/null | \
      awk '{print $1":"$2" ["$4"] @ "$3}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get Kubernetes clusters (cached)
_doctl_k8s_clusters() {
  local cache_file="$_doctl_cache_dir/k8s_clusters"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    doctl kubernetes cluster list --format ID,Name,Region,Status --no-header 2>/dev/null | \
      awk '{print $1":"$2" ["$4"]"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get databases (cached)
_doctl_databases() {
  local cache_file="$_doctl_cache_dir/databases"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    doctl databases list --format ID,Name,Engine,Status --no-header 2>/dev/null | \
      awk '{print $1":"$2" ("$3") ["$4"]"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get domains (cached)
_doctl_domains() {
  local cache_file="$_doctl_cache_dir/domains"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    doctl compute domain list --format Domain --no-header 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get floating IPs (cached)
_doctl_floating_ips() {
  local cache_file="$_doctl_cache_dir/floating_ips"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    doctl compute floating-ip list --format IP,DropletName,Region --no-header 2>/dev/null | \
      awk '{print $1":"$2" ("$3")"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get volumes (cached)
_doctl_volumes() {
  local cache_file="$_doctl_cache_dir/volumes"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    doctl compute volume list --format ID,Name,Size,Region --no-header 2>/dev/null | \
      awk '{print $1":"$2" ("$3"GB "$4")"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get snapshots (cached)
_doctl_snapshots() {
  local cache_file="$_doctl_cache_dir/snapshots"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    doctl compute snapshot list --format ID,Name,ResourceType,MinDiskSize --no-header 2>/dev/null | \
      awk '{print $1":"$2" ("$3", "$4"GB)"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get VPCs (cached)
_doctl_vpcs() {
  local cache_file="$_doctl_cache_dir/vpcs"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    doctl vpcs list --format ID,Name,Region --no-header 2>/dev/null | \
      awk '{print $1":"$2" ("$3")"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get container registries (cached)
_doctl_registries() {
  local cache_file="$_doctl_cache_dir/registries"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    doctl registry list --format Name --no-header 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get regions
_doctl_regions() {
  local regions=(
    'nyc1:New York 1'
    'nyc3:New York 3'
    'ams3:Amsterdam 3'
    'sfo3:San Francisco 3'
    'sgp1:Singapore 1'
    'lon1:London 1'
    'fra1:Frankfurt 1'
    'tor1:Toronto 1'
    'blr1:Bangalore 1'
    'syd1:Sydney 1'
  )
  print -l "${regions[@]}"
}

# Get droplet sizes
_doctl_sizes() {
  local sizes=(
    's-1vcpu-512mb-10gb:Basic (512MB, 1 CPU)'
    's-1vcpu-1gb:Basic (1GB, 1 CPU)'
    's-1vcpu-2gb:Basic (2GB, 1 CPU)'
    's-2vcpu-2gb:Basic (2GB, 2 CPU)'
    's-2vcpu-4gb:Basic (4GB, 2 CPU)'
    's-4vcpu-8gb:Basic (8GB, 4 CPU)'
    'c-2:CPU-Optimized (4GB, 2 CPU)'
    'c-4:CPU-Optimized (8GB, 4 CPU)'
    'c-8:CPU-Optimized (16GB, 8 CPU)'
    'g-2vcpu-8gb:GPU (8GB, 2 CPU, 1 GPU)'
    'gd-2vcpu-8gb:GPU+SSD (8GB, 2 CPU, 1 GPU)'
    'm-2vcpu-16gb:Memory-Optimized (16GB, 2 CPU)'
    'm-4vcpu-32gb:Memory-Optimized (32GB, 4 CPU)'
  )
  print -l "${sizes[@]}"
}

# Get images
_doctl_images() {
  local images=(
    'ubuntu-22-04-x64:Ubuntu 22.04 (LTS)'
    'ubuntu-20-04-x64:Ubuntu 20.04 (LTS)'
    'debian-12-x64:Debian 12'
    'debian-11-x64:Debian 11'
    'fedora-39-x64:Fedora 39'
    'centos-stream-9-x64:CentOS Stream 9'
    'rockylinux-9-x64:Rocky Linux 9'
    'almalinux-9-x64:AlmaLinux 9'
    'docker-20-04:Docker on Ubuntu 20.04'
    'lamp-20-04:LAMP on Ubuntu 20.04'
    'nodejs-20-04:NodeJS on Ubuntu 20.04'
    'wordpress-20-04:WordPress on Ubuntu 20.04'
  )
  print -l "${images[@]}"
}

# ============================================================
# MAIN COMPLETION FUNCTION
# ============================================================

_doctl_enhanced() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # Global options
  if [[ "$cur" == -* ]] && (( CURRENT == 2 )); then
    _doctl_global_options
    return
  fi
  
  # First level - commands
  if (( CURRENT == 2 )); then
    if [[ "$cur" != -* ]]; then
      _doctl_commands
    else
      _doctl_global_options
    fi
    return
  fi
  
  local cmd=$words[2]
  
  # Complete based on command
  case "$cmd" in
    compute)
      _doctl_compute_completion
      ;;
    kubernetes|k8s|k)
      _doctl_kubernetes_completion
      ;;
    databases|db)
      _doctl_databases_completion
      ;;
    registry|reg)
      _doctl_registry_completion
      ;;
    apps)
      _doctl_apps_completion
      ;;
    vpcs)
      _doctl_vpcs_completion
      ;;
    auth)
      _doctl_auth_completion
      ;;
    account)
      _doctl_account_completion
      ;;
    balance)
      _doctl_balance_completion
      ;;
    billing-history)
      _doctl_billing_completion
      ;;
    invoice)
      _doctl_invoice_completion
      ;;
    projects)
      _doctl_projects_completion
      ;;
    serverless|sls)
      _doctl_serverless_completion
      ;;
    version)
      # No subcommands
      ;;
    *)
      _files
      ;;
  esac
}

_doctl_global_options() {
  local -a options
  options=(
    '(-t --access-token)'{-t,--access-token}'[API V2 token]:token: '
    '(-u --api-url)'{-u,--api-url}'[API endpoint]:url: '
    '(-c --config)'{-c,--config}'[Config file]:file:_files'
    '--context[Auth context]:context: '
    '--interactive[Interactive mode]'
    '--trace[Network trace]'
    '(-o --output)'{-o,--output}'[Output format]:format:(text json)'
    '(-v --verbose)'{-v,--verbose}'[Verbose output]'
    '--http-retry-max[Max retries]:count:'
    '(-h --help)'{-h,--help}'[Show help]'
  )
  _describe -t options "doctl options" options
}

_doctl_commands() {
  local -a commands
  commands=(
    '1-click:1-click applications'
    'account:Account details'
    'apps:Apps Platform'
    'balance:Account balance'
    'billing-history:Billing history'
    'compute:Compute (droplets, images, etc.)'
    'databases:Databases'
    'invoice:Invoices'
    'kubernetes:Kubernetes (k8s, k)'
    'monitoring:Monitoring (beta)'
    'projects:Projects'
    'registry:Container registry'
    'serverless:Serverless functions'
    'vpcs:VPCs'
    'auth:Authentication'
    'version:Show version'
  )
  _describe -t commands "doctl commands" commands
}

# Compute completions
_doctl_compute_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'action:Action commands'
      'cdn:CDN commands'
      'certificate:Certificate commands'
      'domain:Domain commands'
      'droplet:Droplet commands'
      'firewall:Firewall commands'
      'floating-ip:Floating IP commands'
      'image:Image commands'
      'load-balancer:Load balancer commands'
      'region:Region commands'
      'size:Size commands'
      'snapshot:Snapshot commands'
      'ssh:SSH to droplet'
      'ssh-key:SSH key commands'
      'tag:Tag commands'
      'volume:Volume commands'
      'vpc:VPC commands'
    )
    _describe -t commands "compute commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    droplet)
      _doctl_compute_droplet_completion
      ;;
    ssh)
      _arguments \
        '--ssh-user[SSH user]:user: ' \
        '--ssh-port[SSH port]:port: ' \
        '--ssh-key-path[SSH key]:key:_files' \
        '--ssh-agent-forwarding[Agent forwarding]' \
        '*:droplet:_doctl_droplets'
      ;;
    floating-ip|fip)
      _doctl_compute_floating_ip_completion
      ;;
    volume)
      _doctl_compute_volume_completion
      ;;
    domain)
      _doctl_compute_domain_completion
      ;;
    image)
      _doctl_compute_image_completion
      ;;
    snapshot)
      _doctl_compute_snapshot_completion
      ;;
    ssh-key)
      _doctl_compute_ssh_key_completion
      ;;
    firewall)
      _doctl_compute_firewall_completion
      ;;
    load-balancer|lb)
      _doctl_compute_lb_completion
      ;;
    cdn)
      _doctl_compute_cdn_completion
      ;;
    action)
      _arguments \
        '*:action: '
      ;;
    certificate)
      _arguments \
        '*:certificate: '
      ;;
    region)
      _doctl_regions
      ;;
    size)
      _doctl_sizes
      ;;
    tag)
      _arguments \
        '*:tag: '
      ;;
    vpc)
      _doctl_vpcs
      ;;
  esac
}

_doctl_compute_droplet_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'actions:List actions'
      'backups:List backups'
      'create:Create droplet'
      'delete:Delete droplet'
      'get:Get droplet'
      'kernels:List kernels'
      'list:List droplets'
      'neighbors:List neighbors'
      'snapshots:List snapshots'
      'tag:Tag droplet'
      'untag:Untag droplet'
    )
    _describe -t commands "droplet commands" commands
    return
  fi
  
  local action=$words[4]
  
  case "$action" in
    create)
      _arguments \
        '--image[Image]:image:_doctl_images' \
        '--region[Region]:region:_doctl_regions' \
        '--size[Size]:size:_doctl_sizes' \
        '--ssh-keys[SSH keys]:keys: ' \
        '--backups[Enable backups]' \
        '--ipv6[Enable IPv6]' \
        '--monitoring[Enable monitoring]' \
        '--private-networking[Private networking]' \
        '--vpc-uuid[VPC]:vpc:_doctl_vpcs' \
        '--user-data[User data]:data: ' \
        '--user-data-file[User data file]:file:_files' \
        '--tag[Tags]:tags: ' \
        '--wait[Wait for create]' \
        '--tag-name[Tag name]:name: ' \
        '--tag-ignore[Ignore tag errors]' \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:name: '
      ;;
    delete|get|actions|backups|kernels|neighbors|snapshots|tag|untag)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:droplet:_doctl_droplets'
      ;;
    list)
      _arguments \
        '--tag-name[Filter by tag]:tag: ' \
        '--tag-ignore[Ignore tag errors]' \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
  esac
}

_doctl_droplets() {
  local droplets=(${(f)"$(_doctl_droplets)"})
  _describe -t droplets "droplets" droplets
}

_doctl_compute_floating_ip_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'create:Create floating IP'
      'delete:Delete floating IP'
      'get:Get floating IP'
      'list:List floating IPs'
    )
    _describe -t commands "floating-ip commands" commands
    return
  fi
  
  local action=$words[4]
  
  case "$action" in
    create)
      _arguments \
        '--region[Region]:region:_doctl_regions' \
        '--droplet-id[Droplet]:droplet:_doctl_droplets' \
        '--project-id[Project]:project: ' \
        '--project-name[Project]:project: ' \
        '--wait[Wait]' \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
    delete|get)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:ip:_doctl_floating_ips'
      ;;
    list)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
  esac
}

_doctl_floating_ips() {
  local ips=(${(f)"$(_doctl_floating_ips)"})
  _describe -t ips "floating IPs" ips
}

_doctl_compute_volume_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'create:Create volume'
      'delete:Delete volume'
      'get:Get volume'
      'list:List volumes'
      'snapshot:Snapshot volume'
    )
    _describe -t commands "volume commands" commands
    return
  fi
  
  local action=$words[4]
  
  case "$action" in
    create)
      _arguments \
        '--region[Region]:region:_doctl_regions' \
        '--size[Size GiB]:size: ' \
        '--description[Description]:desc: ' \
        '--fs-type[Filesystem]:fs:(ext4 xfs)' \
        '--tag[Tags]:tags: ' \
        '--wait[Wait]' \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:name: '
      ;;
    delete|get|snapshot)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:volume:_doctl_volumes'
      ;;
    list)
      _arguments \
        '--region[Filter region]:region:_doctl_regions' \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
  esac
}

_doctl_volumes() {
  local volumes=(${(f)"$(_doctl_volumes)"})
  _describe -t volumes "volumes" volumes
}

_doctl_compute_domain_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'create:Create domain'
      'delete:Delete domain'
      'get:Get domain'
      'list:List domains'
      'records:Domain records'
    )
    _describe -t commands "domain commands" commands
    return
  fi
  
  local action=$words[4]
  
  case "$action" in
    create)
      _arguments \
        '--ip-address[IP]:ip: ' \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:domain: '
      ;;
    delete|get|records)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:domain:_doctl_domains'
      ;;
    list)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
  esac
}

_doctl_domains() {
  local domains=(${(f)"$(_doctl_domains)"})
  _describe -t domains "domains" domains
}

_doctl_compute_image_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'create:Create image'
      'delete:Delete image'
      'get:Get image'
      'list:List images'
      'update:Update image'
    )
    _describe -t commands "image commands" commands
    return
  fi
  
  local action=$words[4]
  
  case "$action" in
    create)
      _arguments \
        '--droplet-id[Droplet]:droplet:_doctl_droplets' \
        '--region[Region]:region:_doctl_regions' \
        '--description[Description]:desc: ' \
        '--tag[Tags]:tags: ' \
        '--wait[Wait]' \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:name: '
      ;;
    list)
      _arguments \
        '--public[Public only]' \
        '--private[Private only]' \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
    *)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:image: '
      ;;
  esac
}

_doctl_compute_snapshot_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'delete:Delete snapshot'
      'get:Get snapshot'
      'list:List snapshots'
    )
    _describe -t commands "snapshot commands" commands
    return
  fi
  
  _arguments \
    '--resource[Resource type]:type:(droplet volume)' \
    '--format[Format]:format: ' \
    '--no-header[No header]' \
    '*:snapshot:_doctl_snapshots'
}

_doctl_snapshots() {
  local snapshots=(${(f)"$(_doctl_snapshots)"})
  _describe -t snapshots "snapshots" snapshots
}

_doctl_compute_ssh_key_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'create:Create key'
      'delete:Delete key'
      'get:Get key'
      'import:Import key'
      'list:List keys'
      'update:Update key'
    )
    _describe -t commands "ssh-key commands" commands
    return
  fi
  
  local action=$words[4]
  
  case "$action" in
    import)
      _arguments \
        '--public-key-file[Key file]:file:_files' \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:name: '
      ;;
    create)
      _arguments \
        '--public-key[Public key]:key: ' \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:name: '
      ;;
    *)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:key: '
      ;;
  esac
}

_doctl_compute_firewall_completion() {
  _arguments \
    '*:firewall: '
}

_doctl_compute_lb_completion() {
  _arguments \
    '*:load-balancer: '
}

_doctl_compute_cdn_completion() {
  _arguments \
    '*:cdn: '
}

# Kubernetes completions
_doctl_kubernetes_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      '1-click:1-click apps'
      'cluster:Cluster commands'
      'kubeconfig:Kubeconfig commands'
      'node-pool:Node pool commands'
      'options:List options'
      'registry:Registry integration'
    )
    _describe -t commands "kubernetes commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    cluster)
      _doctl_k8s_cluster_completion
      ;;
    kubeconfig)
      _arguments \
        'save:Save config' \
        'show:Show config' \
        'remove:Remove config' \
        '*:cluster:_doctl_k8s_clusters'
      ;;
    node-pool)
      _arguments \
        '*:cluster:_doctl_k8s_clusters'
      ;;
    options)
      _arguments \
        '--version[List versions]' \
        '--machine-sizes[List sizes]' \
        '--region[List regions]'
      ;;
  esac
}

_doctl_k8s_cluster_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'create:Create cluster'
      'delete:Delete cluster'
      'get:Get cluster'
      'list:List clusters'
      'node-pool:Node pool'
      'update:Update cluster'
      'upgrade:Upgrade cluster'
    )
    _describe -t commands "cluster commands" commands
    return
  fi
  
  local action=$words[4]
  
  case "$action" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--region[Region]:region:_doctl_regions' \
        '--version[Version]:version: ' \
        '--node-pool[Node pool]:pool: ' \
        '--tag[Tags]:tags: ' \
        '--auto-upgrade[Auto upgrade]' \
        '--maintenance-policy[Policy]:policy: ' \
        '--surge-upgrade[Surge upgrade]' \
        '--ha[High availability]' \
        '--set-current-context[Set context]' \
        '--wait[Wait]' \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
    delete|get|update|upgrade)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:cluster:_doctl_k8s_clusters'
      ;;
    list)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
    node-pool)
      _arguments \
        '*:cluster:_doctl_k8s_clusters'
      ;;
  esac
}

_doctl_k8s_clusters() {
  local clusters=(${(f)"$(_doctl_k8s_clusters)"})
  _describe -t clusters "clusters" clusters
}

# Databases completions
_doctl_databases_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'backups:Backups'
      'ca:Get CA'
      'cluster:Cluster'
      'connection:Connection'
      'create:Create'
      'db:DB'
      'delete:Delete'
      'firewall:Firewall'
      'get:Get'
      'list:List'
      'maintenance:Maintenance'
      'migration:Migration'
      'options:Options'
      'pool:Pool'
      'replica:Replica'
      'resize:Resize'
      'sql-mode:SQL mode'
      'user:User'
    )
    _describe -t commands "databases commands" commands
    return
  fi
  
  _arguments \
    '*:database:_doctl_databases'
}

_doctl_databases() {
  local dbs=(${(f)"$(_doctl_databases)"})
  _describe -t dbs "databases" dbs
}

# Registry completions
_doctl_registry_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create'
      'delete:Delete'
      'docker-config:Docker config'
      'garbage-collection:GC'
      'get:Get'
      'login:Login'
      'logout:Logout'
      'options:Options'
      'repository:Repository'
    )
    _describe -t commands "registry commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--subscription-tier[Tier]:tier:(starter basic professional)'
      ;;
    repository)
      _arguments \
        'list:List' \
        'list-manifests:List manifests' \
        'delete-manifest:Delete manifest' \
        'delete-tag:Delete tag' \
        '*:registry:_doctl_registries'
      ;;
    *)
      _arguments \
        '*:registry:_doctl_registries'
      ;;
  esac
}

_doctl_registries() {
  local registries=(${(f)"$(_doctl_registries)"})
  _describe -t registries "registries" registries
}

# Apps completions
_doctl_apps_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create'
      'delete:Delete'
      'get:Get'
      'list:List'
      'logs:Logs'
      'propose:Propose'
      'spec:Spec'
      'tier:Tier'
      'update:Update'
    )
    _describe -t commands "apps commands" commands
    return
  fi
  
  _arguments \
    '*:app: '
}

# VPCs completions
_doctl_vpcs_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create'
      'delete:Delete'
      'get:Get'
      'list:List'
      'peer:Peer'
      'update:Update'
    )
    _describe -t commands "vpc commands" commands
    return
  fi
  
  local action=$words[3]
  
  case "$action" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--region[Region]:region:_doctl_regions' \
        '--ip-range[IP range]:range: ' \
        '--description[Description]:desc: ' \
        '--default[Default]' \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
    delete|get|update)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]' \
        '*:vpc:_doctl_vpcs_list'
      ;;
    list)
      _arguments \
        '--format[Format]:format: ' \
        '--no-header[No header]'
      ;;
  esac
}

_doctl_vpcs_list() {
  local vpcs=(${(f)"$(_doctl_vpcs)"})
  _describe -t vpcs "VPCs" vpcs
}

# Auth completions
_doctl_auth_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'init:Initialize'
      'list:List contexts'
      'remove:Remove context'
      'switch:Switch context'
    )
    _describe -t commands "auth commands" commands
    return
  fi
  
  _arguments \
    '--context[Context]:context: ' \
    '--token[Token]:token: '
}

# Account completions
_doctl_account_completion() {
  _arguments \
    'get:Get account' \
    'ratelimit:Get rate limit'
}

# Billing completions
_doctl_balance_completion() {
  _arguments \
    '--format[Format]:format: ' \
    '--no-header[No header]'
}

_doctl_billing_completion() {
  _arguments \
    '--format[Format]:format: ' \
    '--no-header[No header]'
}

_doctl_invoice_completion() {
  _arguments \
    'get:Get invoice' \
    'list:List invoices' \
    'csv:Get CSV' \
    'pdf:Get PDF' \
    '--format[Format]:format: ' \
    '--no-header[No header]'
}

# Projects completions
_doctl_projects_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create'
      'delete:Delete'
      'get:Get'
      'list:List'
      'resources:Resources'
      'update:Update'
    )
    _describe -t commands "projects commands" commands
    return
  fi
  
  _arguments \
    '*:project: '
}

# Serverless completions
_doctl_serverless_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'connect:Connect'
      'deploy:Deploy'
      'functions:Functions'
      'get-metadata:Get metadata'
      'init:Initialize'
      'logs:Logs'
      'namespaces:Namespaces'
      'status:Status'
    )
    _describe -t commands "serverless commands" commands
    return
  fi
  
  _arguments \
    '*:function: '
}

# Register enhanced completion
compdef _doctl_enhanced doctl

# Legacy: Keep generating native completions as fallback
if [[ ! -f "$ZSH_CACHE_DIR/completions/_doctl" ]]; then
  typeset -g -A _comps
  autoload -Uz _doctl
  _comps[doctl]=_doctl
fi

doctl completion zsh >| "$ZSH_CACHE_DIR/completions/_doctl" &|

# ============================================================
# ALIASES
# ============================================================

# caps:category=auth
# caps:desc=Initialize doctl auth
alias doauth='doctl auth init'

# caps:category=compute
# caps:desc=List droplets
alias droplets='doctl compute droplet list'

# caps:category=compute
# caps:desc=SSH to droplet
alias dossh='doctl compute ssh'

# caps:category=k8s
# caps:desc=List Kubernetes clusters
alias dok8s='doctl kubernetes cluster list'

# caps:category=database
# caps:desc=List databases
alias dodb='doctl databases list'
alias dosnap='doctl compute snapshot list'
alias doips='doctl compute floating-ip list'
alias dovolumes='doctl compute volume list'
alias dok8s='doctl kubernetes cluster list'
alias dodb='doctl databases list'
alias doreg='doctl registry list'
alias doapps='doctl apps list'
dodroplet() {
  doctl compute droplet get "$1"
}
dokubeconfig() {
  doctl kubernetes cluster kubeconfig save "$1"
}
