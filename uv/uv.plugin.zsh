# Enhanced uv completions with Python version and tool support
# ============================================================================

# Return immediately if uv is not found
if (( ! $+commands[uv] )); then
  return
fi

# ============================================================================
# COMPLETION SETUP
# ============================================================================

# If the completion file doesn't exist yet, we need to autoload it and
# bind it. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_uv" ]]; then
  typeset -g -A _comps
  autoload -Uz _uv
  _comps[uv]=_uv
fi

if [[ ! -f "$ZSH_CACHE_DIR/completions/_uvx" ]]; then
  typeset -g -A _comps
  autoload -Uz _uvx
  _comps[uvx]=_uvx
fi

# uv and uvx are installed together (uvx is an alias to `uv tool run`)  
# Overwrites the file each time as completions might change with uv versions.
uv generate-shell-completion zsh >| "$ZSH_CACHE_DIR/completions/_uv" &|
uvx --generate-shell-completion zsh >| "$ZSH_CACHE_DIR/completions/_uvx" &|

# ============================================================================
# UV SCRIPT COMPLETIONS
# ============================================================================

# Complete uv scripts from pyproject.toml
_uv_scripts() {
  local pyproject="$PWD/pyproject.toml"
  [[ -f "$pyproject" ]] || return
  
  local -a scripts
  scripts=(${(f)"$(cat "$pyproject" | python3 -c '
import tomllib, sys
try:
    data = tomllib.load(sys.stdin.buffer)
    scripts = data.get("project", {}).get("scripts", {})
    for name, cmd in scripts.items():
        desc = cmd[:50] + "..." if len(cmd) > 50 else cmd
        print(f"{name}:{desc}")
except:
    pass' 2>/dev/null || python3 -c '
import toml, sys
try:
    data = toml.load(sys.stdin)
    scripts = data.get("project", {}).get("scripts", {})
    for name, cmd in scripts.items():
        desc = cmd[:50] + "..." if len(cmd) > 50 else cmd
        print(f"{name}:{desc}")
except:
    pass' 2>/dev/null << EOF
$(cat "$pyproject")
EOF
)"})
  
  _describe -t scripts "project scripts" scripts
}

# Complete Python versions available via uv
_uv_python_versions() {
  local cache="$ZSH_CACHE_DIR/uv_python_versions"
  if [[ ! -f "$cache" || -n "$cache"(#qNm+1440) ]]; then
    uv python list --only-installed 2>/dev/null | awk '{print $1}' | sort -u >| "$cache" &|
  fi
  
  local -a versions
  versions=($(cat "$cache" 2>/dev/null))
  
  # Fallback to common versions
  if (( ${#versions} == 0 )); then
    versions=("3.13" "3.12" "3.11" "3.10" "3.9" "3.8")
  fi
  
  _describe -t versions "Python versions" versions
}

# Complete available Python versions for installation
_uv_python_available() {
  local cache="$ZSH_CACHE_DIR/uv_python_available"
  if [[ ! -f "$cache" || -n "$cache"(#qNm+1440) ]]; then
    uv python list 2>/dev/null | grep -v "->" | awk '{print $1}' | sort -u >| "$cache" &|
  fi
  
  local -a versions
  versions=($(cat "$cache" 2>/dev/null))
  
  # Fallback
  if (( ${#versions} == 0 )); then
    versions=("3.13.0" "3.12.0" "3.11.0" "3.10.0" "3.9.0" "pypy3.10" "pypy3.9")
  fi
  
  _describe -t versions "available Python versions" versions
}

# Complete installed uv tools
_uv_tools() {
  local cache="$ZSH_CACHE_DIR/uv_tools"
  if [[ ! -f "$cache" || -n "$cache"(#qNm+60) ]]; then
    uv tool list 2>/dev/null | grep -v '^-' | awk '{print $1}' >| "$cache" &|
  fi
  
  local -a tools
  tools=($(cat "$cache" 2>/dev/null))
  
  # Add common tools as suggestions
  tools+=(
    "black:Python code formatter"
    "ruff:Python linter and formatter"
    "mypy:Static type checker"
    "isort:Import sorter"
    "pytest:Testing framework"
    "tox:Test automation"
    "pre-commit:Git hooks framework"
    "cookiecutter:Project template tool"
    "poetry:Dependency management"
    "pipenv:Virtualenv management"
    "httpie:HTTP client"
    "pgcli:PostgreSQL CLI"
    "litecli:SQLite CLI"
    "jupyterlab:Jupyter environment"
    "ipython:Enhanced Python REPL"
    "bandit:Security linter"
    "pydocstyle:Docstring conventions"
    "pyupgrade:Python upgrade checker"
    "autoflake:Remove unused imports"
    "pyupgrade:Upgrade Python code"
    "pdm:Python package manager"
    "hatch:Modern Python project manager"
  )
  
  _describe -t tools "uv tools" tools
}

# Complete installed packages
_uv_packages() {
  local -a packages
  
  # From pyproject.toml
  local pyproject="$PWD/pyproject.toml"
  if [[ -f "$pyproject" ]]; then
    packages+=(${(f)"$(cat "$pyproject" | python3 -c '
import tomllib, sys
try:
    data = tomllib.load(sys.stdin.buffer)
    # Try PEP 621 format first
    for dep in data.get("project", {}).get("dependencies", []):
        print(dep.split("[")[0].split("=")[0].split(">")[0].split("<")[0].strip())
    # Then try uv-specific format
    for dep in data.get("tool", {}).get("uv", {}).get("dependencies", []):
        print(dep.split("[")[0].split("=")[0].split(">")[0].split("<")[0].strip())
except:
    pass' 2>/dev/null || python3 -c '
import toml, sys
try:
    data = toml.load(sys.stdin)
    for dep in data.get("project", {}).get("dependencies", []):
        print(dep.split("[")[0].split("=")[0].split(">")[0].split("<")[0].strip())
except:
    pass' 2>/dev/null << EOF
$(cat "$pyproject")
EOF
)"})
  fi
  
  # From uv.lock or requirements files
  if [[ -f "uv.lock" ]]; then
    packages+=($(grep -o '^name = "[^"]*"' uv.lock 2>/dev/null | head -50 | sed 's/name = "//;s/"$//' | sort -u))
  fi
  
  _describe -t packages "packages" packages
}

# Complete uvx/uv tool run packages
_uvx_packages() {
  _uv_tools
}

# Complete virtual environments
_uv_venvs() {
  local -a venvs
  
  # Check common locations
  for dir in "$PWD/.venv" "$PWD/venv" "$PWD/env" "$HOME/.venv" "$WORKON_HOME"/*; do
    [[ -d "$dir" ]] && venvs+=("$dir")
  done
  
  # From uv's cache
  local uv_cache="${UV_CACHE_DIR:-$HOME/.cache/uv}"
  if [[ -d "$uv_cache/environments" ]]; then
    venvs+=($(ls -1 "$uv_cache/environments" 2>/dev/null | head -20))
  fi
  
  _describe -t venvs "virtual environments" venvs
}

# Complete uv pip options
_uv_pip_options() {
  local -a options=(
    "install:Install packages"
    "uninstall:Uninstall packages"
    "freeze:List installed packages"
    "list:List installed packages"
    "show:Show package info"
    "tree:Show dependency tree"
    "check:Verify environment"
    "compile:Compile requirements"
    "sync:Sync environment"
  )
  _describe -t options "pip commands" options
}

# Complete requirement files
_uv_requirement_files() {
  local -a files
  files=($(ls -1 *requirements*.txt 2>/dev/null) $(ls -1 pyproject.toml 2>/dev/null))
  _describe -t files "requirement files" files
}

# ============================================================================
# ENHANCED UV COMPLETION FUNCTION
# ============================================================================

_uv_enhanced() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  # First use the standard uv completion if available
  if [[ -f "$ZSH_CACHE_DIR/completions/_uv" ]]; then
    source "$ZSH_CACHE_DIR/completions/_uv" 2>/dev/null && return
  fi
  
  # Fallback completion
  local -a uv_cmds=(
    "add:Add Python packages"
    "build:Build Python packages"
    "init:Initialize project"
    "install:Install project"
    "lock:Lock dependencies"
    "python:Manage Python versions"
    "pip:Python package management"
    "remove:Remove packages"
    "run:Run commands"
    "sync:Sync environment"
    "tool:Manage tools"
    "tree:View dependency tree"
    "venv:Create virtual environment"
    "version:Show version"
    "workspace:Manage workspaces"
  )
  
  _arguments -C \
    '(-h --help)'{-h,--help}'[Show help]' \
    '(-V --version)'{-V,--version}'[Show version]' \
    '1: :->command' \
    '*:: :->args'
  
  case "$state" in
    command)
      _describe -t commands "uv commands" uv_cmds
      ;;
    args)
      case "$line[1]" in
        run)
          _uv_scripts
          ;;
        add|remove|upgrade)
          _uv_packages
          ;;
        python)
          local -a py_cmds=("install:Install Python" "list:List versions" "find:Find Python" "pin:Pin version")
          _describe -t py_cmds "python commands" py_cmds
          _uv_python_versions
          ;;
        pip)
          _uv_pip_options
          _uv_packages
          ;;
        venv|virtualenv)
          _uv_python_versions
          ;;
        tool)
          local -a tool_cmds=("install:Install tool" "uninstall:Uninstall tool" "list:List tools" "upgrade:Upgrade tool" "run:Run tool")
          _describe -t tool_cmds "tool commands" tool_cmds
          _uv_tools
          ;;
        init)
          _uv_python_versions
          ;;
        sync|install)
          _uv_requirement_files
          ;;
      esac
      ;;
  esac
}

_uvx_enhanced() {
  _uv_tools
}

# ============================================================================
# BASIC ALIASES
# ============================================================================

alias uv="noglob uv"

alias uva='uv add'
alias uvexp='uv export --format requirements-txt --no-hashes --output-file requirements.txt --quiet'
alias uvi='uv init'
alias uvinw='uv init --no-workspace'
alias uvl='uv lock'
alias uvlr='uv lock --refresh'
alias uvlu='uv lock --upgrade'
alias uvp='uv pip'
alias uvpi='uv python install'
alias uvpl='uv python list'
alias uvpu='uv python uninstall'
alias uvpy='uv python'
alias uvpp='uv python pin'
alias uvr='uv run'
alias uvrm='uv remove'
alias uvs='uv sync'
alias uvsr='uv sync --refresh'
alias uvsu='uv sync --upgrade'
alias uvtr='uv tree'
alias uvup='uv self update'
alias uvv='uv venv'

# ============================================================================
# ENHANCED ALIASES
# ============================================================================

# uv run variations
alias uvr-py='uv run python'
alias uvr-py3='uv run python3'
alias uvr-pip='uv run pip'

# uv add variations
alias uva-dev='uv add --dev'
alias uva-optional='uv add --optional'
alias uva-extras='uv add --extra'

# uv pip variations
alias uvp-i='uv pip install'
alias uvp-u='uv pip uninstall'
alias uvp-f='uv pip freeze'
alias uvp-l='uv pip list'
alias uvp-s='uv pip show'
alias uvp-t='uv pip tree'
alias uvp-c='uv pip check'

# Sync variations
alias uvs-dev='uv sync --dev'
alias uvs-no-dev='uv sync --no-dev'
alias uvs-all='uv sync --all-extras'

# Tool variations
alias uvt='uv tool'
alias uvt-i='uv tool install'
alias uvt-u='uv tool uninstall'
alias uvt-l='uv tool list'
alias uvt-up='uv tool upgrade'
alias uvt-ul='uv tool upgrade --all'

# Python management
alias uvpy-l='uv python list'
alias uvpy-i='uv python install'
alias uvpy-u='uv python uninstall'
alias uvpy-f='uv python find'
alias uvpy-p='uv python pin'

# Build and publish
alias uvb='uv build'
alias uvb-w='uv build --wheel'
alias uvb-s='uv build --sdist'
alias uvpub='uv publish'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Quick uv init with common settings
uv-init() {
  local name="${1:-$(basename $PWD)}"
  local pyver="${2:-3.11}"
  
  uv init --name "$name" --python "$pyver" "$@"
  
  # Add common dev dependencies
  uv add --dev pytest ruff mypy --quiet 2>/dev/null || true
  
  echo "Initialized $name with Python $pyver"
  echo "Dev dependencies: pytest, ruff, mypy"
}

# Setup a new project with uv
uv-setup() {
  local name="${1:-$(basename $PWD)}"
  
  mkdir -p src/$name tests
  touch src/$name/__init__.py
  touch tests/__init__.py
  
  uv-init "$name"
  
  # Add basic config to pyproject.toml
  cat >> pyproject.toml <<'EOF'

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I"]

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
EOF

  echo "Project structure created"
}

# Run tests with uv
uv-test() {
  uv run pytest --cov=src --cov-report=term-missing "$@"
}

# Format code with ruff
uv-format() {
  uv run ruff format . && uv run ruff check --fix .
}

# Check code with ruff and mypy
uv-check() {
  uv run ruff check . && uv run mypy .
}

# Install common development tools
uv-dev-tools() {
  local tools=(black ruff mypy pytest pre-commit ipython)
  for tool in $tools; do
    echo "Installing $tool..."
    uv tool install "$tool" 2>/dev/null || uv tool upgrade "$tool"
  done
}

# Update all uv-managed tools
uv-tool-update-all() {
  uv tool list | grep -v '^-' | awk '{print $1}' | while read tool; do
    echo "Updating $tool..."
    uv tool upgrade "$tool"
  done
}

# Clean uv cache
uv-clean() {
  echo "Cleaning uv cache..."
  uv cache clean
  echo "Cache cleaned"
}

# Show uv info
uv-info() {
  echo "=== UV Version ==="
  uv --version
  echo ""
  echo "=== Python Versions ==="
  uv python list
  echo ""
  echo "=== Installed Tools ==="
  uv tool list
  echo ""
  echo "=== Cache Info ==="
  uv cache dir 2>/dev/null || echo "Cache dir: ${UV_CACHE_DIR:-~/.cache/uv}"
}

# Create venv with specific Python version
uv-mkvenv() {
  local pyver="${1:-3.11}"
  local name="${2:-.venv}"
  uv venv --python "$pyver" "$name"
  echo "Created $name with Python $pyver"
}

# Export requirements for deployment
uv-export-reqs() {
  local output="${1:-requirements.txt}"
  uv export --no-hashes --output-file "$output"
  echo "Exported to $output"
}

# Quick upgrade all dependencies
uv-upgrade-all() {
  uv lock --upgrade
  uv sync
}

# Run a tool with uvx (shortcut)
uvx-run() {
  local tool="$1"
  shift
  uvx "$tool" "$@"
}
