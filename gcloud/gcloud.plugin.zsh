# Google Cloud SDK - Enhanced completions
# Author: Ian Chesal (github.com/ianchesal)
# Enhanced with service and resource completions

if [[ -z "${CLOUDSDK_HOME}" ]]; then
  search_locations=(
    "$HOME/google-cloud-sdk"
    "/usr/local/share/google-cloud-sdk"
    "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
    "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
    "/opt/homebrew/share/google-cloud-sdk"
    "/usr/share/google-cloud-sdk"
    "/snap/google-cloud-sdk/current"
    "/snap/google-cloud-cli/current"
    "/usr/lib/google-cloud-sdk"
    "/usr/lib64/google-cloud-sdk"
    "/opt/google-cloud-sdk"
    "/opt/google-cloud-cli"
    "/opt/local/libexec/google-cloud-sdk"
    "$HOME/.asdf/installs/gcloud/*/"
  )

  for gcloud_sdk_location in $search_locations; do
    if [[ -d "${gcloud_sdk_location}" ]]; then
      CLOUDSDK_HOME="${gcloud_sdk_location}"
      break
    fi
  done
  unset search_locations gcloud_sdk_location
fi

if (( ! $+commands[gcloud] )); then
  return
fi

# ============================================================
# CACHE AND STATE MANAGEMENT
# ============================================================

_gcloud_cache_dir="${ZSH_CACHE_DIR}/gcloud"
mkdir -p "$_gcloud_cache_dir"

# Get projects (cached)
_gcloud_projects() {
  local cache_file="$_gcloud_cache_dir/projects"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gcloud projects list --format='value(projectId,name)' 2>/dev/null | \
      awk -F'\t' '{print $1":"$2}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get compute instances (cached)
_gcloud_instances() {
  local cache_file="$_gcloud_cache_dir/instances"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    gcloud compute instances list --format='value(name,zone,status)' 2>/dev/null | \
      awk '{print $1":"$2" ["$3"]"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get compute zones (cached)
_gcloud_zones() {
  local cache_file="$_gcloud_cache_dir/zones"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 3600 ]]; then
    gcloud compute zones list --format='value(name,region,status)' 2>/dev/null | \
      awk '{print $1":"$2" ["$3"]"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get compute regions (cached)
_gcloud_regions() {
  local cache_file="$_gcloud_cache_dir/regions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 3600 ]]; then
    gcloud compute regions list --format='value(name,status)' 2>/dev/null | \
      awk '{print $1":"$2}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get GKE clusters (cached)
_gcloud_clusters() {
  local cache_file="$_gcloud_cache_dir/clusters"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    gcloud container clusters list --format='value(name,zone,status)' 2>/dev/null | \
      awk '{print $1":"$2" ["$3"]"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get Cloud Run services (cached)
_gcloud_run_services() {
  local cache_file="$_gcloud_cache_dir/run_services"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    gcloud run services list --format='value(metadata.name,status.conditions[0].status)' 2>/dev/null | \
      awk '{print $1":"$2}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get Cloud Functions (cached)
_gcloud_functions() {
  local cache_file="$_gcloud_cache_dir/functions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    gcloud functions list --format='value(name,status)' 2>/dev/null | \
      awk '{print $1":"$2}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get App Engine services (cached)
_gcloud_app_services() {
  local cache_file="$_gcloud_cache_dir/app_services"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gcloud app services list --format='value(id)' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get configurations
_gcloud_configurations() {
  gcloud config configurations list --format='value(name,is_active)' 2>/dev/null | \
    awk '{print $1":"($2=="True"?"(active)":"")}'
}

# Get machine types
_gcloud_machine_types() {
  local types=(
    'e2-micro:E2 Micro (2 vCPU, 1 GB)'
    'e2-small:E2 Small (2 vCPU, 2 GB)'
    'e2-medium:E2 Medium (2 vCPU, 4 GB)'
    'e2-standard-2:E2 Standard (2 vCPU, 8 GB)'
    'e2-standard-4:E2 Standard (4 vCPU, 16 GB)'
    'e2-standard-8:E2 Standard (8 vCPU, 32 GB)'
    'n1-standard-1:N1 Standard (1 vCPU, 3.75 GB)'
    'n1-standard-2:N1 Standard (2 vCPU, 7.5 GB)'
    'n1-standard-4:N1 Standard (4 vCPU, 15 GB)'
    'n2-standard-2:N2 Standard (2 vCPU, 8 GB)'
    'n2-standard-4:N2 Standard (4 vCPU, 16 GB)'
    'n2d-standard-2:N2D Standard (2 vCPU, 8 GB)'
    'c2-standard-4:C2 Compute (4 vCPU, 16 GB)'
    'c2d-standard-2:C2D Compute (2 vCPU, 8 GB)'
    'm1-ultramem-40:M1 Ultra (40 vCPU, 961 GB)'
    'a2-highgpu-1g:A2 High GPU (12 vCPU, 85 GB, 1 GPU)'
  )
  print -l "${types[@]}"
}

# Get disk types
_gcloud_disk_types() {
  local types=(
    'pd-balanced:Persistent Disk Balanced'
    'pd-ssd:Persistent Disk SSD'
    'pd-standard:Persistent Disk Standard'
    'pd-extreme:Persistent Disk Extreme'
    'hyperdisk-balanced:Hyperdisk Balanced'
    'hyperdisk-extreme:Hyperdisk Extreme'
    'hyperdisk-ml:Hyperdisk ML'
    'local-ssd:Local SSD'
  )
  print -l "${types[@]}"
}

# Get image families
_gcloud_image_families() {
  local families=(
    'debian-12:Debian 12 (Bookworm)'
    'debian-11:Debian 11 (Bullseye)'
    'ubuntu-2204-lts:Ubuntu 22.04 LTS'
    'ubuntu-2004-lts:Ubuntu 20.04 LTS'
    'ubuntu-2404-lts:Ubuntu 24.04 LTS'
    'centos-7:CentOS 7'
    'centos-stream-9:CentOS Stream 9'
    'rocky-linux-8:Rocky Linux 8'
    'rocky-linux-9:Rocky Linux 9'
    'rhel-9:RHEL 9'
    'rhel-8:RHEL 8'
    'sles-15:SUSE Linux Enterprise 15'
    'windows-2022:Windows Server 2022'
    'windows-2019:Windows Server 2019'
    'cos-113:Container-Optimized OS'
    'fedora-coreos-stable:Fedora CoreOS'
  )
  print -l "${families[@]}"
}

# ============================================================
# MAIN COMPLETION FUNCTION
# ============================================================

_gcloud_enhanced() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # Global options
  if [[ "$cur" == -* ]] && (( CURRENT == 2 )); then
    _gcloud_global_options
    return
  fi
  
  # First level - groups and commands
  if (( CURRENT == 2 )); then
    if [[ "$cur" != -* ]]; then
      _gcloud_groups
    else
      _gcloud_global_options
    fi
    return
  fi
  
  local group=$words[2]
  
  # Complete based on group
  case "$group" in
    compute)
      _gcloud_compute_completion
      ;;
    container)
      _gcloud_container_completion
      ;;
    run)
      _gcloud_run_completion
      ;;
    functions)
      _gcloud_functions_completion
      ;;
    app)
      _gcloud_app_completion
      ;;
    storage)
      _gcloud_storage_completion
      ;;
    sql)
      _gcloud_sql_completion
      ;;
    pubsub)
      _gcloud_pubsub_completion
      ;;
    iam)
      _gcloud_iam_completion
      ;;
    kms)
      _gcloud_kms_completion
      ;;
    secrets)
      _gcloud_secrets_completion
      ;;
    builds)
      _gcloud_builds_completion
      ;;
    artifacts)
      _gcloud_artifacts_completion
      ;;
    scheduler)
      _gcloud_scheduler_completion
      ;;
    tasks)
      _gcloud_tasks_completion
      ;;
    logging)
      _gcloud_logging_completion
      ;;
    monitoring)
      _gcloud_monitoring_completion
      ;;
    config)
      _gcloud_config_completion
      ;;
    projects)
      _gcloud_projects_completion
      ;;
    services)
      _gcloud_services_completion
      ;;
    auth)
      _gcloud_auth_completion
      ;;
    source)
      _gcloud_source_completion
      ;;
    *)
      # Fall back to default completion
      _gcloud
      ;;
  esac
}

_gcloud_global_options() {
  local -a options
  options=(
    '--account[Account]:account: '
    '--billing-project[Billing project]:project:_gcloud_projects'
    '--configuration[Configuration]:config:_gcloud_configurations'
    '--flags-file[Flags file]:file:_files'
    '--flatten[Flatten keys]:keys: '
    '--format[Output format]:format:(config csv default diff disabled flattened get json list multi none object table text value yaml)'
    '--help[Show help]'
    '--project[Project ID]:project:_gcloud_projects'
    '--quiet[Quiet mode]'
    '--verbosity[Verbosity]:level:(debug info warning error critical none)'
    '--version[Show version]'
    '--access-token-file[Token file]:file:_files'
    '--impersonate-service-account[Impersonate]:email: '
    '--log-http[Log HTTP]'
    '--trace-token[Trace token]:token: '
    '--no-user-output-enabled[Disable output]'
  )
  _describe -t options "gcloud options" options
}

_gcloud_groups() {
  local -a groups
  groups=(
    'access-context-manager:Access context manager'
    'active-directory:Active Directory'
    'ai:AI Platform'
    'anthos:Anthos'
    'apigee:Apigee'
    'app:App Engine'
    'artifacts:Artifact Registry'
    'asset:Cloud Asset Inventory'
    'assured:Assured Workloads'
    'auth:Authentication'
    'batch:Batch'
    'bd:Cloud Bigtable'
    'bigtable:Cloud Bigtable'
    'billing:Cloud Billing'
    'bq:BigQuery'
    'builds:Cloud Build'
    'certificate-manager:Certificate Manager'
    'cloud-shell:Cloud Shell'
    'commerce-procurement:Commerce Procurement'
    'components:Cloud SDK components'
    'composer:Cloud Composer'
    'compute:Compute Engine'
    'config:Configuration'
    'container:Kubernetes Engine'
    'container-analysis:Container Analysis'
    'data-catalog:Data Catalog'
    'dataflow:Dataflow'
    'dataplex:Dataplex'
    'dataproc:Cloud Dataproc'
    'datastore:Cloud Datastore'
    'deploy:Cloud Deploy'
    'deployment-manager:Deployment Manager'
    'dns:Cloud DNS'
    'docker:Docker'
    'domains:Cloud Domains'
    'emulators:Emulators'
    'endpoints:Cloud Endpoints'
    'filestore:Filestore'
    'firebase:Firebase'
    'firestore:Firestore'
    'functions:Cloud Functions'
    'game:Game Servers'
    ' healthcare:Cloud Healthcare'
    'iam:Identity and Access Management'
    'iapat:IAP'
    'identity:Cloud Identity'
    'iot:Cloud IoT'
    'kms:Cloud KMS'
    'logging:Cloud Logging'
    'looker:Looker'
    'memcache:Memorystore'
    'meta:Meta'
    'migration:Migrate'
    'ml:AI Platform'
    'ml-engine:AI Platform'
    'monitoring:Cloud Monitoring'
    'netapp:NetApp'
    'network-connectivity:Network Connectivity'
    'network-management:Network Management'
    'network-security:Network Security'
    'network-services:Network Services'
    'notebooks:Notebooks'
    'organizations:Organizations'
    'policy-intelligence:Policy Intelligence'
    'policy-troubleshoot:Policy Troubleshooter'
    'privateca:Certificate Authority'
    'projects:Cloud Resource Manager'
    'pubsub:Cloud Pub/Sub'
    'recaptcha:reCAPTCHA'
    'redis:Memorystore Redis'
    'resource-manager:Resource Manager'
    'resource-settings:Resource Settings'
    'run:Cloud Run'
    'scc:Security Command Center'
    'scheduler:Cloud Scheduler'
    'secrets:Secret Manager'
    'service-directory:Service Directory'
    'services:Service Management'
    'source:Cloud Source Repositories'
    'spanner:Cloud Spanner'
    'sql:Cloud SQL'
    'storage:Cloud Storage'
    'tasks:Cloud Tasks'
    'trace:Cloud Trace'
    'transcoder:Transcoder'
    'vmware:VMware Engine'
    'workflows:Workflows'
  )
  _describe -t groups "gcloud groups" groups
}

# Compute completions
_gcloud_compute_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'accelerator-types:Accelerator types'
      'addresses:Addresses'
      'backend-buckets:Backend buckets'
      'backend-services:Backend services'
      'commitments:Commitments'
      'disks:Disks'
      'disk-types:Disk types'
      'firewall-rules:Firewall rules'
      'forwarding-rules:Forwarding rules'
      'health-checks:Health checks'
      'http-health-checks:HTTP health checks'
      'https-health-checks:HTTPS health checks'
      'images:Images'
      'instance-groups:Instance groups'
      'instance-templates:Instance templates'
      'instances:Instances (VMs)'
      'interconnects:Interconnects'
      'machine-types:Machine types'
      'networks:Networks'
      'network-endpoint-groups:Network endpoint groups'
      'operations:Operations'
      'os-login:OS Login'
      'packet-mirrorings:Packet mirroring'
      'project-info:Project info'
      'regions:Regions'
      'reservations:Reservations'
      'resource-policies:Resource policies'
      'routers:Routers'
      'routes:Routes'
      'security-policies:Security policies'
      'shared-vpc:Shared VPC'
      'snapshots:Snapshots'
      'sole-tenancy:Sole tenancy'
      'ssl-certificates:SSL certificates'
      'ssl-policies:SSL policies'
      'subnetworks:Subnetworks'
      'target-grpc-proxies:Target gRPC proxies'
      'target-http-proxies:Target HTTP proxies'
      'target-https-proxies:Target HTTPS proxies'
      'target-instances:Target instances'
      'target-pools:Target pools'
      'target-ssl-proxies:Target SSL proxies'
      'target-tcp-proxies:Target TCP proxies'
      'target-vpn-gateways:Target VPN gateways'
      'tpus:TPUs'
      'url-maps:URL maps'
      'vpn-gateways:VPN gateways'
      'vpn-tunnels:VPN tunnels'
      'zones:Zones'
      'config-ssh:Config SSH'
      'connect-to-serial-port:Connect to serial'
      'copy-files:Copy files'
      'scp:SCP'
      'ssh:SSH'
      'ssh-keys:SSH keys'
    )
    _describe -t commands "compute commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    instances)
      _gcloud_compute_instances_completion
      ;;
    zones)
      _arguments \
        '*:zone:_gcloud_zones'
      ;;
    regions)
      _arguments \
        '*:region:_gcloud_regions'
      ;;
    machine-types)
      _arguments \
        '*:type:_gcloud_machine_types'
      ;;
    disks)
      _arguments \
        '--type[Disk type]:type:_gcloud_disk_types' \
        '*:disk: '
      ;;
    images)
      _arguments \
        '--image-family[Family]:family:_gcloud_image_families' \
        '*:image: '
      ;;
    ssh)
      _arguments \
        '--zone[Zone]:zone:_gcloud_zones' \
        '--command[Command]:command: ' \
        '--container[Container]:container: ' \
        '--ssh-key-file[Key file]:file:_files' \
        '--ssh-flag[Flags]:flags: ' \
        '--force-key-file-overwrite[Force overwrite]' \
        '--strict-host-key-checking[Host checking]:value:(yes no ask)' \
        '*:instance:_gcloud_instances'
      ;;
    scp|copy-files)
      _arguments \
        '--zone[Zone]:zone:_gcloud_zones' \
        '--scp-flag[SCP flags]:flags: ' \
        '--compress[Compress]' \
        '--recurse[Recursive]' \
        '*:instance:_gcloud_instances'
      ;;
    *)
      _arguments \
        '--zone[Zone]:zone:_gcloud_zones' \
        '--region[Region]:region:_gcloud_regions' \
        '*:resource: '
      ;;
  esac
}

_gcloud_compute_instances_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'add-access-config:Add access config'
      'add-iam-policy-binding:Add IAM binding'
      'add-labels:Add labels'
      'add-metadata:Add metadata'
      'add-tags:Add tags'
      'attach-disk:Attach disk'
      'create:Create instance'
      'delete:Delete instance'
      'delete-access-config:Delete access config'
      'describe:Describe instance'
      'detach-disk:Detach disk'
      'get-guest-attributes:Get guest attrs'
      'get-iam-policy:Get IAM policy'
      'get-screenshot:Get screenshot'
      'get-serial-port-output:Get serial output'
      'list:List instances'
      'move:Move instance'
      'network-interfaces:Network interfaces'
      'remove-iam-policy-binding:Remove IAM binding'
      'remove-labels:Remove labels'
      'remove-metadata:Remove metadata'
      'remove-tags:Remove tags'
      'reset:Reset instance'
      'resize:Resize instance'
      'resume:Resume instance'
      'set-disk-auto-delete:Set disk auto-delete'
      'set-iam-policy:Set IAM policy'
      'set-machine-type:Set machine type'
      'set-scheduling:Set scheduling'
      'set-scopes:Set scopes'
      'set-service-account:Set service account'
      'simulate-maintenance-event:Simulate maintenance'
      'start:Start instance'
      'start-iap-tunnel:Start IAP tunnel'
      'stop:Stop instance'
      'suspend:Suspend instance'
      'tail-serial-port-output:Tail serial output'
      'update:Update instance'
      'update-access-config:Update access config'
    )
    _describe -t commands "instances commands" commands
    return
  fi
  
  local action=$words[4]
  
  case "$action" in
    create)
      _arguments \
        '--zone[Zone]:zone:_gcloud_zones' \
        '--machine-type[Machine type]:type:_gcloud_machine_types' \
        '--image-family[Image family]:family:_gcloud_image_families' \
        '--image-project[Image project]:project: ' \
        '--boot-disk-size[Boot disk size]:size: ' \
        '--boot-disk-type[Boot disk type]:type:_gcloud_disk_types' \
        '--network[Network]:network: ' \
        '--subnet[Subnet]:subnet: ' \
        '--tags[Network tags]:tags: ' \
        '--service-account[Service account]:email: ' \
        '--scopes[Scopes]:scopes: ' \
        '--preemptible[Preemptible]' \
        '--spot[Spot VM]' \
        '--no-restart-on-failure[No restart]' \
        '--maintenance-policy[Maintenance]:policy:(MIGRATE TERMINATE)' \
        '--labels[Labels]:labels: ' \
        '--metadata[Metadata]:metadata: ' \
        '--metadata-from-file[Metadata from file]:files: ' \
        '--address[Address]:address: ' \
        '--provisioning-model[Provisioning]:model:(STANDARD SPOT)' \
        '--shielded-secure-boot[Secure boot]' \
        '--shielded-vtpm[vTPM]' \
        '--shielded-integrity-monitoring[Integrity monitoring]' \
        '--enable-nested-virtualization[Nested virt]' \
        '--min-cpu-platform[Min CPU]:platform: ' \
        '--custom-cpu[Custom CPUs]:count: ' \
        '--custom-memory[Custom memory]:memory: ' \
        '--custom-extensions[Custom extensions]' \
        '--deletion-protection[Deletion protection]' \
        '*:name: '
      ;;
    start|stop|reset|delete|describe|update|suspend|resume|resize|move)
      _arguments \
        '--zone[Zone]:zone:_gcloud_zones' \
        '*:instance:_gcloud_instances'
      ;;
    list)
      _arguments \
        '--zones[Zones]:zones:_gcloud_zones' \
        '--filter[Filter]:filter: ' \
        '--limit[Limit]:limit: ' \
        '--page-size[Page size]:size: ' \
        '--sort-by[Sort]:fields: ' \
        '--uri[Show URIs]'
      ;;
    *)
      _arguments \
        '--zone[Zone]:zone:_gcloud_zones' \
        '*:instance:_gcloud_instances'
      ;;
  esac
}

_gcloud_instances() {
  local instances=(${(f)"$(_gcloud_instances)"})
  _describe -t instances "instances" instances
}

_gcloud_zones() {
  local zones=(${(f)"$(_gcloud_zones)"})
  _describe -t zones "zones" zones
}

_gcloud_regions() {
  local regions=(${(f)"$(_gcloud_regions)"})
  _describe -t regions "regions" regions
}

_gcloud_machine_types() {
  local types=(${(f)"$(_gcloud_machine_types)"})
  _describe -t types "machine types" types
}

_gcloud_disk_types() {
  local types=(${(f)"$(_gcloud_disk_types)"})
  _describe -t types "disk types" types
}

_gcloud_image_families() {
  local families=(${(f)"$(_gcloud_image_families)"})
  _describe -t families "image families" families
}

# Container/GKE completions
_gcloud_container_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'clusters:Clusters'
      'node-pools:Node pools'
      'operations:Operations'
      'subnets:Subnets'
      'get-server-config:Get server config'
      'images:Images'
    )
    _describe -t commands "container commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    clusters)
      _gcloud_container_clusters_completion
      ;;
    node-pools)
      _arguments \
        'create:Create pool' \
        'delete:Delete pool' \
        'list:List pools' \
        'update:Update pool' \
        'rollback:Rollback' \
        '*:cluster:_gcloud_clusters'
      ;;
    *)
      _arguments \
        '*:resource: '
      ;;
  esac
}

_gcloud_container_clusters_completion() {
  if (( CURRENT == 4 )); then
    local commands=(
      'create:Create cluster'
      'create-auto:Create Autopilot'
      'delete:Delete cluster'
      'describe:Describe cluster'
      'get-credentials:Get credentials'
      'list:List clusters'
      'resize:Resize cluster'
      'update:Update cluster'
      'upgrade:Upgrade cluster'
    )
    _describe -t commands "clusters commands" commands
    return
  fi
  
  local action=$words[4]
  
  case "$action" in
    create|create-auto)
      _arguments \
        '--zone[Zone]:zone:_gcloud_zones' \
        '--region[Region]:region:_gcloud_regions' \
        '--node-locations[Node locations]:zones: ' \
        '--num-nodes[Node count]:count: ' \
        '--machine-type[Machine type]:type:_gcloud_machine_types' \
        '--disk-type[Disk type]:type:_gcloud_disk_types' \
        '--disk-size[Disk size]:size: ' \
        '--image-type[Image type]:type:(COS COS_CONTAINERD UBUNTU UBUNTU_CONTAINERD WINDOWS_SAC WINDOWS_LTSC)' \
        '--enable-autoscaling[Enable autoscaling]' \
        '--min-nodes[Min nodes]:count: ' \
        '--max-nodes[Max nodes]:count: ' \
        '--enable-autorepair[Enable autorepair]' \
        '--enable-autoupgrade[Enable autoupgrade]' \
        '--enable-cloud-logging[Enable logging]' \
        '--enable-cloud-monitoring[Enable monitoring]' \
        '--enable-network-policy[Enable network policy]' \
        '--enable-ip-alias[Enable IP alias]' \
        '--network[Network]:network: ' \
        '--subnetwork[Subnetwork]:subnet: ' \
        '--cluster-ipv4-cidr[Cluster CIDR]:cidr: ' \
        '--services-ipv4-cidr[Services CIDR]:cidr: ' \
        '--enable-private-nodes[Private nodes]' \
        '--enable-private-endpoint[Private endpoint]' \
        '--master-ipv4-cidr[Master CIDR]:cidr: ' \
        '--release-channel[Release channel]:channel:(rapid regular stable)' \
        '--cluster-version[Version]:version: ' \
        '--addons[Addons]:addons: ' \
        '--metadata[Metadata]:metadata: ' \
        '--labels[Labels]:labels: ' \
        '--tags[Tags]:tags: ' \
        '--service-account[Service account]:email: ' \
        '--enable-shielded-nodes[Shielded nodes]' \
        '--shielded-secure-boot[Secure boot]' \
        '--shielded-integrity-monitoring[Integrity monitoring]' \
        '--workload-pool[Workload pool]:pool: ' \
        '--enable-workload-identity[Workload identity]' \
        '--spot[Spot nodes]' \
        '--enable-intra-node-visibility[Intra-node visibility]' \
        '--enable-vertical-pod-autoscaling[VPA]' \
        '--enable-horizontal-pod-autoscaling[HPA]' \
        '--maintenance-window[Maintenance window]:window: ' \
        '--resource-usage-bigquery-dataset[BigQuery dataset]:dataset: ' \
        '--enable-resource-consumption-metering[Consumption metering]' \
        '--default-max-pods-per-node[Max pods]:count: ' \
        '--enable-dataplane-v2[Dataplane V2]' \
        '--enable-fqdn-network-policy[FQDN policy]' \
        '--enable-google-cloud-identity[Cloud Identity]' \
        '--enable-multi-networking[Multi-networking]' \
        '--enable-alias-kafka-broker-ip[Alias Kafka]' \
        '--enable-multi-network-gateway[Multi-network gateway]' \
        '--gateway-api[Gateway API]:version:(standard experimental)' \
        '--enable-kubernetes-alpha[Kubernetes alpha]' \
        '--enable-legacy-authorization[Legacy authorization]' \
        '--enable-master-authorized-networks[Authorized networks]' \
        '--master-authorized-networks[Networks]:networks: ' \
        '--enable-identity-service[Identity service]' \
        '--security-posture[Security posture]:posture:(standard enterprise)' \
        '--workload-vulnerability-scanning[Vuln scanning]:mode:(disabled basic standard enterprise)' \
        '--enable-managed-prometheus[Managed Prometheus]' \
        '--enable-cost-allocation[Cost allocation]' \
        '--enable-pod-security-policy[Pod security policy]' \
        '--enable-tpu[TPU]' \
        '--tpu-ipv4-cidr[TPU CIDR]:cidr: ' \
        '--enable-autoprovisioning[Autoprovisioning]' \
        '--autoprovisioning-locations[Locations]:zones: ' \
        '--autoscaling-profile[Autoscaling profile]:profile:(OPTIMIZE_UTILIZATION BALANCED)' \
        '--enable-node-autoprovisioning[Node autoprovisioning]' \
        '--max-cpu[Max CPU]:count: ' \
        '--max-memory[Max memory]:memory: ' \
        '--min-accelerator[Min accelerator]:count: ' \
        '--max-accelerator[Max accelerator]:count: ' \
        '--accelerator-type[Accelerator type]:type: ' \
        '--enable-autoprovisioning-autorepair[Autoprovision repair]' \
        '--enable-autoprovisioning-autoupgrade[Autoprovision upgrade]' \
        '--autoprovisioning-min-upgrade-nodes[Min upgrade nodes]:count: ' \
        '--autoprovisioning-max-surge-upgrade[Max surge]:count: ' \
        '--autoprovisioning-max-unavailable-upgrade[Max unavailable]:count: ' \
        '--enable-autoprovisioning-autoscaling[Autoprovision autoscaling]' \
        '--autoprovisioning-locations[Autoprovision locations]:zones: ' \
        '--enable-autoprovisioning-surge-upgrade[Surge upgrade]' \
        '--enable-autoprovisioning-blue-green-upgrade[Blue-green upgrade]' \
        '--enable-autoprovisioning-node-pool-soak-duration[Soak duration]:duration: ' \
        '--enable-autoprovisioning-standard-upgrade[Standard upgrade]' \
        '--enable-autoprovisioning-max-surge-upgrade[Max surge upgrade]:count: ' \
        '--enable-autoprovisioning-max-unavailable-upgrade[Max unavailable]:count: ' \
        '--enable-autoprovisioning-node-pool-auto-repair[Auto repair]' \
        '--enable-autoprovisioning-node-pool-auto-upgrade[Auto upgrade]' \
        '--enable-autoprovisioning-node-pool-autoscaling[Autoscaling]' \
        '--enable-autoprovisioning-node-pool-management[Management]' \
        '--enable-autoprovisioning-node-pool-upgrade[Upgrade]' \
        '--enable-autoprovisioning-node-pool-rollback[Rollback]' \
        '--enable-autoprovisioning-node-pool-resize[Resize]' \
        '--enable-autoprovisioning-node-pool-update[Update]' \
        '--enable-autoprovisioning-node-pool-delete[Delete]' \
        '--enable-autoprovisioning-node-pool-create[Create]' \
        '*:name: '
      ;;
    delete|describe|get-credentials|resize|update|upgrade)
      _arguments \
        '--zone[Zone]:zone:_gcloud_zones' \
        '--region[Region]:region:_gcloud_regions' \
        '*:cluster:_gcloud_clusters'
      ;;
    list)
      _arguments \
        '--zone[Zone]:zone:_gcloud_zones' \
        '--region[Region]:region:_gcloud_regions'
      ;;
  esac
}

_gcloud_clusters() {
  local clusters=(${(f)"$(_gcloud_clusters)"})
  _describe -t clusters "clusters" clusters
}

# Cloud Run completions
_gcloud_run_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'deploy:Deploy service'
      'services:Services'
      'revisions:Revisions'
      'domain-mappings:Domain mappings'
      'jobs:Jobs'
      'triggers:Triggers'
    )
    _describe -t commands "run commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    deploy)
      _arguments \
        '--image[Container image]:image: ' \
        '--source[Source directory]:dir:_files -/' \
        '--port[Port]:port: ' \
        '--env[Environment]:envs: ' \
        '--env-vars-file[Env file]:file:_files' \
        '--memory[Memory]:memory: ' \
        '--cpu[CPU]:cpu: ' \
        '--concurrency[Concurrency]:count: ' \
        '--max-instances[Max instances]:count: ' \
        '--min-instances[Min instances]:count: ' \
        '--timeout[Timeout]:duration: ' \
        '--service-account[Service account]:email: ' \
        '--ingress[Ingress]:ingress:(all internal internal-and-cloud-load-balancing)' \
        '--egress[Egress]:egress:(all private-ranges-only)' \
        '--vpc-connector[VPC connector]:connector: ' \
        '--vpc-egress[VPC egress]:egress:(all private-ranges-only private-ranges-only)' \
        '--region[Region]:region:_gcloud_regions' \
        '--platform[Platform]:platform:(managed gke anthos)' \
        '--no-traffic[No traffic]' \
        '--tag[Tag]:tag: ' \
        '--revision-suffix[Suffix]:suffix: ' \
        '--labels[Labels]:labels: ' \
        '--annotations[Annotations]:annotations: ' \
        '--command[Command]:cmd: ' \
        '--args[Args]:args: ' \
        '--clear-env[Clear env]' \
        '--remove-env[Remove env]:vars: ' \
        '--set-cloudsql-instances[Cloud SQL]:instances: ' \
        '--remove-cloudsql-instances[Remove Cloud SQL]:instances: ' \
        '--clear-cloudsql-instances[Clear Cloud SQL]' \
        '--update-secrets[Secrets]:secrets: ' \
        '--set-secrets[Set secrets]:secrets: ' \
        '--remove-secrets[Remove secrets]:secrets: ' \
        '--clear-secrets[Clear secrets]' \
        '--update-labels[Update labels]:labels: ' \
        '--remove-labels[Remove labels]:labels: ' \
        '--clear-labels[Clear labels]' \
        '--allow-unauthenticated[Allow unauthenticated]' \
        '--no-allow-unauthenticated[No unauthenticated]' \
        '--breakglass[Breakglass]' \
        '--binary-authorization[Binary Auth]:policy: ' \
        '--use-http2[Use HTTP/2]' \
        '--execution-environment[Environment]:env:(gen1 gen2)' \
        '--session-affinity[Session affinity]' \
        '--startup-probe[Startup probe]:probe: ' \
        '--liveness-probe[Liveness probe]:probe: ' \
        '--no-startup-probe[No startup probe]' \
        '--no-liveness-probe[No liveness probe]' \
        '--max-surge[Max surge]:count: ' \
        '--max-unavailable[Max unavailable]:count: ' \
        '--sandbox[Sandbox]:sandbox:(gvisor)' \
        '--sql-instances[SQL instances]:instances: ' \
        '--use-http1[Use HTTP/1]' \
        '--async[Async]' \
        '*:service:_gcloud_run_services'
      ;;
    services)
      _arguments \
        'describe:Describe' \
        'list:List' \
        'delete:Delete' \
        'update:Update' \
        'add-iam-policy-binding:Add IAM' \
        'remove-iam-policy-binding:Remove IAM' \
        'get-iam-policy:Get IAM' \
        'set-iam-policy:Set IAM' \
        '--region[Region]:region:_gcloud_regions' \
        '*:service:_gcloud_run_services'
      ;;
    revisions)
      _arguments \
        'delete:Delete' \
        'describe:Describe' \
        'list:List' \
        '--region[Region]:region:_gcloud_regions' \
        '*:revision: '
      ;;
    *)
      _arguments \
        '--region[Region]:region:_gcloud_regions' \
        '*:resource: '
      ;;
  esac
}

_gcloud_run_services() {
  local services=(${(f)"$(_gcloud_run_services)"})
  _describe -t services "services" services
}

# Functions completions
_gcloud_functions_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'deploy:Deploy function'
      'describe:Describe function'
      'list:List functions'
      'delete:Delete function'
      'call:Call function'
      'logs:Logs'
      'add-iam-policy-binding:Add IAM'
      'remove-iam-policy-binding:Remove IAM'
      'get-iam-policy:Get IAM'
      'set-iam-policy:Set IAM'
    )
    _describe -t commands "functions commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    deploy)
      _arguments \
        '--runtime[Runtime]:runtime:(nodejs20 nodejs18 python311 python310 go121 go120 java17 java11 dotnet6 ruby32 php82)' \
        '--trigger-http[HTTP trigger]' \
        '--trigger-topic[Pub/Sub trigger]:topic: ' \
        '--trigger-bucket[Storage trigger]:bucket: ' \
        '--trigger-event[Event trigger]:event: ' \
        '--trigger-resource[Resource]:resource: ' \
        '--entry-point[Entry point]:function: ' \
        '--source[Source]:dir:_files -/' \
        '--stage-bucket[Stage bucket]:bucket: ' \
        '--memory[Memory]:memory: ' \
        '--timeout[Timeout]:duration: ' \
        '--max-instances[Max instances]:count: ' \
        '--min-instances[Min instances]:count: ' \
        '--concurrency[Concurrency]:count: ' \
        '--service-account[Service account]:email: ' \
        '--env-vars-file[Env file]:file:_files' \
        '--set-env-vars[Env vars]:vars: ' \
        '--remove-env-vars[Remove vars]:vars: ' \
        '--clear-env-vars[Clear env]' \
        '--labels[Labels]:labels: ' \
        '--vpc-connector[VPC connector]:connector: ' \
        '--egress-settings[Egress]:egress:(all private-ranges-only)' \
        '--ingress-settings[Ingress]:ingress:(all internal-only allow-internal-only)' \
        '--build-env-vars[Build env]:vars: ' \
        '--build-env-vars-file[Build env file]:file:_files' \
        '--set-build-env-vars[Set build env]:vars: ' \
        '--remove-build-env-vars[Remove build env]:vars: ' \
        '--clear-build-env-vars[Clear build env]' \
        '--update-labels[Update labels]:labels: ' \
        '--remove-labels[Remove labels]:labels: ' \
        '--clear-labels[Clear labels]' \
        '--update-build-env-vars[Update build env]:vars: ' \
        '--remove-build-env-vars[Remove build env]:vars: ' \
        '--clear-build-env-vars[Clear build env]' \
        '--runtime[Runtime]:runtime:(nodejs20 nodejs18 python311 python310 go121 go120 java17 java11 dotnet6 ruby32 php82)' \
        '--trigger-http[HTTP trigger]' \
        '--trigger-topic[Pub/Sub trigger]:topic: ' \
        '--trigger-bucket[Storage trigger]:bucket: ' \
        '--trigger-event[Event trigger]:event: ' \
        '--trigger-resource[Resource]:resource: ' \
        '--entry-point[Entry point]:function: ' \
        '--source[Source]:dir:_files -/' \
        '--stage-bucket[Stage bucket]:bucket: ' \
        '--region[Region]:region:_gcloud_regions' \
        '--gen2[Gen 2]' \
        '--no-gen2[No Gen 2]' \
        '--allow-unauthenticated[Allow unauth]' \
        '--no-allow-unauthenticated[No unauth]' \
        '--ingress-settings[Ingress]:ingress:(all internal-only allow-internal-only)' \
        '--egress-settings[Egress]:egress:(all private-ranges-only)' \
        '--vpc-connector[VPC connector]:connector: ' \
        '--set-build-env-vars[Build env]:vars: ' \
        '--remove-build-env-vars[Remove build env]:vars: ' \
        '--clear-build-env-vars[Clear build env]' \
        '--service-account[Service account]:email: ' \
        '--timeout[Timeout]:duration: ' \
        '--max-instances[Max instances]:count: ' \
        '--min-instances[Min instances]:count: ' \
        '--concurrency[Concurrency]:count: ' \
        '--memory[Memory]:memory: ' \
        '--retry[Retry]' \
        '--no-retry[No retry]' \
        '--update-labels[Update labels]:labels: ' \
        '--remove-labels[Remove labels]:labels: ' \
        '--clear-labels[Clear labels]' \
        '--build-worker-pool[Worker pool]:pool: ' \
        '--kms-key[KMS key]:key: ' \
        '--docker-registry[Registry]:registry:(artifact-registry container-registry)' \
        '--docker-repository[Repository]:repo: ' \
        '--async[Async]' \
        '--security-level[Security]:level:(secure-optional secure-always)' \
        '--cpu[CPU]:cpu:(gcf_gen1 gcf_gen2)' \
        '--set-env-vars[Env vars]:vars: ' \
        '--remove-env-vars[Remove vars]:vars: ' \
        '--clear-env-vars[Clear env]' \
        '--env-vars-file[Env file]:file:_files' \
        '*:name:_gcloud_functions'
      ;;
    delete|describe|call)
      _arguments \
        '--region[Region]:region:_gcloud_regions' \
        '--data[Data]:data: ' \
        '--data-file[Data file]:file:_files' \
        '*:function:_gcloud_functions'
      ;;
    list)
      _arguments \
        '--regions[Regions]:regions:_gcloud_regions'
      ;;
    logs)
      _arguments \
        '--region[Region]:region:_gcloud_regions' \
        '--limit[Limit]:limit: ' \
        '--filter[Filter]:filter: ' \
        '--format[Format]:format: ' \
        '*:function:_gcloud_functions'
      ;;
  esac
}

_gcloud_functions() {
  local functions=(${(f)"$(_gcloud_functions)"})
  _describe -t functions "functions" functions
}

# App Engine completions
_gcloud_app_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'browse:Browse app'
      'create:Create app'
      'deploy:Deploy'
      'describe:Describe app'
      'domain-mappings:Domain mappings'
      'firewall-rules:Firewall rules'
      'logs:Logs'
      'open-console:Open console'
      'regions:Regions'
      'services:Services'
      'ssl-certificates:SSL certificates'
      'update:Update app'
      'versions:Versions'
    )
    _describe -t commands "app commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    deploy)
      _arguments \
        '--version[Version]:version: ' \
        '--no-promote[No promote]' \
        '--promote[Promote]' \
        '--stop-previous-version[Stop previous]' \
        '--no-stop-previous-version[No stop]' \
        '--image-url[Image URL]:url: ' \
        '--appyaml[App YAML]:file:_files' \
        '--appyaml-dir[App YAML dir]:dir:_files -/' \
        '--bucket[Bucket]:bucket: ' \
        '--no-cache[No cache]' \
        '--no-prune[No prune]' \
        '--quiet[Quiet]' \
        '--retain-backups[Retain backups]' \
        '--retain-backups-days[Retention days]:days: ' \
        '--service[SERVICE]:service:_gcloud_app_services' \
        '--update-checksums[Update checksums]' \
        '--no-update-checksums[No update]' \
        '--vpc-connector[VPC connector]:connector: ' \
        '--clear-vpc-connector[Clear VPC]' \
        '--vpc-egress[Egress]:egress:(all private-ranges-only)' \
        '--clear-build-env-vars[Clear build env]' \
        '--set-build-env-vars[Build env]:vars: ' \
        '--update-build-env-vars[Update build env]:vars: ' \
        '--remove-build-env-vars[Remove build env]:vars: ' \
        '--build-env-vars-file[Build env file]:file:_files' \
        '--update-labels[Update labels]:labels: ' \
        '--remove-labels[Remove labels]:labels: ' \
        '--clear-labels[Clear labels]' \
        '--labels-file[Labels file]:file:_files' \
        '--set-managed-by[Managed by]:managed: ' \
        '--set-build-service-account[Build SA]:email: ' \
        '--clear-build-service-account[Clear build SA]' \
        '--no-use-cloud-build[No Cloud Build]' \
        '--use-cloud-build[Cloud Build]' \
        '--cloud-build-timeout[Timeout]:duration: ' \
        '--no-ignore-file[No ignore file]' \
        '--ignore-file[Ignore file]:file:_files' \
        '*:files:_files'
      ;;
    services)
      _arguments \
        'browse:Browse' \
        'delete:Delete' \
        'describe:Describe' \
        'list:List' \
        'set-traffic:Set traffic' \
        '--service[SERVICE]:service:_gcloud_app_services'
      ;;
    versions)
      _arguments \
        'browse:Browse' \
        'delete:Delete' \
        'describe:Describe' \
        'list:List' \
        'migrate:Migrate' \
        'start:Start' \
        'stop:Stop' \
        '--service[SERVICE]:service:_gcloud_app_services' \
        '--version[VERSION]:version: '
      ;;
    logs)
      _arguments \
        '--service[SERVICE]:service:_gcloud_app_services' \
        '--version[VERSION]:version: ' \
        '--limit[Limit]:limit: ' \
        '--severity[Minimum severity]:severity:(debug info warning error critical)' \
        '--filters[Filters]:filters: ' \
        '--format[Format]:format: ' \
        '--level[Level]:level:(any debug info warning error critical)' \
        '--tail[Follow]' \
        '--until[Until time]:time: ' \
        '--after[After time]:time: ' \
        '--flatten[Flatten]:flatten: ' \
        '--sort-by[Sort by]:sort: ' \
        '--trace[Trace ID]:trace: '
      ;;
    *)
      _arguments \
        '--service[SERVICE]:service:_gcloud_app_services' \
        '--version[VERSION]:version: ' \
        '*:resource: '
      ;;
  esac
}

_gcloud_app_services() {
  local services=(${(f)"$(_gcloud_app_services)"})
  _describe -t services "services" services
}

# Simple stubs for remaining services
_gcloud_storage_completion() { _message 'Cloud Storage commands'; }
_gcloud_sql_completion() { _message 'Cloud SQL commands'; }
_gcloud_pubsub_completion() { _message 'Cloud Pub/Sub commands'; }
_gcloud_iam_completion() { _message 'IAM commands'; }
_gcloud_kms_completion() { _message 'Cloud KMS commands'; }
_gcloud_secrets_completion() { _message 'Secret Manager commands'; }
_gcloud_builds_completion() { _message 'Cloud Build commands'; }
_gcloud_artifacts_completion() { _message 'Artifact Registry commands'; }
_gcloud_scheduler_completion() { _message 'Cloud Scheduler commands'; }
_gcloud_tasks_completion() { _message 'Cloud Tasks commands'; }
_gcloud_logging_completion() { _message 'Cloud Logging commands'; }
_gcloud_monitoring_completion() { _message 'Cloud Monitoring commands'; }

# Config completions
_gcloud_config_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'configurations:Configurations'
      'get-value:Get value'
      'list:List properties'
      'set:Set property'
      'unset:Unset property'
    )
    _describe -t commands "config commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    configurations)
      _arguments \
        'activate:Activate' \
        'create:Create' \
        'delete:Delete' \
        'describe:Describe' \
        'list:List' \
        'rename:Rename' \
        '*:config:_gcloud_configurations'
      ;;
    get-value|set|unset)
      _arguments \
        '--scope[Scope]:scope:(installation user workspace)' \
        '*:property: '
      ;;
  esac
}

_gcloud_configurations() {
  local configs=(${(f)"$(_gcloud_configurations)"})
  _describe -t configs "configurations" configs
}

# Projects completions
_gcloud_projects_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'add-iam-policy-binding:Add IAM'
      'create:Create project'
      'delete:Delete project'
      'describe:Describe project'
      'get-ancestors:Get ancestors'
      'get-ancestors-iam-policies:Get IAM ancestors'
      'get-iam-policy:Get IAM'
      'list:List projects'
      'move:Move project'
      'remove-iam-policy-binding:Remove IAM'
      'set-iam-policy:Set IAM'
      'undelete:Undelete'
      'update:Update project'
    )
    _describe -t commands "projects commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    create)
      _arguments \
        '--name[Name]:name: ' \
        '--enable-cloud-apis[Enable APIs]' \
        '--labels[Labels]:labels: ' \
        '--folder[FOLDER]:folder: ' \
        '--organization[Organization]:org: ' \
        '--set-as-default[Set default]' \
        '*:project_id: '
      ;;
    delete|describe|undelete|update|move|get-ancestors|get-ancestors-iam-policies)
      _arguments \
        '*:project:_gcloud_projects'
      ;;
    list)
      _arguments \
        '--filter[Filter]:filter: ' \
        '--limit[Limit]:limit: ' \
        '--page-size[Page size]:size: ' \
        '--sort-by[Sort]:fields: ' \
        '--uri[Show URIs]'
      ;;
    *)
      _arguments \
        '*:project:_gcloud_projects'
      ;;
  esac
}

_gcloud_projects() {
  local projects=(${(f)"$(_gcloud_projects)"})
  _describe -t projects "projects" projects
}

# Services completions
_gcloud_services_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'disable:Disable service'
      'enable:Enable service'
      'list:List services'
      'vpc-peerings:VPC peerings'
    )
    _describe -t commands "services commands" commands
    return
  fi
  
  _arguments \
    '--available[Available services]' \
    '--enabled[Enabled services]' \
    '--filter[Filter]:filter: ' \
    '--limit[Limit]:limit: ' \
    '--page-size[Page size]:size: ' \
    '--sort-by[Sort]:fields: ' \
    '*:service: '
}

# Auth completions
_gcloud_auth_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'activate-service-account:Activate SA'
      'application-default:Application default'
      'configure-docker:Configure Docker'
      'gcloud-login:Gcloud login'
      'list:List creds'
      'login:Login'
      'logout:Logout'
      'print-access-token:Print token'
      'print-identity-token:Print identity'
      'revoke:Revoke'
    )
    _describe -t commands "auth commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    login)
      _arguments \
        '--cred-file[Cred file]:file:_files' \
        '--remote-bootstrap[Remote bootstrap]:bootstrap: ' \
        '--launch-browser[Launch browser]' \
        '--no-launch-browser[No browser]' \
        '--update-adc[Update ADC]' \
        '--no-update-adc[No ADC]' \
        '--force[Force]' \
        '--brief[Brief]' \
        '--enable-gdrive-access[GDrive access]' \
        '--no-enable-gdrive-access[No GDrive]' \
        '--client-id-file[Client ID]:file:_files' \
        '*:account: '
      ;;
    activate-service-account)
      _arguments \
        '--key-file[Key file]:file:_files' \
        '--password-file[Password file]:file:_files' \
        '--prompt-for-password[Prompt]' \
        '--no-prompt-for-password[No prompt]' \
        '--project[Project]:project:_gcloud_projects' \
        '--lifetime[Lifetime]:seconds: ' \
        '--scopes[Scopes]:scopes: ' \
        '--no-scopes[No scopes]' \
        '--no-activate[No activate]' \
        '--no-user-output-enabled[No output]' \
        '--user-output-enabled[Output]' \
        '--verbosity[Verbosity]:verbosity:(debug info warning error critical none)' \
        '--trace-token[Trace token]:token: ' \
        '--log-http[Log HTTP]' \
        '--no-log-http[No log]' \
        '--access-token-file[Token file]:file:_files' \
        '--impersonate-service-account[Impersonate]:email: ' \
        '*:account: '
      ;;
    *)
      _arguments \
        '*:account: '
      ;;
  esac
}

# Source completions
_gcloud_source_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'repos:Repos'
      'project-configs:Project configs'
    )
    _describe -t commands "source commands" commands
    return
  fi
  
  _arguments \
    'clone:Clone' \
    'create:Create' \
    'delete:Delete' \
    'describe:Describe' \
    'list:List' \
    'update:Update' \
    'get-iam-policy:Get IAM' \
    'set-iam-policy:Set IAM' \
    '*:repo: '
}

# Register enhanced completion
compdef _gcloud_enhanced gcloud

# Source gcloud completion if available
if [[ -f "$CLOUDSDK_HOME/completion.zsh.inc" ]]; then
  source "$CLOUDSDK_HOME/completion.zsh.inc"
fi

# ============================================================
# ALIASES
# ============================================================

alias gcpinfo='gcloud info'
alias gcpconfig='gcloud config list'
alias gcpprojects='gcloud projects list'
alias gcpzones='gcloud compute zones list'
alias gcpregions='gcloud compute regions list'
alias gcpswitch='gcloud config configurations activate'
alias gcpsetproject='gcloud config set project'
alias gcpinstances='gcloud compute instances list'
alias gcpclusters='gcloud container clusters list'
alias gcpfunctions='gcloud functions list'
alias gcprunservices='gcloud run services list'
alias gcpssh='gcloud compute ssh'
alias gcppush='gcloud builds submit'
alias gcpdeploy='gcloud app deploy'
alias gcpbrowse='gcloud app browse'
alias gcpcontainers='gcloud container images list'
alias gcplogs='gcloud logging logs list'
alias gcpbuckets='gcloud storage buckets list'
