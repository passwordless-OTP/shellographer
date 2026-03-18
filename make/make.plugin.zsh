# Enhanced Make completions with Makefile target support
# ============================================================================

(( $+commands[make] )) && {
  
  # ============================================================================
  # MAKEFILE TARGET COMPLETIONS
  # ============================================================================
  
  # Parse Makefile for targets
  _make_targets() {
    local makefile="$1"
    [[ -f "$makefile" ]] || return
    
    local -a targets
    
    # Extract targets from Makefile
    # Match lines like "target:" or "target: dependencies" but not variable assignments
    targets=(${(f)"$(grep -E '^[a-zA-Z0-9_-]+:.*$' "$makefile" 2>/dev/null | 
      grep -v '^[A-Z_]*=' | 
      sed 's/:.*$//' | 
      sort -u | 
      head -100)"})
    
    # Also look for .PHONY targets which are more reliable
    local phony_targets=$(grep -A20 '^\.PHONY:' "$makefile" 2>/dev/null | head -1 | sed 's/\.PHONY://')
    if [[ -n "$phony_targets" ]]; then
      for t in ${(z)phony_targets}; do
        [[ -n "$t" ]] && targets+=("$t")
      done
    fi
    
    # Look for documented targets (with ## comments)
    local documented=(${(f)"$(grep -E '^[a-zA-Z0-9_-]+:.*## ' "$makefile" 2>/dev/null | 
      sed 's/:\{1,2\}.*## /:/' | 
      head -50)"})
    
    # Combine and remove duplicates
    targets=(${(u)targets})
    
    if (( ${#documented} > 0 )); then
      _describe -t documented "documented targets" documented
    else
      _describe -t targets "targets" targets
    fi
  }
  
  # Complete make variables
  _make_variables() {
    local makefile="$1"
    [[ -f "$makefile" ]] || return
    
    local -a vars
    vars=(${(f)"$(grep -E '^[A-Z_]+[?]?=' "$makefile" 2>/dev/null | 
      sed 's/[?]?=.*$//' | 
      head -50)"})
    
    # Add common make variables
    vars+=(
      "CC:C compiler"
      "CXX:C++ compiler"
      "CFLAGS:C compiler flags"
      "CXXFLAGS:C++ compiler flags"
      "LDFLAGS:Linker flags"
      "LDLIBS:Libraries to link"
      "CPPFLAGS:C preprocessor flags"
      "DESTDIR:Destination directory"
      "PREFIX:Installation prefix"
      "BINDIR:Binary directory"
      "LIBDIR:Library directory"
      "DATADIR:Data directory"
      "MANDIR:Man page directory"
      "V:Verbose flag (V=1)"
      "DEBUG:Debug flag (DEBUG=1)"
    )
    
    _describe -t vars "variables" vars
  }
  
  # Find the Makefile
  _make_find_makefile() {
    local -a makefiles=("GNUmakefile" "makefile" "Makefile")
    
    # Check for specific makefile
    if [[ -n "$opt_args[-f]" ]]; then
      echo "$opt_args[-f]"
      return
    fi
    
    # Check for MAKEFILE environment variable
    if [[ -n "$MAKEFILE" && -f "$MAKEFILE" ]]; then
      echo "$MAKEFILE"
      return
    fi
    
    # Look in current directory
    for mf in $makefiles; do
      if [[ -f "$mf" ]]; then
        echo "$mf"
        return
      fi
    done
    
    # Look in parent directories
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
      for mf in $makefiles; do
        if [[ -f "$dir/$mf" ]]; then
          echo "$dir/$mf"
          return
        fi
      done
      dir=$(dirname "$dir")
    done
  }
  
  # Complete include directories
  _make_includes() {
    _files -/ -g '*.mk' -g 'Makefile*'
  }
  
  # Complete makefiles
  _make_makefiles() {
    _files -g 'Makefile*' -g '*.mk' -g 'makefile*' -g 'GNUmakefile'
  }
  
  # Main make completion function
  _make_completion() {
    local curcontext="$curcontext" state line
    typeset -A opt_args
    
    _arguments -C \
      '(-h --help)'{-h,--help}'[Display help]' \
      '(-v --version)'{-v,--version}'[Display version]' \
      '(-n --just-print --dry-run --recon)'{-n,--just-print,--dry-run,--recon}'[Print commands without executing]' \
      '(-t --touch)'{-t,--touch}'[Touch targets instead of remaking]' \
      '(-q --question)'{-q,--question}'[Run no recipe unless target needs update]' \
      '(-W --what-if --new-file --assume-new)'{-W,--what-if,--new-file,--assume-new}'[Consider file as infinitely new]:file:_files' \
      '(-B --always-make)'{-B,--always-make}'[Unconditionally make all targets]' \
      '(-C --directory)'{-C,--directory}'[Change to directory before reading makefiles]:directory:_files -/' \
      '(-f --file --makefile)'{-f,--file,--makefile}'[Read file as makefile]:makefile:_make_makefiles' \
      '(-I --include-dir)'{-I,--include-dir}'[Search directory for included makefiles]:directory:_files -/' \
      '(-j --jobs)'{-j,--jobs}'[Allow N parallel jobs]:jobs:' \
      '(-l --load-average)'{-l,--load-average}'[Don\\'t start multiple jobs unless load is below N]:load:' \
      '(-e --environment-overrides)'{-e,--environment-overrides}'[Environment variables override makefiles]' \
      '(-k --keep-going)'{-k,--keep-going}'[Keep going when some targets can\\'t be made]' \
      '(-s --silent --quiet)'{-s,--silent,--quiet}'[Don\\'t echo recipes]' \
      '(-S --no-keep-going --stop)'{-S,--no-keep-going,--stop}'[Turns off -k]' \
      '(-r --no-builtin-rules)'{-r,--no-builtin-rules}'[Disable built-in rules]' \
      '(-R --no-builtin-variables)'{-R,--no-builtin-variables}'[Disable built-in variables]' \
      '--debug[Print debugging info]' \
      '--output-sync[Synchronize output]:type:(none line target recurse)' \
      '*-D[Define variable]:variable:_make_variables' \
      '*: :->args'
    
    case "$state" in
      args)
        local makefile=$(_make_find_makefile)
        if [[ -n "$makefile" ]]; then
          _make_targets "$makefile"
          _make_variables "$makefile"
        else
          _files
        fi
        ;;
    esac
  }
  
  compdef _make_completion make
  
  # Also complete gmake if it exists
  (( $+commands[gmake] )) && compdef _make_completion gmake
  
  # ============================================================================
  # MAKE ALIASES
  # ============================================================================
  
  # Common make commands
  alias m='make'
  alias mb='make build'
  alias mc='make clean'
  alias md='make dist'
  alias mi='make install'
  alias mt='make test'
  alias mr='make run'
  alias mf='make format'
  alias ml='make lint'
  alias mp='make package'
  alias mu='make update'
  alias mdoc='make doc'
  alias mdocs='make docs'
  
  # Parallel builds
  alias mj='make -j'
  alias mj4='make -j4'
  alias mj8='make -j8'
  alias mj16='make -j16'
  
  # Dry run
  alias mn='make -n'
  alias mdr='make --dry-run'
  
  # Silent
  alias ms='make -s'
  alias mq='make -q'
  
  # Debug
  alias mdbg='make --debug'
  alias mdbgv='make --debug=v'
  
  # Clean builds
  alias mcb='make clean && make build'
  alias mcr='make clean && make run'
  alias mct='make clean && make test'
  
  # Verbose
  alias mv='make V=1'
  alias mvb='make V=1 build'
  alias mvt='make V=1 test'
  
  # Common targets (if they exist)
  alias mall='make all'
  alias mcheck='make check'
  alias mdev='make dev'
  alias mprod='make prod'
  alias mdeploy='make deploy'
  alias msetup='make setup'
  alias minit='make init'
  alias mconfig='make config'
  alias mre='make re'
  alias mfclean='make fclean'
  
  # ============================================================================
  # UTILITY FUNCTIONS
  # ============================================================================
  
  # List all make targets
  make-list() {
    local makefile="${1:-$(_make_find_makefile)}"
    [[ -z "$makefile" ]] && { echo "No Makefile found"; return 1 }
    
    echo "=== Targets in $makefile ==="
    grep -E '^[a-zA-Z0-9_-]+:.*$' "$makefile" 2>/dev/null | 
      grep -v '^[A-Z_]*=' | 
      sed 's/:.*$//' | 
      sort -u | 
      nl
  }
  
  # List documented targets (with ## comments)
  make-help() {
    local makefile="${1:-$(_make_find_makefile)}"
    [[ -z "$makefile" ]] && { echo "No Makefile found"; return 1 }
    
    if grep -q '## ' "$makefile" 2>/dev/null; then
      echo "=== Available targets ==="
      grep -E '^[a-zA-Z0-9_-]+:.*## ' "$makefile" | 
        sed 's/:.*## /|/' | 
        awk -F'|' '{ printf "  \033[36m%-20s\033[0m %s\n", $1, $2 }'
    else
      make-list "$makefile"
    fi
  }
  
  # Find which Makefile defines a target
  make-where() {
    local target="$1"
    [[ -z "$target" ]] && { echo "Usage: make-where <target>"; return 1 }
    
    grep -rn "^$target:" . --include="Makefile" --include="makefile" --include="*.mk" 2>/dev/null |
      head -10
  }
  
  # Watch Makefile and rebuild on changes
  make-watch() {
    local target="${1:-all}"
    if (( $+commands[entr] )); then
      ls Makefile* *.c *.h 2>/dev/null | entr -c make "$target"
    else
      echo "entr not installed. Install with: brew install entr (macOS) or apt install entr (Linux)"
      return 1
    fi
  }
  
  # Create a basic Makefile for a C/C++ project
  make-init() {
    local project="${1:-$(basename $PWD)}"
    local lang="${2:-c}"
    
    [[ -f "Makefile" ]] && { echo "Makefile already exists"; return 1 }
    
    if [[ "$lang" == "cpp" || "$lang" == "c++" || "$lang" == "cxx" ]]; then
      cat > Makefile <<'EOF'
CXX = g++
CXXFLAGS = -Wall -Wextra -std=c++17 -O2
LDFLAGS =
SRCDIR = src
BUILDDIR = build
TARGET = bin/app

SOURCES = $(wildcard $(SRCDIR)/*.cpp)
OBJECTS = $(patsubst $(SRCDIR)/%.cpp,$(BUILDDIR)/%.o,$(SOURCES))

.PHONY: all clean debug run

all: $(TARGET)

$(TARGET): $(OBJECTS)
	@mkdir -p bin
	$(CXX) $(OBJECTS) -o $@ $(LDFLAGS)

$(BUILDDIR)/%.o: $(SRCDIR)/%.cpp
	@mkdir -p $(BUILDDIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILDDIR) bin

debug: CXXFLAGS = -Wall -Wextra -std=c++17 -g -DDEBUG
debug: clean $(TARGET)

run: $(TARGET)
	./$(TARGET)

# Help command
help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
EOF
    else
      cat > Makefile <<'EOF'
CC = gcc
CFLAGS = -Wall -Wextra -O2
LDFLAGS =
SRCDIR = src
BUILDDIR = build
TARGET = bin/app

SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(patsubst $(SRCDIR)/%.c,$(BUILDDIR)/%.o,$(SOURCES))

.PHONY: all clean debug run

all: $(TARGET)

$(TARGET): $(OBJECTS)
	@mkdir -p bin
	$(CC) $(OBJECTS) -o $@ $(LDFLAGS)

$(BUILDDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILDDIR) bin

debug: CFLAGS = -Wall -Wextra -g -DDEBUG
debug: clean $(TARGET)

run: $(TARGET)
	./$(TARGET)

# Help command
help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
EOF
    fi
    
    mkdir -p src bin
    echo "Created Makefile for $project ($lang)"
    echo "Run 'make help' for available targets"
  }
  
  # Generate compile_commands.json using bear or compiledb
  make-compdb() {
    if (( $+commands[bear] )); then
      bear -- make "$@"
    elif (( $+commands[compiledb] )); then
      compiledb make "$@"
    else
      echo "Install bear (brew install bear) or compiledb (pip install compiledb)"
      return 1
    fi
  }
}
