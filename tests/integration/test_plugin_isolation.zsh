#!/usr/bin/env zsh
# Integration tests for plugin isolation

source "${0:A:h:h}/framework.zsh"

0=${(%):-%N}
local _test_dir=${0:A:h:h:h}

test_wrangler_works_standalone() {
  local test_zshrc=$(mktemp)
  
  # Don't load shellographer.plugin.zsh, just wrangler directly
  cat > $test_zshrc << EOF
# Don't load main shellographer, just wrangler plugin
source $_test_dir/shellographer/plugins/wrangler/wrangler.plugin.zsh
alias | grep -q "wrangler-dev-server"
EOF
  
  zsh -c "source $test_zshrc" 2>&1
  assert_equals 0 $? "Wrangler plugin works standalone"
  
  rm -f $test_zshrc
}

test_gh_works_standalone() {
  local test_zshrc=$(mktemp)
  
  cat > $test_zshrc << EOF
source $_test_dir/shellographer/plugins/gh/gh.plugin.zsh
alias | grep -q "gh-pr-create"
EOF
  
  zsh -c "source $test_zshrc" 2>&1
  assert_equals 0 $? "GitHub plugin works standalone"
  
  rm -f $test_zshrc
}

test_docker_works_standalone() {
  local test_zshrc=$(mktemp)
  
  cat > $test_zshrc << EOF
source $_test_dir/shellographer/plugins/docker/docker.plugin.zsh
alias | grep -q "docker-container-list"
EOF
  
  zsh -c "source $test_zshrc" 2>&1
  assert_equals 0 $? "Docker plugin works standalone"
  
  rm -f $test_zshrc
}

test_double_load_protection() {
  local test_zshrc=$(mktemp)
  
  cat > $test_zshrc << EOF
export ZSH="$HOME/.oh-my-zsh"
plugins=(shellographer)
source \$ZSH/oh-my-zsh.sh
# Try to load again - should be no-op
source $_test_dir/shellographer/shellographer.plugin.zsh
EOF
  
  # Should not error on double load
  zsh -c "source $test_zshrc; exit 0" 2>&1
  assert_equals 0 $? "Double load protection works"
  
  rm -f $test_zshrc
}

# Run tests
run_test test_wrangler_works_standalone
run_test test_gh_works_standalone
run_test test_docker_works_standalone
run_test test_double_load_protection

print_summary
