# Enhanced Cargo completions with features and target support
# ============================================================================

if ! (( $+commands[rustup] && $+commands[cargo] )); then
  return
fi

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `cargo`. Otherwise, compinit will have already done that
if [[ ! -f "$ZSH_CACHE_DIR/completions/_cargo" ]]; then
  autoload -Uz _cargo
  typeset -g -A _comps
  _comps[cargo]=_cargo
fi

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `rustup`. Otherwise, compinit will have already done that
if [[ ! -f "$ZSH_CACHE_DIR/completions/_rustup" ]]; then
  autoload -Uz _rustup
  typeset -g -A _comps
  _comps[rustup]=_rustup
fi

# Generate completion files in the background
rustup completions zsh >| "$ZSH_CACHE_DIR/completions/_rustup" &|
cat >| "$ZSH_CACHE_DIR/completions/_cargo" <<'EOF'
#compdef cargo
source "$(rustup run ${${(z)$(rustup default)}[1]} rustc --print sysroot)"/share/zsh/site-functions/_cargo
EOF

# ============================================================================
# CARGO FEATURE COMPLETIONS
# ============================================================================

# Complete features from Cargo.toml
_cargo_features() {
  local cargo_toml="$PWD/Cargo.toml"
  [[ -f "$cargo_toml" ]] || return
  
  local -a features
  features=(${(f)"$(cat "$cargo_toml" | python3 -c '
import tomllib, sys
try:
    data = tomllib.load(sys.stdin.buffer)
    feats = data.get("features", {})
    for name, deps in feats.items():
        if isinstance(deps, list):
            desc = f"enables: {', '.join(deps[:3])}"
            if len(deps) > 3:
                desc += f" (+{len(deps)-3})"
        else:
            desc = "feature flag"
        print(f"{name}:{desc}")
    # Add default if it exists
    if "default" in feats:
        print("default:Default features")
except:
    pass' 2>/dev/null || python3 -c '
import toml, sys
try:
    data = toml.load(sys.stdin)
    feats = data.get("features", {})
    for name, deps in feats.items():
        if isinstance(deps, list):
            desc = f"enables: {', '.join(deps[:3])}"
            if len(deps) > 3:
                desc += f" (+{len(deps)-3})"
        else:
            desc = "feature flag"
        print(f"{name}:{desc}")
except:
    pass' 2>/dev/null << EOF
$(cat "$cargo_toml")
EOF
)"})
  
  _describe -t features "features" features
}

# Complete build targets
_cargo_targets() {
  local cargo_toml="$PWD/Cargo.toml"
  local -a targets
  
  # Binaries
  if [[ -f "$cargo_toml" ]]; then
    targets+=(${(f)"$(cat "$cargo_toml" | python3 -c '
import tomllib, sys
try:
    data = tomllib.load(sys.stdin.buffer)
    # Binaries
    for i, bin in enumerate(data.get("bin", [])):
        name = bin.get("name", f"bin{i}")
        path = bin.get("path", "")
        print(f"{name}:binary ({path})")
    # Examples
    for i, ex in enumerate(data.get("example", [])):
        name = ex.get("name", f"example{i}")
        path = ex.get("path", "")
        print(f"{name}:example ({path})")
    # Tests
    for i, test in enumerate(data.get("test", [])):
        name = test.get("name", f"test{i}")
        path = test.get("path", "")
        print(f"{name}:test ({path})")
    # Benchmarks
    for i, bench in enumerate(data.get("bench", [])):
        name = bench.get("name", f"bench{i}")
        path = bench.get("path", "")
        print(f"{name}:benchmark ({path})")
except:
    pass' 2>/dev/null || python3 -c '
import toml, sys
try:
    data = toml.load(sys.stdin)
    for i, bin in enumerate(data.get("bin", [])):
        name = bin.get("name", f"bin{i}")
        path = bin.get("path", "")
        print(f"{name}:binary ({path})")
    for i, ex in enumerate(data.get("example", [])):
        name = ex.get("name", f"example{i}")
        path = ex.get("path", "")
        print(f"{name}:example ({path})")
except:
    pass' 2>/dev/null << EOF
$(cat "$cargo_toml")
EOF
)"})
  fi
  
  # Auto-detect from src directory
  if [[ -d src/bin ]]; then
    for bin in src/bin/*.rs; do
      [[ -f "$bin" ]] || continue
      local name=$(basename "$bin" .rs)
      targets+=("$name:binary (src/bin/$name.rs)")
    done
  fi
  
  if [[ -d examples ]]; then
    for ex in examples/*.rs; do
      [[ -f "$ex" ]] || continue
      local name=$(basename "$ex" .rs)
      targets+=("$name:example (examples/$name.rs)")
    done
  fi
  
  # Add lib target if present
  if [[ -f "src/lib.rs" ]]; then
    local pkg_name=$(grep -m1 '^name' Cargo.toml 2>/dev/null | sed 's/.*= *"\([^"]*\)".*/\1/')
    [[ -n "$pkg_name" ]] && targets+=("$pkg_name:library (src/lib.rs)")
  fi
  
  # Add main binary if present
  if [[ -f "src/main.rs" ]]; then
    local pkg_name=$(grep -m1 '^name' Cargo.toml 2>/dev/null | sed 's/.*= *"\([^"]*\)".*/\1/')
    [[ -n "$pkg_name" ]] && targets+=("$pkg_name:binary (src/main.rs)")
  fi
  
  _describe -t targets "targets" targets
}

# Complete test names
_cargo_tests() {
  local -a tests
  
  # Find test functions in test files
  if [[ -d tests ]]; then
    tests+=($(grep -r "^fn " tests/*.rs 2>/dev/null | sed 's/.*fn \([^ (]*\).*/\1/'))
  fi
  
  # Find #[test] functions in src
  tests+=($(grep -r "#\[test\]" src --include="*.rs" -A1 2>/dev/null | grep "^fn " | sed 's/.*fn \([^ (]*\).*/\1/'))
  
  # Find test modules
  tests+=($(grep -r "^mod " tests/*.rs 2>/dev/null | sed 's/.*mod \([^ {]*\).*/\1/'))
  
  _describe -t tests "tests" tests
}

# Complete dependencies
_cargo_deps() {
  local cargo_toml="$PWD/Cargo.toml"
  [[ -f "$cargo_toml" ]] || return
  
  local -a deps
  deps=(${(f)"$(cat "$cargo_toml" | python3 -c '
import tomllib, sys
try:
    data = tomllib.load(sys.stdin.buffer)
    for section in ["dependencies", "dev-dependencies", "build-dependencies"]:
        for name, spec in data.get(section, {}).items():
            if isinstance(spec, dict):
                version = spec.get("version", "")
                features = spec.get("features", [])
                desc = version if version else ", ".join(features[:2]) if features else section
            elif isinstance(spec, str):
                desc = f"{spec}"
            else:
                desc = section
            print(f"{name}:{desc}")
except:
    pass' 2>/dev/null || python3 -c '
import toml, sys
try:
    data = toml.load(sys.stdin)
    for section in ["dependencies", "dev-dependencies", "build-dependencies"]:
        for name, spec in data.get(section, {}).items():
            if isinstance(spec, dict):
                version = spec.get("version", "")
                print(f"{name}:{version or section}")
            elif isinstance(spec, str):
                print(f"{name}:{spec}")
            else:
                print(f"{name}:{section}")
except:
    pass' 2>/dev/null << EOF
$(cat "$cargo_toml")
EOF
)"})
  
  _describe -t deps "dependencies" deps
}

# Complete installed binaries
_cargo_bins() {
  local -a bins
  if [[ -d target/debug ]]; then
    bins+=($(ls -1 target/debug/ 2>/dev/null | grep -v "\.d$") )
  fi
  if [[ -d target/release ]]; then
    bins+=($(ls -1 target/release/ 2>/dev/null | grep -v "\.d$") )
  fi
  _describe -t bins "binaries" bins
}

# Complete profiles
_cargo_profiles() {
  local -a profiles=(
    "dev:Development build"
    "release:Release build"
    "test:Test build"
    "bench:Benchmark build"
  )
  
  # Add custom profiles from Cargo.toml
  local cargo_toml="$PWD/Cargo.toml"
  if [[ -f "$cargo_toml" ]]; then
    profiles+=(${(f)"$(cat "$cargo_toml" | python3 -c '
import tomllib, sys
try:
    data = tomllib.load(sys.stdin.buffer)
    for name in data.get("profile", {}).keys():
        print(f"{name}:custom profile")
except:
    pass' 2>/dev/null || python3 -c '
import toml, sys
try:
    data = toml.load(sys.stdin)
    for name in data.get("profile", {}).keys():
        print(f"{name}:custom profile")
except:
    pass' 2>/dev/null << EOF
$(cat "$cargo_toml")
EOF
)"})
  fi
  
  _describe -t profiles "profiles" profiles
}

# Complete triple targets
_cargo_triples() {
  local cache="$ZSH_CACHE_DIR/cargo_triples"
  if [[ ! -f "$cache" || -n "$cache"(#qNm+1440) ]]; then
    rustc --print target-list 2>/dev/null >| "$cache" &|
  fi
  
  local -a triples
  triples=($(cat "$cache" 2>/dev/null))
  
  # Common triples
  if (( ${#triples} == 0 )); then
    triples=(
      "x86_64-unknown-linux-gnu"
      "x86_64-unknown-linux-musl"
      "x86_64-apple-darwin"
      "aarch64-apple-darwin"
      "x86_64-pc-windows-msvc"
      "x86_64-pc-windows-gnu"
      "aarch64-unknown-linux-gnu"
      "aarch64-unknown-linux-musl"
      "wasm32-unknown-unknown"
      "wasm32-wasi"
      "thumbv7em-none-eabihf"
    )
  fi
  
  _describe -t triples "target triples" triples
}

# ============================================================================
# RUSTUP COMPLETIONS
# ============================================================================

# Complete toolchains
_rustup_toolchains() {
  local -a toolchains
  toolchains=($(rustup toolchain list 2>/dev/null | sed 's/ (default)//;s/ (override)//'))
  _describe -t toolchains "toolchains" toolchains
}

# Complete components
_rustup_components() {
  local -a components=(
    "rust-docs:Documentation"
    "rust-src:Rust source code"
    "rust-std:Standard library"
    "rustc:Compiler"
    "cargo:Build system"
    "clippy:Linter"
    "rustfmt:Formatter"
    "rust-analyzer:Language server"
    "llvm-tools:LLVM tools"
    "miri:Undefined behavior detection"
    "rls:Rust Language Server"
  )
  _describe -t components "components" components
}

# Complete targets
_rustup_targets() {
  local -a targets
  targets=($(rustup target list 2>/dev/null | grep "(installed)" | sed 's/ (installed)//'))
  targets+=($(rustc --print target-list 2>/dev/null | head -50))
  _describe -t targets "targets" targets
}

# ============================================================================
# CARGO ALIASES
# ============================================================================

# Basic commands
alias cb='cargo build'
alias cbr='cargo build --release'
alias cc='cargo check'
alias ccl='cargo clippy'
alias cclf='cargo clippy --fix'
alias cdoc='cargo doc'
alias cdoco='cargo doc --open'
alias cf='cargo fmt'
alias cn='cargo new'
alias cnb='cargo new --bin'
alias cnl='cargo new --lib'
alias cr='cargo run'
alias cre='cargo run --example'
alias crb='cargo run --bin'
alias ct='cargo test'
alias ctp='cargo test --package'
alias cu='cargo update'
alias cv='cargo verify-project'
alias cx='cargo clean'

# Test variations
alias cta='cargo test --all'
alias ctall='cargo test --all-features'
alias ctlib='cargo test --lib'
alias ctbin='cargo test --bins'
alias ctdoc='cargo test --doc'
alias cting='cargo test --integration'
alias ctu='cargo test --unit'

# Build variations
alias cba='cargo build --all'
alias cball='cargo build --all-features'
alias cbw='cargo build --workspace'
alias cbl='cargo build --lib'
alias cbb='cargo build --bins'

# Check variations
alias cca='cargo check --all'
alias ccw='cargo check --workspace'
alias ccall='cargo check --all-features'
alias cct='cargo check --tests'

# Release variations
alias cpub='cargo publish'
alias cpubd='cargo publish --dry-run'
alias cpubv='cargo publish --verify'

# Feature flags
alias cbf='cargo build --features'
alias cbnf='cargo build --no-default-features'
alias cbfall='cargo build --all-features'
alias ctf='cargo test --features'
alias ctnf='cargo test --no-default-features'

# Workspace
alias cwb='cargo build --workspace'
alias cwc='cargo check --workspace'
alias cwt='cargo test --workspace'
alias cwr='cargo run --workspace'

# Examples
alias ce='cargo run --example'
alias cel='cargo run --example $(ls examples/*.rs 2>/dev/null | head -1 | xargs basename -s .rs)'

# Benchmarks
alias cben='cargo bench'
alias cbenb='cargo build --benches'

# Documentation
alias cdo='cargo doc --open'
alias cdop='cargo doc --open --package'
alias cdw='cargo doc --workspace'
alias cdp='cargo doc --document-private-items'

# Fix and fmt
alias cfix='cargo fix'
alias cfixb='cargo fix --bin'
alias cfixl='cargo fix --lib'
alias cfixe='cargo fix --edition'
alias cfm='cargo fmt'
alias cfmt='cargo fmt --'

# Clean and cache
alias ccc='cargo clean'
alias cccc='cargo clean && cargo cache --autoclean'

# Expand macros
alias cexp='cargo expand'
alias cexpp='cargo expand --package'

# Miri (undefined behavior detection)
alias cmiri='cargo miri'
alias cmirir='cargo miri run'
alias cmiri='cargo miri test'

# Wasm
alias cwasmb='cargo build --target wasm32-unknown-unknown'
alias cwasmr='cargo run --target wasm32-wasi'

# Cross compilation helpers
alias cblinux='cargo build --target x86_64-unknown-linux-gnu'
alias cbmusl='cargo build --target x86_64-unknown-linux-musl'
alias cbmac='cargo build --target x86_64-apple-darwin'
alias cbmacarm='cargo build --target aarch64-apple-darwin'

# Rustup aliases
alias rup='rustup update'
alias rupn='rustup update nightly'
alias rups='rustup update stable'
alias rdefault='rustup default'
alias rov='rustup override'
alias rtarget='rustup target'
alias rcomp='rustup component'
alias rtool='rustup toolchain'
alias rdoc='rustup doc'
alias rself='rustup self'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Build and run in one command
cbrun() {
  cargo build --release && ./target/release/"${1:-$(basename $PWD)}"
}

# Watch and rebuild on changes
cwatch() {
  if (( $+commands[cargo-watch] )); then
    cargo watch -x "$1"
  else
    echo "cargo-watch not installed. Install with: cargo install cargo-watch"
    return 1
  fi
}

# Check all features one by one
check-all-features() {
  local features=$(cargo read-manifest 2>/dev/null | python3 -c '
import json,sys
data=json.load(sys.stdin)
print(" ".join(data.get("features", {}).keys()))
' 2>/dev/null)
  
  for feat in ${(z)features}; do
    echo "=== Checking feature: $feat ==="
    cargo check --features "$feat" || return 1
  done
}

# Run clippy with all features
clippy-all() {
  cargo clippy --all-features -- -D warnings
}

# Build for multiple targets
build-all-targets() {
  local targets=("x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl")
  for target in $targets; do
    echo "=== Building for $target ==="
    cargo build --release --target "$target" || echo "Failed for $target"
  done
}

# Clean build artifacts and target directory
clean-deep() {
  cargo clean
  rm -rf target/
  find . -name "*.rs.bk" -delete
  find . -name "*.pdb" -delete
}

# Show crate info
crate-info() {
  local crate="$1"
  [[ -z "$crate" ]] && { echo "Usage: crate-info <crate-name>"; return 1 }
  cargo search "$crate" --limit 1
}

# List available examples
list-examples() {
  if [[ -d examples ]]; then
    ls -1 examples/*.rs 2>/dev/null | xargs -n1 basename -s .rs
  else
    echo "No examples directory found"
  fi
}

# Run cargo with specific feature combo
cargo-with-features() {
  local feats="$1"
  shift
  cargo "$@" --features "$feats"
}

# Test with different feature combinations
test-features() {
  echo "=== Testing without features ==="
  cargo test --no-default-features
  echo "=== Testing with default features ==="
  cargo test
  echo "=== Testing with all features ==="
  cargo test --all-features
}

# Benchmark and save results
bench-save() {
  local name="${1:-$(date +%Y%m%d-%H%M%S)}"
  cargo bench | tee "benchmark-$name.txt"
}

# Setup a new Rust project with common defaults
rust-init() {
  local name="$1"
  local lib="$2"
  
  if [[ "$lib" == "--lib" ]]; then
    cargo new --lib "$name"
  else
    cargo new "$name"
  fi
  
  cd "$name"
  
  # Add common dev dependencies
  cat >> Cargo.toml <<'EOF'

[dev-dependencies]
# Add your dev dependencies here

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
panic = "abort"
strip = true

[profile.dev]
opt-level = 0
debug = true
EOF

  echo "Created Rust project: $name"
}

# Update all Rust tools installed via cargo
cargo-update-tools() {
  cargo install --list | grep -E '^[a-z0-9_-]+ v[0-9.]+:$' | sed 's/ v.*$//' | while read tool; do
    echo "Updating $tool..."
    cargo install "$tool" --force
  done
}
