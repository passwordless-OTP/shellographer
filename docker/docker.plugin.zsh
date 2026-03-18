# Docker aliases
alias d='docker'
alias dbl='docker build'
alias dcin='docker container inspect'
alias dcls='docker container ls'
alias dclsa='docker container ls -a'
alias dib='docker image build'
alias dii='docker image inspect'
alias dils='docker image ls'
alias dipu='docker image push'
alias dipru='docker image prune -a'
alias dirm='docker image rm'
alias dit='docker image tag'
alias dlo='docker container logs'
alias dnc='docker network create'
alias dncn='docker network connect'
alias dndcn='docker network disconnect'
alias dni='docker network inspect'
alias dnls='docker network ls'
alias dnrm='docker network rm'
alias dpo='docker container port'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dpu='docker pull'
alias dr='docker container run'
alias drit='docker container run -it'
alias drm='docker container rm'
alias 'drm!'='docker container rm -f'
alias dst='docker container start'
alias drs='docker container restart'
alias dsta='docker stop $(docker ps -q)'
alias dstp='docker container stop'
alias dsts='docker stats'
alias dtop='docker top'
alias dvi='docker volume inspect'
alias dvls='docker volume ls'
alias dvprune='docker volume prune'
alias dxc='docker container exec'
alias dxcit='docker container exec -it'

# Enhanced Docker aliases
alias dcomp='docker compose'
alias dcompup='docker compose up -d'
alias dcompdown='docker compose down'
alias dcompbuild='docker compose build'
alias dcomplogs='docker compose logs -f'
alias dcompps='docker compose ps'
alias dcomprestart='docker compose restart'
alias dprune='docker system prune -f'
alias dpruneall='docker system prune -a --volumes -f'
alias dnuke='docker rm -f $(docker ps -aq) 2>/dev/null; docker volume rm $(docker volume ls -q) 2>/dev/null; docker network prune -f'

if (( ! $+commands[docker] )); then
  return
fi

# Standardized $0 handling
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# ============================================================
# DOCKER DAEMON & ENVIRONMENT CHECKS
# ============================================================

# Check if Docker daemon is running
_docker_daemon_check() {
  docker info &>/dev/null
}

# Check if using Podman (docker -> podman alias)
_docker_is_podman() {
  [[ "$(_docker_binary)" == *podman* ]] || docker --version 2>/dev/null | grep -qi podman
}

# Get the actual docker binary (handles podman alias)
_docker_binary() {
  if (( $+commands[podman] )) && [[ $(whence -p docker) == $(whence -p podman) ]]; then
    echo "podman"
  else
    echo "docker"
  fi
}

# Show warning if docker daemon is not running
_docker_warn_if_down() {
  if ! _docker_daemon_check; then
    echo "${fg[yellow]}⚠️  Docker daemon is not running${reset_color}" >&2
    return 1
  fi
  return 0
}

# Get current docker context
_docker_current_context() {
  docker context show 2>/dev/null || echo "default"
}

# List docker contexts
_docker_contexts() {
  docker context ls --format '{{.Name}}:{{.Description}}' 2>/dev/null
}

# ============================================================
# ENHANCED DOCKER COMPLETIONS
# ============================================================

# Cache directories for dynamic completions
_docker_cache_dir="${ZSH_CACHE_DIR}/docker"
mkdir -p "$_docker_cache_dir"

# Validate cache file isn't empty and is fresh enough
_docker_cache_valid() {
  local cache_file="$1"
  local max_age="${2:-60}"  # Default 60 seconds
  
  [[ ! -f "$cache_file" ]] && return 1
  [[ ! -s "$cache_file" ]] && return 1
  
  local age=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  [[ $age -le $max_age ]]
}

# Get running containers with descriptions
_docker_running_containers() {
  local cache_file="$_docker_cache_dir/running_containers"
  
  # Don't try to fetch if daemon is down
  if ! _docker_daemon_check; then
    [[ -f "$cache_file" ]] && cat "$cache_file"  # Return stale cache
    return
  fi
  
  if ! _docker_cache_valid "$cache_file" 5; then
    docker ps --format '{{.Names}}:{{.Image}} ({{.Status}})' 2>/dev/null >| "$cache_file" || true
  fi
  
  [[ -s "$cache_file" ]] && cat "$cache_file"
}

# Get all containers (running and stopped)
_docker_all_containers() {
  local cache_file="$_docker_cache_dir/all_containers"
  
  if ! _docker_daemon_check; then
    [[ -f "$cache_file" ]] && cat "$cache_file"
    return
  fi
  
  if ! _docker_cache_valid "$cache_file" 5; then
    docker ps -a --format '{{.Names}}:{{.Image}} ({{.Status}})' 2>/dev/null >| "$cache_file" || true
  fi
  
  [[ -s "$cache_file" ]] && cat "$cache_file"
}

# Get container IDs
_docker_container_ids() {
  docker ps -q 2>/dev/null
}

# Get all container IDs
_docker_all_container_ids() {
  docker ps -aq 2>/dev/null
}

# Get images with descriptions
_docker_images() {
  local cache_file="$_docker_cache_dir/images"
  
  if ! _docker_daemon_check; then
    [[ -f "$cache_file" ]] && cat "$cache_file"
    return
  fi
  
  if ! _docker_cache_valid "$cache_file" 30; then
    docker images --format '{{.Repository}}:{{.Tag}} ({{.Size}})' 2>/dev/null | grep -v '<none>' >| "$cache_file" || true
  fi
  
  [[ -s "$cache_file" ]] && cat "$cache_file"
}

# Get image IDs
_docker_image_ids() {
  docker images -q 2>/dev/null | sort -u
}

# Get volumes
_docker_volumes() {
  local cache_file="$_docker_cache_dir/volumes"
  
  if ! _docker_daemon_check; then
    [[ -f "$cache_file" ]] && cat "$cache_file"
    return
  fi
  
  if ! _docker_cache_valid "$cache_file" 30; then
    docker volume ls --format '{{.Name}}:{{.Driver}}' 2>/dev/null >| "$cache_file" || true
  fi
  
  [[ -s "$cache_file" ]] && cat "$cache_file"
}

# Get networks
_docker_networks() {
  local cache_file="$_docker_cache_dir/networks"
  
  if ! _docker_daemon_check; then
    [[ -f "$cache_file" ]] && cat "$cache_file"
    return
  fi
  
  if ! _docker_cache_valid "$cache_file" 60; then
    docker network ls --format '{{.Name}}:{{.Driver}}' 2>/dev/null >| "$cache_file" || true
  fi
  
  [[ -s "$cache_file" ]] && cat "$cache_file"
}

# Get compose services
_docker_compose_services() {
  if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]] || [[ -f "compose.yml" ]] || [[ -f "compose.yaml" ]]; then
    docker compose config --services 2>/dev/null
  fi
}

# Get compose profiles
_docker_compose_profiles() {
  if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]] || [[ -f "compose.yml" ]] || [[ -f "compose.yaml" ]]; then
    docker compose config --profiles 2>/dev/null
  fi
}

# Get Dockerfile build stages
_dockerfile_stages() {
  local dockerfile="${1:-Dockerfile}"
  [[ -f "$dockerfile" ]] || return
  grep -iE '^FROM\s+.*\s+AS\s+' "$dockerfile" | sed -E 's/.*AS\s+([a-zA-Z0-9_-]+).*/\1/i'
}

# Context-aware container completion
_docker_complete_containers() {
  local state=$1
  local -a containers
  
  case "$state" in
    running)
      containers=(${(f)"$(_docker_running_containers)"})
      _describe -t containers "running containers" containers
      ;;
    all)
      containers=(${(f)"$(_docker_all_containers)"})
      _describe -t containers "containers" containers
      ;;
    stopped)
      local all=(${(f)"$(_docker_all_containers)"})
      local running=(${(f)"$(_docker_running_containers)"})
      local stopped=()
      for c in "$all[@]"; do
        local name="${c%%:*}"
        [[ ! " ${running[@]} " =~ " $name " ]] && stopped+=($c)
      done
      _describe -t containers "stopped containers" stopped
      ;;
  esac
}

# Context-aware image completion
_docker_complete_images() {
  local -a images
  images=(${(f)"$(_docker_images)"})
  _describe -t images "images" images
}

# Volume completion
_docker_complete_volumes() {
  local -a volumes
  volumes=(${(f)"$(_docker_volumes)"})
  _describe -t volumes "volumes" volumes
}

# Network completion
_docker_complete_networks() {
  local -a networks
  networks=(${(f)"$(_docker_networks)"})
  _describe -t networks "networks" networks
}

# Enhanced docker completion function
_docker_enhanced() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  # Get the current command position
  local cmd=$line[1]
  local subcmd=$line[2]
  
  # Complete based on context
  if (( CURRENT == 2 )); then
    # Main docker commands
    local commands=(
      'run:Run a command in a new container'
      'exec:Run a command in a running container'
      'ps:List containers'
      'build:Build an image from a Dockerfile'
      'pull:Pull an image or a repository'
      'push:Push an image or a repository'
      'images:List images'
      'rmi:Remove images'
      'rm:Remove containers'
      'stop:Stop containers'
      'start:Start containers'
      'restart:Restart containers'
      'kill:Kill running containers'
      'logs:Fetch logs'
      'inspect:Return low-level info'
      'top:Display running processes'
      'stats:Display live stream of resource usage'
      'diff:Inspect changes on filesystem'
      'cp:Copy files/folders'
      'port:List port mappings'
      'commit:Create new image from container'
      'export:Export container filesystem'
      'import:Import tarball to create image'
      'save:Save images to tar archive'
      'load:Load images from tar archive'
      'login:Log in to registry'
      'logout:Log out from registry'
      'search:Search Docker Hub'
      'version:Show version'
      'info:Display system-wide info'
      'system:Manage Docker'
      'volume:Manage volumes'
      'network:Manage networks'
      'container:Manage containers'
      'image:Manage images'
      'compose:Docker Compose'
    )
    _describe -t commands "docker command" commands
    return
  fi
  
  # Subcommand completions
  case "$subcmd" in
    run)
      _arguments \
        '(-d --detach)'{-d,--detach}'[Run in background]' \
        '(-i --interactive)'{-i,--interactive}'[Keep STDIN open]' \
        '(-t --tty)'{-t,--tty}'[Allocate pseudo-TTY]' \
        '--rm[Auto-remove on exit]' \
        '(-p --publish)'{-p,--publish}'[Publish port]:port:' \
        '(-e --env)'{-e,--env}'[Set environment]:env:' \
        '(-v --volume)'{-v,--volume}'[Bind mount]:volume:_docker_complete_volumes' \
        '--network[Connect to network]:network:_docker_complete_networks' \
        '--name[Container name]:name:' \
        '*:image:_docker_complete_images'
      ;;
    exec)
      _arguments \
        '(-d --detach)'{-d,--detach}'[Run in background]' \
        '(-i --interactive)'{-i,--interactive}'[Keep STDIN open]' \
        '(-t --tty)'{-t,--tty}'[Allocate pseudo-TTY]' \
        '(-w --workdir)'{-w,--workdir}'[Working directory]:dir:_files -/' \
        '1:container:_docker_complete_containers running' \
        '*::command:_path_commands'
      ;;
    ps)
      _arguments \
        '(-a --all)'{-a,--all}'[Show all]' \
        '(-q --quiet)'{-q,--quiet}'[Only IDs]' \
        '--filter[Filter output]:filter:' \
        '--format[Pretty-print]:format:' \
        '--last[Show last n]:n:' \
        '(-s --size)'{-s,--size}'[Display total file sizes]'
      ;;
    build)
      _arguments \
        '(-t --tag)'{-t,--tag}'[Name and tag]:tag:' \
        '(-f --file)'{-f,--file}'[Dockerfile]:file:_files' \
        '--target[Build stage]:stage:_dockerfile_stages' \
        '--build-arg[Build argument]:arg:' \
        '--cache-from[Cache source]:image:' \
        '--pull[Always pull]' \
        '--no-cache[Do not use cache]' \
        '--squash[Squash layers]' \
        '--compress[Compress build context]' \
        '--label[Set metadata]:label:' \
        '*:path:_files -/'
      ;;
    rm)
      _arguments \
        '(-f --force)'{-f,--force}'[Force removal]' \
        '(-v --volumes)'{-v,--volumes}'[Remove volumes]' \
        '*:container:_docker_complete_containers all'
      ;;
    stop|kill)
      _arguments \
        '(-t --time)'{-t,--time}'[Seconds to wait]:seconds:' \
        '*:container:_docker_complete_containers running'
      ;;
    start|restart)
      _arguments \
        '(-a --attach)'{-a,--attach}'[Attach stdout/err]' \
        '(-i --interactive)'{-i,--interactive}'[Attach stdin]' \
        '*:container:_docker_complete_containers stopped'
      ;;
    logs)
      _arguments \
        '(-f --follow)'{-f,--follow}'[Follow log output]' \
        '--tail[Number of lines]:lines:' \
        '(-t --timestamps)'{-t,--timestamps}'[Show timestamps]' \
        '--since[Show since timestamp]:time:' \
        '--until[Show until timestamp]:time:' \
        '*:container:_docker_complete_containers all'
      ;;
    inspect)
      _arguments \
        '(-f --format)'{-f,--format}'[Format output]:format:' \
        '(-s --size)'{-s,--size}'[Display total file sizes]' \
        '--type[Return JSON for specified type]:type:(container image network volume)' \
        '*:object:_docker_complete_containers all'
      ;;
    cp)
      _arguments \
        '(-a --archive)'{-a,--archive}'[Archive mode]' \
        '(-L --follow-link)'{-L,--follow-link}'[Follow symlinks]' \
        '1:source:_docker_cp_source' \
        '2:destination:_docker_cp_dest'
      ;;
    volume)
      local volcmd=$line[3]
      if (( CURRENT == 3 )); then
        local vcommands=(
          'create:Create volume'
          'inspect:Display info'
          'ls:List volumes'
          'prune:Remove unused'
          'rm:Remove volume'
        )
        _describe -t commands "volume command" vcommands
      else
        case "$volcmd" in
          rm|inspect)
            _arguments '*:volume:_docker_complete_volumes'
            ;;
        esac
      fi
      ;;
    network)
      local netcmd=$line[3]
      if (( CURRENT == 3 )); then
        local ncommands=(
          'connect:Connect container'
          'create:Create network'
          'disconnect:Disconnect container'
          'inspect:Display info'
          'ls:List networks'
          'prune:Remove unused'
          'rm:Remove network'
        )
        _describe -t commands "network command" ncommands
      else
        case "$netcmd" in
          rm|inspect)
            _arguments '*:network:_docker_complete_networks'
            ;;
          connect|disconnect)
            _arguments '1:network:_docker_complete_networks' '2:container:_docker_complete_containers all'
            ;;
        esac
      fi
      ;;
    compose)
      local compcmd=$line[3]
      if (( CURRENT == 3 )); then
        local ccommands=(
          'build:Build services'
          'config:Parse and output config'
          'cp:Copy files'
          'create:Create containers'
          'down:Stop and remove'
          'events:Receive events'
          'exec:Execute command'
          'images:List images'
          'kill:Kill containers'
          'logs:View logs'
          'ls:List running projects'
          'pause:Pause services'
          'port:Print public port'
          'ps:List containers'
          'pull:Pull images'
          'push:Push images'
          'restart:Restart containers'
          'rm:Remove stopped'
          'run:Run one-off command'
          'start:Start services'
          'stop:Stop services'
          'top:Display processes'
          'unpause:Unpause services'
          'up:Create and start'
          'wait:Wait for containers'
        )
        _describe -t commands "compose command" ccommands
      else
        case "$compcmd" in
          up)
            _arguments \
              '(-d --detach)'{-d,--detach}'[Detached mode]' \
              '--build[Build images]' \
              '--force-recreate[Recreate containers]' \
              '--no-deps[Skip linked services]' \
              '--no-recreate[Recreate only if image changed]' \
              '--pull[Pull before running]' \
              '--remove-orphans[Remove orphans]' \
              '(-t --timeout)'{-t,--timeout}'[Timeout]:timeout:' \
              '--wait[Wait for healthy]' \
              '*:service:_docker_compose_services'
            ;;
          down)
            _arguments \
              '--rmi[Remove images]:type:(all local)' \
              '(-v --volumes)'{-v,--volumes}'[Remove volumes]' \
              '--remove-orphans[Remove orphans]' \
              '(-t --timeout)'{-t,--timeout}'[Timeout]:timeout:'
            ;;
          logs)
            _arguments \
              '(-f --follow)'{-f,--follow}'[Follow output]' \
              '--tail[Number of lines]:lines:' \
              '(-t --timestamps)'{-t,--timestamps}'[Show timestamps]' \
              '*:service:_docker_compose_services'
            ;;
          exec|run)
            _arguments \
              '(-d --detach)'{-d,--detach}'[Detached mode]' \
              '(-e --env)'{-e,--env}'[Environment]:env:' \
              '(-T --no-TTY)'{-T,--no-TTY}'[Disable pseudo-TTY]' \
              '(-w --workdir)'{-w,--workdir}'[Working directory]:dir:_files -/' \
              '--rm[Remove after run]' \
              '1:service:_docker_compose_services' \
              '*::command:_path_commands'
            ;;
          build)
            _arguments \
              '--build-arg[Build argument]:arg:' \
              '--no-cache[No cache]' \
              '--pull[Always pull]' \
              '--push[Push images]' \
              '*:service:_docker_compose_services'
            ;;
          start|stop|restart|kill|rm|pause|unpause|top)
            _arguments '*:service:_docker_compose_services'
            ;;
        esac
      fi
      ;;
    images)
      _arguments \
        '(-a --all)'{-a,--all}'[Show intermediate]' \
        '--digests[Show digests]' \
        '--filter[Filter]:filter:' \
        '--format[Format]:format:' \
        '--no-trunc[Don'\''t truncate]' \
        '(-q --quiet)'{-q,--quiet}'[Only IDs]' \
        ':repository:'
      ;;
    rmi)
      _arguments \
        '(-f --force)'{-f,--force}'[Force removal]' \
        '--no-prune[Don'\''t delete parents]' \
        '*:image:_docker_complete_images'
      ;;
    pull|push)
      _arguments \
        '(-a --all-tags)'{-a,--all-tags}'[All tags]' \
        '--disable-content-trust[Skip verification]' \
        '--platform[Platform]:platform:' \
        '--quiet[Suppress output]' \
        ':image:_docker_complete_images'
      ;;
    tag)
      _arguments \
        '1:source:_docker_complete_images' \
        '2:target: '
      ;;
    save)
      _arguments \
        '(-o --output)'{-o,--output}'[Output file]:file:_files' \
        '*:image:_docker_complete_images'
      ;;
    load)
      _arguments \
        '(-i --input)'{-i,--input}'[Input file]:file:_files' \
        '--quiet[Suppress output]'
      ;;
    export)
      _arguments \
        '(-o --output)'{-o,--output}'[Output file]:file:_files' \
        ':container:_docker_complete_containers all'
      ;;
    import)
      _arguments \
        '(-c --change)'{-c,--change}'[Apply Dockerfile instruction]:change:' \
        '(-m --message)'{-m,--message}'[Set commit message]:message:' \
        '1:file:_files' \
        '2:repository: '
      ;;
    commit)
      _arguments \
        '(-a --author)'{-a,--author}'[Author]:author:' \
        '(-c --change)'{-c,--change}'[Dockerfile instruction]:change:' \
        '(-m --message)'{-m,--message}'[Commit message]:message:' \
        '(-p --pause)'{-p,--pause}'[Pause during commit]' \
        '1:container:_docker_complete_containers all' \
        '2:repository: '
      ;;
    top)
      _arguments \
        ':container:_docker_complete_containers running' \
        '*:ps_options: '
      ;;
    stats)
      _arguments \
        '(-a --all)'{-a,--all}'[Show all]' \
        '--format[Format]:format:' \
        '--no-stream[Disable streaming]' \
        '--no-trunc[Don'\''t truncate]' \
        '*:container:_docker_complete_containers running'
      ;;
    diff)
      _arguments \
        ':container:_docker_complete_containers all'
      ;;
    port)
      _arguments \
        ':container:_docker_complete_containers all' \
        '::port:'
      ;;
    login)
      _arguments \
        '(-u --username)'{-u,--username}'[Username]:username:_users' \
        '(-p --password)'{-p,--password}'[Password]:password:' \
        '--password-stdin[Read password from stdin]' \
        '--otp[2FA token]:token:' \
        ':server: '
      ;;
    logout)
      _arguments \
        ':server: '
      ;;
    search)
      _arguments \
        '(-f --filter)'{-f,--filter}'[Filter]:filter:' \
        '--format[Format]:format:' \
        '--limit[Max results]:limit:' \
        '--no-trunc[Don'\''t truncate]' \
        ':term: '
      ;;
    system)
      local syscmd=$line[3]
      if (( CURRENT == 3 )); then
        local scommands=(
          'df:Show disk usage'
          'events:Get real-time events'
          'info:Display system info'
          'prune:Remove unused data'
        )
        _describe -t commands "system command" scommands
      else
        case "$syscmd" in
          prune)
            _arguments \
              '(-a --all)'{-a,--all}'[Remove all unused]' \
              '--filter[Filter]:filter:' \
              '(-f --force)'{-f,--force}'[Force]' \
              '--volumes[Prune volumes]'
            ;;
          df)
            _arguments \
              '(-v --verbose)'{-v,--verbose}'[Verbose output]'
            ;;
          events)
            _arguments \
              '(-f --filter)'{-f,--filter}'[Filter]:filter:' \
              '--format[Format]:format:' \
              '--since[Timestamp]:time:' \
              '--until[Timestamp]:time:'
            ;;
        esac
      fi
      ;;
  esac
}

# Helper for cp source completion
_docker_cp_source() {
  local -a containers
  containers=(${(f)"$(_docker_all_containers)"})
  _describe -t containers "container:path or local path" containers
  _files
}

# Helper for cp destination completion  
_docker_cp_dest() {
  local -a containers
  containers=(${(f)"$(_docker_all_containers)"})
  _describe -t containers "container:path or local path" containers
  _files
}

# Register the enhanced completion
compdef _docker_enhanced docker

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `docker`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_docker" ]]; then
  typeset -g -A _comps
  autoload -Uz _docker
  _comps[docker]=_docker
fi

{
  # `docker completion` is only available from 23.0.0 on
  if zstyle -t ':omz:plugins:docker' legacy-completion || \
    ! is-at-least 23.0.0 ${${(s:,:z)"$(command docker --version)"}[3]}; then
      command cp "${0:h}/completions/_docker" "$ZSH_CACHE_DIR/completions/_docker"
    else
      command docker completion zsh | tee "$ZSH_CACHE_DIR/completions/_docker" > /dev/null
  fi
} &|

# ============================================================
# DOCKER UTILITY FUNCTIONS & ADDITIONAL ALIASES
# ============================================================

# caps:category=containers
# caps:desc=List running containers
alias dps='docker ps'

# caps:category=containers
# caps:desc=Run interactive container
alias drit='docker run -it'

# caps:category=images
# caps:desc=Build Docker image
alias dbl='docker build'

# caps:category=compose
# caps:desc=Start compose services
alias dcompup='docker compose up -d'

# caps:category=system
# caps:desc=Clean unused resources
docker-cleanup() {

# Show current context in prompt info
docker_prompt_info() {
  local context=$(_docker_current_context)
  [[ -n "$context" && "$context" != "default" ]] && echo "🐳 $context"
}

# Switch docker context with confirmation
dctx-switch() {
  local ctx="$1"
  [[ -z "$ctx" ]] && { echo "Usage: dctx-switch <context>"; return 1 }
  
  local contexts=($(docker context ls -q 2>/dev/null))
  [[ ! " ${contexts[@]} " =~ " $ctx " ]] && { echo "Context '$ctx' not found. Available: ${contexts[*]}"; return 1 }
  
  echo "Switching from $(docker context show) to $ctx..."
  docker context use "$ctx"
}

# Check docker daemon status
docker-status() {
  if _docker_daemon_check; then
    echo "${fg[green]}✓ Docker daemon is running${reset_color}"
    echo "Context: $(docker context show)"
    echo "Version: $(docker --version)"
    if _docker_is_podman; then
      echo "Backend: Podman (aliased as docker)"
    fi
    return 0
  else
    echo "${fg[red]}✗ Docker daemon is not running${reset_color}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      echo "Start Docker Desktop or run: open -a Docker"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      echo "Try: sudo systemctl start docker"
    fi
    return 1
  fi
}

# Smart docker cleanup
docker-cleanup() {
  echo "Cleaning up Docker resources..."
  
  if ! _docker_daemon_check; then
    echo "Docker daemon not running. Nothing to clean."
    return 1
  fi
  
  # Remove stopped containers
  local stopped=$(docker ps -aq -f status=exited 2>/dev/null | wc -l)
  if [[ $stopped -gt 0 ]]; then
    echo "Removing $stopped stopped containers..."
    docker container prune -f
  fi
  
  # Remove dangling images
  local dangling=$(docker images -q -f dangling=true 2>/dev/null | wc -l)
  if [[ $dangling -gt 0 ]]; then
    echo "Removing $ dangling images..."
    docker image prune -f
  fi
  
  # Remove unused volumes (prompt first)
  local volumes=$(docker volume ls -q -f dangling=true 2>/dev/null | wc -l)
  if [[ $volumes -gt 0 ]]; then
    read -q "REPLY?Remove $volumes unused volumes? [y/N] "
    echo
    [[ "$REPLY" == "y" ]] && docker volume prune -f
  fi
  
  echo "${fg[green]}Cleanup complete${reset_color}"
}

# Get container IP
docker-ip() {
  local container="$1"
  [[ -z "$container" ]] && { echo "Usage: docker-ip <container>"; return 1 }
  
  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container" 2>/dev/null || {
    echo "Container '$container' not found"
    return 1
  }
}

# Get container ports
docker-ports() {
  local container="$1"
  [[ -z "$container" ]] && { echo "Usage: docker-ports <container>"; return 1 }
  
  docker inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{range $conf}}{{$p}} -> {{.HostIp}}:{{.HostPort}}{{println}}{{end}}{{end}}{{end}}' "$container" 2>/dev/null || {
    echo "Container '$container' not found"
    return 1
  }
}

# Show container resource usage
docker-stats-pretty() {
  docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.PIDs}}" "$@"
}

# Follow logs with color coding
docker-logs-color() {
  local container="$1"
  [[ -z "$container" ]] && { echo "Usage: docker-logs-color <container>"; return 1 }
  
  docker logs -f --tail=100 "$container" 2>&1 | while IFS= read -r line; do
    if [[ "$line" == *"ERROR"* ]] || [[ "$line" == *"error"* ]]; then
      echo "${fg[red]}${line}${reset_color}"
    elif [[ "$line" == *"WARN"* ]] || [[ "$line" == *"warning"* ]]; then
      echo "${fg[yellow]}${line}${reset_color}"
    elif [[ "$line" == *"INFO"* ]]; then
      echo "${fg[green]}${line}${reset_color}"
    else
      echo "$line"
    fi
  done
}

# Execute command in container with automatic shell detection
docker-shell() {
  local container="$1"
  [[ -z "$container" ]] && { echo "Usage: docker-shell <container> [shell]"; return 1 }
  
  local shell="${2:-}"
  
  if [[ -z "$shell" ]]; then
    # Try to detect shell
    if docker exec "$container" which bash &>/dev/null; then
      shell="bash"
    elif docker exec "$container" which sh &>/dev/null; then
      shell="sh"
    elif docker exec "$container" which zsh &>/dev/null; then
      shell="zsh"
    else
      echo "No shell found. Specify manually: docker-shell <container> /bin/ash"
      return 1
    fi
  fi
  
  docker exec -it "$container" "$shell"
}

# Copy files with progress
docker-cp-progress() {
  local src="$1"
  local dest="$2"
  [[ -z "$src" || -z "$dest" ]] && { echo "Usage: docker-cp-progress <src> <dest>"; return 1 }
  
  # If source is local, show file size
  if [[ ! "$src" == *":"* ]]; then
    local size=$(du -h "$src" 2>/dev/null | cut -f1)
    echo "Copying $size..."
  fi
  
  docker cp "$src" "$dest"
}

# Build with common options
docker-build-smart() {
  local tag="$1"
  [[ -z "$tag" ]] && { echo "Usage: docker-build-smart <tag> [path]"; return 1 }
  local path="${2:-.}"
  
  local cache_arg=""
  [[ -n "$DOCKER_BUILD_NO_CACHE" ]] && cache_arg="--no-cache"
  
  echo "Building $tag from $path..."
  docker build \
    --tag "$tag" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    $cache_arg \
    "$path"
}

# Run interactive with common options
docker-run-it() {
  local image="$1"
  shift
  [[ -z "$image" ]] && { echo "Usage: docker-run-it <image> [cmd]"; return 1 }
  
  docker run -it --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    "$image" "$@"
}

# Compose with project name from directory
docker-compose-project() {
  local project=$(basename "$(pwd)")
  docker compose -p "$project" "$@"
}

# Validate Dockerfile
dockerfile-lint() {
  local dockerfile="${1:-Dockerfile}"
  [[ -f "$dockerfile" ]] || { echo "Dockerfile not found: $dockerfile"; return 1 }
  
  # Basic syntax check
  docker build --target=INVALID_TARGET_TO_CHECK_SYNTAX_ONLY -f "$dockerfile" . 2>&1 | grep -v "invalid target" && echo "Syntax OK" || echo "Syntax error found"
}
