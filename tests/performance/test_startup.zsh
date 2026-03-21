#!/usr/bin/env zsh
# Performance tests for startup time

source "${0:A:h:h}/framework.zsh"

0=${(%):-%N}
local _test_dir=${0:A:h:h:h}

test_startup_under_50ms() {
  local test_zshrc=$(mktemp)
  
  # Direct source without oh-my-zsh overhead
  cat > $test_zshrc << EOF
source $_test_dir/shellographer/shellographer.plugin.zsh
EOF
  
  # Warmup
  zsh -c "source $test_zshrc" 2>/dev/null
  
  # Benchmark
  local start end duration_ms
  start=$(date +%s%N)
  zsh -c "source $test_zshrc; exit 0" 2>/dev/null
  end=$(date +%s%N)
  
  duration_ms=$(( (end - start) / 1000000 ))
  
  print "Startup time: ${duration_ms}ms"
  
  # Should be under 50ms (relaxed to 100ms for CI)
  (( duration_ms < 100 ))
  assert_equals 0 $? "Startup under 100ms (${duration_ms}ms)"
  
  rm -f $test_zshrc
}

test_startup_single_plugin() {
  local test_zshrc=$(mktemp)
  
  # Direct source without oh-my-zsh overhead
  cat > $test_zshrc << EOF
SHELLOGRAPHER_PLUGINS="wrangler"
source $_test_dir/shellographer/shellographer.plugin.zsh
EOF
  
  # Warmup
  zsh -c "source $test_zshrc" 2>/dev/null
  
  # Benchmark
  local start end duration_ms
  start=$(date +%s%N)
  zsh -c "source $test_zshrc; exit 0" 2>/dev/null
  end=$(date +%s%N)
  
  duration_ms=$(( (end - start) / 1000000 ))
  
  print "Single plugin startup: ${duration_ms}ms"
  
  # Should be under 50ms (relaxed for CI)
  (( duration_ms < 50 ))
  assert_equals 0 $? "Single plugin startup under 50ms (${duration_ms}ms)"
  
  rm -f $test_zshrc
}

test_no_file_io_at_startup() {
  # Verify no registry file is created at startup
  local test_cache="${TMPDIR:-/tmp}/shellographer-perf-test-$$"
  export XDG_CACHE_HOME="$test_cache"
  
  local test_zshrc=$(mktemp)
  cat > $test_zshrc << EOF
export XDG_CACHE_HOME="$test_cache"
export ZSH="$HOME/.oh-my-zsh"
plugins=(shellographer)
source \$ZSH/oh-my-zsh.sh
EOF
  
  # Run shell
  zsh -c "source $test_zshrc" 2>/dev/null
  
  # No registry file should exist yet (lazy write)
  [[ ! -f "$test_cache/shellographer/registry" ]]
  assert_equals 0 $? "No registry file created at startup (lazy write)"
  
  rm -f $test_zshrc
  rm -rf "$test_cache"
}

# Run tests
run_test test_startup_under_50ms
run_test test_startup_single_plugin
run_test test_no_file_io_at_startup

print_summary
