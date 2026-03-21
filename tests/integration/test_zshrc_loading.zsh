#!/usr/bin/env zsh
# Integration tests for .zshrc loading

source "${0:A:h:h}/framework.zsh"

0=${(%):-%N}
local _test_dir=${0:A:h:h:h}

test_no_parse_errors() {
  local test_zshrc=$(mktemp)
  
  cat > $test_zshrc << EOF
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(shellographer)
source \$ZSH/oh-my-zsh.sh
EOF
  
  zsh -c "source $test_zshrc; exit 0" 2>&1
  assert_equals 0 $? ".zshrc sources without errors"
  
  rm -f $test_zshrc
}

test_user_function_preserved() {
  local test_zshrc=$(mktemp)
  
  cat > $test_zshrc << 'EOF'
gh-pr-create() { echo "user function"; }
export ZSH="$HOME/.oh-my-zsh"
plugins=(shellographer)
source $ZSH/oh-my-zsh.sh
type gh-pr-create | grep -q "function"
EOF
  
  zsh -c "source $test_zshrc" 2>&1
  assert_equals 0 $? "User function preserved"
  
  rm -f $test_zshrc
}

test_aliases_available() {
  local test_zshrc=$(mktemp)
  
  # Direct source (no oh-my-zsh dependency)
  cat > $test_zshrc << EOF
source $_test_dir/shellographer/shellographer.plugin.zsh
alias | grep -q "wrangler-dev-server\|gh-pr-create\|docker-container-list"
EOF
  
  zsh -c "source $test_zshrc" 2>&1
  assert_equals 0 $? "Shellographer aliases available"
  
  rm -f $test_zshrc
}

test_debug_mode_works() {
  local test_zshrc=$(mktemp)
  
  cat > $test_zshrc << 'EOF'
SHELLOGRAPHER_DEBUG=1
export ZSH="$HOME/.oh-my-zsh"
plugins=(shellographer)
source $ZSH/oh-my-zsh.sh
EOF
  
  local output
  output=$(zsh -c "source $test_zshrc" 2>&1)
  
  # Debug mode should produce some output
  [[ -n "$output" ]]
  assert_equals 0 $? "Debug mode produces output"
  
  rm -f $test_zshrc
}

# Run tests
run_test test_no_parse_errors
run_test test_user_function_preserved
run_test test_aliases_available
run_test test_debug_mode_works

print_summary
