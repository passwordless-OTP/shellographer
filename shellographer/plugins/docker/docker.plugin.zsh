# shellographer/plugins/docker/docker.plugin.zsh
# Docker CLI aliases and completions

0=${(%):-%N}
local _pdir=${0:A:h}

# Add completions to fpath
fpath+=("$_pdir")

# Guard: Skip if docker not installed
if (( ! $+commands[docker] )); then
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
  "docker-container-list:docker ps:List running containers"
  "docker-container-list-all:docker ps -a:List all containers"
  "docker-container-exec:docker exec -it:Execute command in container"
  "docker-container-logs:docker logs -f:Follow container logs"
  "docker-container-stop:docker stop:Stop container"
  "docker-container-rm:docker rm:Remove container"
  "docker-container-prune:docker container prune:Remove stopped containers"
  "docker-image-list:docker images:List images"
  "docker-image-build:docker build:Build image"
  "docker-image-rm:docker rmi:Remove image"
  "docker-image-prune:docker image prune:Remove unused images"
  "docker-compose-up:docker-compose up -d:Start compose services"
  "docker-compose-down:docker-compose down:Stop compose services"
  "docker-compose-logs:docker-compose logs -f:Follow compose logs"
  "docker-compose-build:docker-compose build:Build compose services"
  "docker-system-prune:docker system prune -f:Clean up unused data"
)

for _entry in $_aliases; do
  local _parts=(${(s/:/)_entry})
  local _name=$_parts[1] _cmd=$_parts[2] _desc=$_parts[3]
  
  if (( $+functions[_shellographer_alias] )); then
    _shellographer_alias "$_name" "$_cmd" "$_desc"
  else
    (( $+functions[$_name] || $+aliases[$_name] )) || alias "$_name=$_cmd"
  fi
done

# Dynamic completions
_docker_complete_containers() {
  local cache_key="docker/containers"
  local cmd="docker ps --format '{{.Names}}' 2>/dev/null"
  
  if (( $+functions[_shellographer_cache] )); then
    _shellographer_cache "$cache_key" 30 "$cmd"
  fi
}

_docker_complete_images() {
  local cache_key="docker/images"
  local cmd="docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null"
  
  if (( $+functions[_shellographer_cache] )); then
    _shellographer_cache "$cache_key" 60 "$cmd"
  fi
}

# Register completions if compinit available
if (( $+functions[compdef] )); then
  compdef '_path_files -/' docker-container-logs 2>/dev/null || true
fi

unset _pdir _helper _aliases _entry _parts _name _cmd _desc
