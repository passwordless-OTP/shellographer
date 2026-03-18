# Enhanced Poetry completions with pyproject.toml script and environment support
# ============================================================================

# Return immediately if poetry is not found
if (( ! $+commands[poetry] )); then
  return
fi

# ============================================================================
# COMPLETION SETUP
# ============================================================================

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `poetry`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_poetry" ]]; then
  typeset -g -A _comps
  autoload -Uz _poetry
  _comps[poetry]=_poetry
fi

poetry completions zsh >| "$ZSH_CACHE_DIR/completions/_poetry" &|

# ============================================================================
# POETRY SCRIPT COMPLETIONS
# ============================================================================

# Complete poetry scripts from pyproject.toml
_poetry_scripts() {
  local pyproject="$PWD/pyproject.toml"
  [[ -f "$pyproject" ]] || return
  
  local -a scripts
  scripts=(${(f)"$(cat "$pyproject" | python3 -c '
import tomllib, sys
try:
    data = tomllib.load(sys.stdin.buffer)
    scripts = data.get("tool", {}).get("poetry", {}).get("scripts", {})
    for name, cmd in scripts.items():
        desc = cmd[:50] + "..." if len(cmd) > 50 else cmd
        print(f"{name}:{desc}")
except:
    pass' 2>/dev/null || python3 -c '
import toml, sys
try:
    data = toml.load(sys.stdin)
    scripts = data.get("tool", {}).get("poetry", {}).get("scripts", {})
    for name, cmd in scripts.items():
        desc = cmd[:50] + "..." if len(cmd) > 50 else cmd
        print(f"{name}:{desc}")
except:
    pass' 2>/dev/null << EOF
$(cat "$pyproject")
EOF
)"})
  
  _describe -t scripts "poetry scripts" scripts
}

# Complete poetry virtual environments
_poetry_envs() {
  local -a envs
  envs=(${(f)"$(poetry env list --full-path 2>/dev/null | sed 's/ (Activated)//')"})
  _describe -t envs "virtual environments" envs
}

# Complete Python versions available
_poetry_python_versions() {
  local -a versions
  versions=($(poetry env list --full-path 2>/dev/null | grep -o 'python[0-9.]*' | sed 's/python//' | sort -u))
  if (( ${#versions} == 0 )); then
    versions=("3.13" "3.12" "3.11" "3.10" "3.9" "3.8" "3.7")
  fi
  _describe -t versions "Python versions" versions
}

# Complete installed packages
_poetry_packages() {
  local -a packages
  packages=(${(f)"$(poetry show 2>/dev/null | awk '{print $1":"$2}')"})
  _describe -t packages "packages" packages
}

# Complete dependency groups
_poetry_groups() {
  local pyproject="$PWD/pyproject.toml"
  local -a groups=("main" "dev")
  
  if [[ -f "$pyproject" ]]; then
    local extra_groups=(${(f)"$(cat "$pyproject" | python3 -c '
import tomllib, sys
try:
    data = tomllib.load(sys.stdin.buffer)
    groups = data.get("tool", {}).get("poetry", {}).get("group", {})
    for name in groups.keys():
        print(name)
except:
    pass' 2>/dev/null || python3 -c '
import toml, sys
try:
    data = toml.load(sys.stdin)
    groups = data.get("tool", {}).get("poetry", {}).get("group", {})
    for name in groups.keys():
        print(name)
except:
    pass' 2>/dev/null << EOF
$(cat "$pyproject")
EOF
)"})
    groups+=($extra_groups)
  fi
  
  _describe -t groups "dependency groups" groups
}

# Complete publish repositories
_poetry_repositories() {
  local -a repos
  repos=(${(f)"$(poetry config repositories 2>/dev/null | grep -o '^[^=]*')"})
  repos+=("pypi")
  _describe -t repos "repositories" repos
}

# Complete poetry config keys
_poetry_config_keys() {
  local -a configs=(
    "cache-dir:Cache directory"
    "experimental.system-git-client:Use system git client"
    "installer.max-workers:Max parallel workers"
    "installer.modern-installation:Use modern installation"
    "installer.no-binary:Don't use binary packages"
    "installer.parallel:Enable parallel installation"
    "repositories.:Repository configuration"
    "virtualenvs.create:Create virtualenv automatically"
    "virtualenvs.in-project:Create virtualenv in project"
    "virtualenvs.options.always-copy:Always copy files"
    "virtualenvs.options.no-pip:Don't install pip"
    "virtualenvs.options.no-setuptools:Don't install setuptools"
    "virtualenvs.options.system-site-packages:Access system packages"
    "virtualenvs.path:Virtualenv path"
    "virtualenvs.prefer-active-python:Prefer active Python"
  )
  _describe -t configs "config keys" configs
}

# ============================================================================
# ENHANCED POETRY COMPLETION FUNCTION
# ============================================================================

_poetry_enhanced() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  # First use the standard poetry completion
  if [[ -f "$ZSH_CACHE_DIR/completions/_poetry" ]]; then
    source "$ZSH_CACHE_DIR/completions/_poetry" 2>/dev/null
  fi
  
  # Add enhanced completions for specific commands
  case "$line[1]" in
    run)
      _poetry_scripts
      ;;
    env)
      case "$line[2]" in
        remove|use|info)
          _poetry_envs
          ;;
      esac
      ;;
    env|python)
      case "$line[2]" in
        use|install)
          _poetry_python_versions
          ;;
      esac
      ;;
    add|remove|show|update|upgrade)
      _poetry_packages
      ;;
    install|sync)
      _poetry_groups
      ;;
    config)
      _poetry_config_keys
      ;;
    publish)
      _poetry_repositories
      ;;
  esac
}

# ============================================================================
# BASIC ALIASES
# ============================================================================

alias pad='poetry add'
alias pbld='poetry build'
alias pch='poetry check'
alias pcmd='poetry list'
alias pconf='poetry config --list'
alias pexp='poetry export --without-hashes > requirements.txt'
alias pin='poetry init'
alias pinst='poetry install'
alias plck='poetry lock'
alias pnew='poetry new'
alias ppath='poetry env info --path'
alias pplug='poetry self show plugins'
alias ppub='poetry publish'
alias prm='poetry remove'
alias prun='poetry run'
alias psad='poetry self add'
alias psh='poetry shell'
alias pshw='poetry show'
alias pslt='poetry show --latest'
alias psup='poetry self update'
alias psync='poetry install --sync'
alias ptree='poetry show --tree'
alias pup='poetry update'
alias pvinf='poetry env info'
alias pvoff='poetry config virtualenvs.create false'
alias pvrm='poetry env remove'
alias pvu='poetry env use'

# ============================================================================
# ENHANCED ALIASES
# ============================================================================

# Quick add with groups
alias pad-dev='poetry add --group dev'
alias pad-test='poetry add --group test'
alias pad-docs='poetry add --group docs'

# Install with specific groups
alias pinst-dev='poetry install --with dev'
alias pinst-all='poetry install --with dev,test,docs'
alias pinst-no-dev='poetry install --without dev'
alias pinst-prod='poetry install --only main'

# Sync commands
alias psync-dev='poetry sync --with dev'
alias psync-all='poetry sync --with dev,test'

# Update commands
alias pup-dev='poetry update --with dev'
alias pup-all='poetry update --with dev,test'
alias pup-pkg='poetry update'

# Lock commands
alias plck-u='poetry lock --update'
alias plck-r='poetry lock --regenerate'

# Run commands
alias prun-py='poetry run python'
alias prun-py3='poetry run python3'
alias prun-pip='poetry run pip'

# Show commands
alias pshw-out='poetry show --outdated'
alias pshw-tree='poetry show --tree'
alias pshw-dep='poetry show --why'

# Build and publish
alias pbld-w='poetry build --wheel'
alias pbld-s='poetry build --sdist'
alias ppub-t='poetry publish --test'

# Environment commands
alias pvls='poetry env list'
alias pvls-f='poetry env list --full-path'
alias pvin='poetry env info'
alias pvrmp='poetry env remove --all'

# Check and lint
alias pchk='poetry check'
alias paudit='poetry audit'

# Export commands
alias pexp-dev='poetry export --with dev --without-hashes'
alias pexp-all='poetry export --with dev,test --without-hashes'
alias pexp-prod='poetry export --without dev --without-hashes'

# Self management
alias psup-plugin='poetry self add'
alias psup-up='poetry self update'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Initialize a new poetry project with common defaults
poetry-init() {
  local name="${1:-$(basename $PWD)}"
  local pyver="${2:-3.11}"
  
  poetry init --name "$name" --python "^$pyver" --no-interaction
  
  # Add common dev dependencies
  poetry add --group dev pytest pytest-cov black isort flake8 mypy --quiet 2>/dev/null || true
  
  echo "Initialized $name with Python $pyver"
  echo "Dev dependencies added: pytest, pytest-cov, black, isort, flake8, mypy"
}

# Activate poetry shell in current directory (for use with direnv)
poetry-activate() {
  if [[ -f "pyproject.toml" ]]; then
    source "$(poetry env info --path)/bin/activate" 2>/dev/null || \\
    source "$(poetry env info --path)/Scripts/activate" 2>/dev/null
  else
    echo "No pyproject.toml found"
    return 1
  fi
}

# Run tests with coverage
poetry-test() {
  poetry run pytest --cov=src --cov-report=term-missing --cov-report=html "$@"
}

# Format code with black and isort
poetry-format() {
  poetry run isort . && poetry run black .
}

# Run all linting checks
poetry-lint() {
  poetry run flake8 . && poetry run mypy . && poetry run black --check .
}

# Update all dependencies and regenerate lock file
poetry-update-all() {
  poetry update && poetry lock --regenerate
}

# Clean up old virtual environments
poetry-clean-envs() {
  local current_env=$(poetry env info --path 2>/dev/null)
  poetry env list --full-path | while read env; do
    env="${env% (Activated)}"
    if [[ "$env" != "$current_env" ]]; then
      echo "Removing: $env"
      rm -rf "$env"
    fi
  done
}

# Export requirements.txt for deployment
poetry-export-reqs() {
  local output="${1:-requirements.txt}"
  poetry export -f requirements.txt --without-hashes --output "$output"
  echo "Exported to $output"
}

# Check for outdated packages in all groups
poetry-outdated() {
  poetry show --outdated --with dev,test 2>/dev/null || poetry show --outdated
}

# Install pre-commit hooks
poetry-setup-precommit() {
  poetry add --group dev pre-commit --quiet 2>/dev/null || true
  poetry run pre-commit install
  
  if [[ ! -f ".pre-commit-config.yaml" ]]; then
    cat > .pre-commit-config.yaml <<'EOF'
repos:
  - repo: https://github.com/psf/black
    rev: 23.x.x
    hooks:
      - id: black
  - repo: https://github.com/PyCQA/isort
    rev: 5.x.x
    hooks:
      - id: isort
  - repo: https://github.com/PyCQA/flake8
    rev: 6.x.x
    hooks:
      - id: flake8
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.x.x
    hooks:
      - id: mypy
EOF
    echo "Created .pre-commit-config.yaml"
  fi
}

# Quick project setup with common structure
poetry-setup-project() {
  local name="${1:-$(basename $PWD)}"
  
  mkdir -p src/$name tests docs
  touch src/$name/__init__.py
  touch tests/__init__.py
  
  poetry-init "$name"
  poetry-setup-precommit
  
  # Create basic pytest config
  cat >> pyproject.toml <<'EOF'

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]

[tool.black]
line-length = 88
target-version = ['py311']

[tool.isort]
profile = "black"

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
EOF

  echo "Project structure created:"
  find . -type f -name "*.py" -o -name "pyproject.toml" | head -10
}
