# Enhanced Just completions with Justfile recipe support
# ============================================================================

(( $+commands[just] )) && {
  
  # ============================================================================
  # JUSTFILE RECIPE COMPLETIONS
  # ============================================================================
  
  # Parse Justfile for recipes
  _just_recipes() {
    local justfile="$1"
    [[ -f "$justfile" ]] || return
    
    local -a recipes
    
    # Use just --summary to get recipe names
    recipes=(${(f)"$(just --justfile "$justfile" --summary 2>/dev/null | tr ' ' '\n')"})
    
    # If that doesn't work, parse manually
    if (( ${#recipes} == 0 )); then
      # Match recipe definitions (lines starting with recipe name followed by ':')
      # Skip lines that start with whitespace, #, or are variable assignments
      recipes=(${(f)"$(grep -E '^[a-zA-Z0-9_-]+[ a-zA-Z0-9_-]*:' "$justfile" 2>/dev/null | 
        grep -v '^[A-Z_]*:=' | 
        grep -v '^[A-Z_]*=' | 
        sed 's/:.*$//' | 
        sed 's/ .*$//' |
        sort -u | 
        head -100)"})
    fi
    
    # Look for documented recipes (with # comments above)
    local documented=(${(f)"$(awk '
      /^# / { doc = substr($0, 3) }
      /^[a-zA-Z0-9_-]+:/ { 
        if (doc) {
          gsub(/:.*/, "", $1)
          print $1 ":" doc
          doc = ""
        }
      }
      !/^# / && !/^[a-zA-Z0-9_-]+:/ { doc = "" }
    ' "$justfile" 2>/dev/null)"})
    
    if (( ${#documented} > 0 )); then
      _describe -t documented "documented recipes" documented
    else
      _describe -t recipes "recipes" recipes
    fi
  }
  
  # Complete just variables
  _just_variables() {
    local justfile="$1"
    [[ -f "$justfile" ]] || return
    
    local -a vars
    # Match variable assignments like VAR := value or VAR = value or VAR ?= value
    vars=(${(f)"$(grep -E '^export +[a-zA-Z_]+[?]?=' "$justfile" 2>/dev/null | 
      sed 's/^export //;s/[?]?=.*$//' | 
      head -50)"})
    
    vars+=(${(f)"$(grep -E '^[a-zA-Z_]+[?]?=' "$justfile" 2>/dev/null | 
      sed 's/[?]?=.*$//' | 
      head -50)"})
    
    _describe -t vars "variables" vars
  }
  
  # Find the Justfile
  _just_find_justfile() {
    local -a justfiles=("justfile" "Justfile" ".justfile")
    
    # Check for specific justfile
    if [[ -n "$opt_args[-f]" ]]; then
      echo "$opt_args[-f]"
      return
    fi
    
    # Check JUST_JUSTFILE environment variable
    if [[ -n "$JUST_JUSTFILE" && -f "$JUST_JUSTFILE" ]]; then
      echo "$JUST_JUSTFILE"
      return
    fi
    
    # Look in current directory
    for jf in $justfiles; do
      if [[ -f "$jf" ]]; then
        echo "$jf"
        return
      fi
    done
    
    # Look in parent directories
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
      for jf in $justfiles; do
        if [[ -f "$dir/$jf" ]]; then
          echo "$dir/$jf"
          return
        fi
      done
      dir=$(dirname "$dir")
    done
  }
  
  # Complete justfiles
  _just_justfiles() {
    _files -g 'justfile' -g 'Justfile' -g '.justfile' -g '*.just'
  }
  
  # Main just completion function
  _just_completion() {
    local curcontext="$curcontext" state line
    typeset -A opt_args
    
    _arguments -C \
      '(-h --help)'{-h,--help}'[Display help]' \
      '(-V --version)'{-V,--version}'[Display version]' \
      '(-f --justfile)'{-f,--justfile}'[Use specific justfile]:justfile:_just_justfiles' \
      '(-d --working-directory)'{-d,--working-directory}'[Use specific working directory]:directory:_files -/' \
      '(-c --command)'{-c,--command}'[Evaluate command]:command:' \
      '--completions[Print shell completion script]:shell:(bash zsh fish powershell elvish)' \
      '--dump[Print justfile]' \
      '(-e --edit)'{-e,--edit}'[Open justfile in editor]' \
      '--evaluate[Evaluate variables]' \
      '--fmt[Format justfile]' \
      '--highlight[Highlight echoed recipe lines]' \
      '--init[Initialize new justfile]' \
      '(-l --list)'{-l,--list}'[List available recipes]' \
      '--no-deps[Don\\'t run recipe dependencies]' \
      '--no-dotenv[Don\\'t load .env file]' \
      '--no-highlight[Don\\'t highlight echoed recipe lines]' \
      '-n[Print what just would do without doing it]' \
      '--dry-run[Print what just would do without doing it]' \
      '(-q --quiet)'{-q,--quiet}'[Suppress all output]' \
      '--shell[Use specific shell]:shell:_command_names' \
      '--shell-arg[Use specific shell argument]:arg:' \
      '--show[Show recipe]:recipe:' \
      '--summary[Display list of recipes]' \
      '--unstable[Enable unstable features]' \
      '--variables[List variables]' \
      '--yes[Confirm all recipes]' \
      '(-v --verbose)'{-v,--verbose}'[Use verbose output]' \
      '*--set[Override variable]:variable:_just_variables:value:' \
      '*: :->args'
    
    case "$state" in
      args)
        local justfile=$(_just_find_justfile)
        if [[ -n "$justfile" ]]; then
          _just_recipes "$justfile"
          _just_variables "$justfile"
        else
          _files
        fi
        ;;
    esac
  }
  
  compdef _just_completion just
  
  # ============================================================================
  # JUST ALIASES
  # ============================================================================
  
  # Basic commands
  alias j='just'
  alias jl='just --list'
  alias js='just --summary'
  alias jh='just --help'
  alias jv='just --version'
  alias je='just --edit'
  alias jd='just --dump'
  alias jf='just --fmt'
  alias ji='just --init'
  
  # Verbose and dry-run
  alias jv='just --verbose'
  alias jn='just --dry-run'
  alias jq='just --quiet'
  
  # Common recipe names (if they exist)
  alias jb='just build'
  alias jt='just test'
  alias jc='just clean'
  alias jcb='just clean && just build'
  alias jct='just clean && just test'
  alias jcr='just clean && just run'
  alias jcl='just clean'
  alias jcln='just clean'
  alias jf='just format'
  alias jfmt='just format'
  alias jdoc='just doc'
  alias jdocs='just docs'
  alias jlint='just lint'
  alias jcheck='just check'
  alias jci='just ci'
  alias jdev='just dev'
  alias jrun='just run'
  alias jstart='just start'
  alias jstop='just stop'
  alias jdeploy='just deploy'
  alias jinstall='just install'
  alias jsetup='just setup'
  alias jupdate='just update'
  alias jup='just update'
  alias jwatch='just watch'
  
  # ============================================================================
  # UTILITY FUNCTIONS
  # ============================================================================
  
  # List all just recipes
  just-list() {
    local justfile="${1:-$(_just_find_justfile)}"
    [[ -z "$justfile" ]] && { echo "No justfile found"; return 1 }
    
    echo "=== Recipes in $justfile ==="
    just --justfile "$justfile" --list 2>/dev/null || 
      grep -E '^[a-zA-Z0-9_-]+[ a-zA-Z0-9_-]*:' "$justfile" | 
        sed 's/:.*$//' | 
        sed 's/ .*$//' |
        sort -u | 
        nl
  }
  
  # Show help for just recipes
  just-help() {
    local justfile="${1:-$(_just_find_justfile)}"
    [[ -z "$justfile" ]] && { echo "No justfile found"; return 1 }
    
    echo "=== Available recipes ==="
    just --justfile "$justfile" --list 2>/dev/null || just-list "$justfile"
  }
  
  # Edit the justfile
  just-edit() {
    local justfile="${1:-$(_just_find_justfile)}"
    [[ -z "$justfile" ]] && { echo "No justfile found"; return 1 }
    
    ${EDITOR:-vi} "$justfile"
  }
  
  # Show recipe source
  just-show() {
    local recipe="$1"
    [[ -z "$recipe" ]] && { echo "Usage: just-show <recipe>"; return 1 }
    
    just --show "$recipe"
  }
  
  # Watch justfile and re-run recipe on changes
  just-watch() {
    local recipe="${1:-default}"
    local justfile="$(_just_find_justfile)"
    
    if (( $+commands[watchexec] )); then
      watchexec -e just just "$recipe"
    elif (( $+commands[entr] )); then
      echo "$justfile" | entr -c just "$recipe"
    else
      echo "Install watchexec (cargo install watchexec-cli) or entr (brew install entr)"
      return 1
    fi
  }
  
  # Create a basic justfile
  just-init() {
    local project="${1:-$(basename $PWD)}"
    local lang="${2:-generic}"
    
    [[ -f "justfile" ]] && { echo "justfile already exists"; return 1 }
    
    case "$lang" in
      rust|cargo)
        cat > justfile <<'EOF'
# Default recipe to run
default: check

# Build the project
build:
    cargo build

# Build for release
release:
    cargo build --release

# Run the project
run:
    cargo run

# Run tests
test:
    cargo test

# Run clippy
clippy:
    cargo clippy --all-features -- -D warnings

# Format code
format:
    cargo fmt

# Run all checks
check: format clippy test

# Clean build artifacts
clean:
    cargo clean

# Watch for changes and run tests
watch:
    cargo watch -x test
EOF
        ;;
      
      python|py|uv)
        cat > justfile <<'EOF'
# Default recipe to run
default: check

# Install dependencies
install:
    uv sync

# Run the application
run:
    uv run python -m src

# Run tests
test:
    uv run pytest

# Run tests with coverage
test-cov:
    uv run pytest --cov=src --cov-report=term-missing

# Format code
format:
    uv run ruff format .

# Lint code
lint:
    uv run ruff check .

# Type check
typecheck:
    uv run mypy .

# Run all checks
check: format lint typecheck test

# Update dependencies
update:
    uv lock --upgrade
    uv sync

# Clean cache
clean:
    rm -rf .pytest_cache .mypy_cache .ruff_cache
    find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
EOF
        ;;
      
      node|js|npm|pnpm)
        cat > justfile <<'EOF'
# Default recipe to run
default: check

# Install dependencies
install:
    pnpm install

# Run the application
dev:
    pnpm dev

# Build the project
build:
    pnpm build

# Run tests
test:
    pnpm test

# Run tests with coverage
test-cov:
    pnpm test --coverage

# Format code
format:
    pnpm format

# Lint code
lint:
    pnpm lint

# Run all checks
check: format lint test

# Update dependencies
update:
    pnpm update

# Clean build artifacts
clean:
    rm -rf dist build node_modules/.cache
EOF
        ;;
      
      go|golang)
        cat > justfile <<'EOF'
# Default recipe to run
default: check

# Build the project
build:
    go build -o bin/app .

# Run the application
run:
    go run .

# Run tests
test:
    go test ./...

# Run tests with coverage
test-cov:
    go test -cover ./...

# Format code
format:
    go fmt ./...

# Vet code
vet:
    go vet ./...

# Run linter (requires golangci-lint)
lint:
    golangci-lint run

# Run all checks
check: format vet test

# Update dependencies
update:
    go get -u ./...
    go mod tidy

# Clean build artifacts
clean:
    rm -rf bin/
    go clean

# Download dependencies
deps:
    go mod download
EOF
        ;;
      
      *)
        cat > justfile <<'EOF'
# Default recipe - shows available recipes
default:
    @just --list

# Example build recipe
build:
    @echo "Building project..."
    # Add your build commands here

# Example test recipe  
test:
    @echo "Running tests..."
    # Add your test commands here

# Example clean recipe
clean:
    @echo "Cleaning..."
    # Add your clean commands here

# Example format recipe
format:
    @echo "Formatting..."
    # Add your format commands here

# Example check recipe
check: format test
    @echo "All checks passed!"
EOF
        ;;
    esac
    
    echo "Created justfile for $project ($lang)"
    echo "Run 'just --list' to see available recipes"
  }
  
  # Create a justfile with common dev recipes
  just-dev-init() {
    cat > justfile <<'EOF'
# List available recipes
default:
    @just --list --unsorted

# Setup development environment
setup:
    @echo "Setting up development environment..."
    # Add setup commands here

# Install dependencies  
install:
    @echo "Installing dependencies..."
    # Add install commands here

# Run development server
dev:
    @echo "Starting development server..."
    # Add dev server command here

# Run the application
run:
    @echo "Running application..."
    # Add run command here

# Run tests
test:
    @echo "Running tests..."
    # Add test command here

# Build for production
build:
    @echo "Building for production..."
    # Add build command here

# Format code
format:
    @echo "Formatting code..."
    # Add format command here

# Lint code
lint:
    @echo "Linting code..."
    # Add lint command here

# Run all checks
check: format lint test
    @echo "All checks passed!"

# Clean build artifacts
clean:
    @echo "Cleaning build artifacts..."
    # Add clean commands here

# Full clean (including dependencies)
clean-all: clean
    @echo "Cleaning everything..."
    # Add full clean commands here

# Deploy application
deploy: build
    @echo "Deploying application..."
    # Add deploy commands here

# Watch for changes and re-run
dev-watch:
    @echo "Watching for changes..."
    # Add watch command here

# Run CI pipeline locally
ci: check
    @echo "Running CI pipeline..."
    # Add CI commands here

# Show help for a specific recipe
help recipe:
    @just --show {{recipe}}
EOF

    echo "Created justfile with common development recipes"
    echo "Run 'just --list' to see available recipes"
  }
}
