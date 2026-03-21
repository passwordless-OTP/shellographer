#!/usr/bin/env zsh
# E2E tests for installation

source "${0:A:h:h}/framework.zsh"

0=${(%):-%N}
local _test_dir=${0:A:h:h:h}

test_install_structure() {
  # Verify expected files exist
  [[ -f "$_test_dir/shellographer/shellographer.plugin.zsh" ]]
  assert_equals 0 $? "Main plugin file exists"
  
  [[ -f "$_test_dir/shellographer/lib/alias-helper.zsh" ]]
  assert_equals 0 $? "alias-helper.zsh exists"
  
  [[ -f "$_test_dir/shellographer/lib/cache-helper.zsh" ]]
  assert_equals 0 $? "cache-helper.zsh exists"
  
  [[ -f "$_test_dir/shellographer/lib/caps.zsh" ]]
  assert_equals 0 $? "caps.zsh exists"
  
  [[ -f "$_test_dir/shellographer/plugins/wrangler/wrangler.plugin.zsh" ]]
  assert_equals 0 $? "wrangler plugin exists"
  
  [[ -f "$_test_dir/shellographer/plugins/gh/gh.plugin.zsh" ]]
  assert_equals 0 $? "gh plugin exists"
  
  [[ -f "$_test_dir/shellographer/plugins/docker/docker.plugin.zsh" ]]
  assert_equals 0 $? "docker plugin exists"
}

test_all_plugins_load() {
  local test_zshrc=$(mktemp)
  
  # Direct source (no oh-my-zsh dependency)
  cat > $test_zshrc << EOF
SHELLOGRAPHER_PLUGINS="wrangler gh docker"
source $_test_dir/shellographer/shellographer.plugin.zsh

# Check markers are set
[[ -n "\$_SHELLOGRAPHER_PLUGIN_WRANGLER" ]]
[[ -n "\$_SHELLOGRAPHER_PLUGIN_GH" ]]
[[ -n "\$_SHELLOGRAPHER_PLUGIN_DOCKER" ]]
EOF
  
  zsh -c "source $test_zshrc" 2>&1
  assert_equals 0 $? "All plugins load successfully"
  
  rm -f $test_zshrc
}

test_caps_command_works() {
  local test_zshrc=$(mktemp)
  
  # Direct source (no oh-my-zsh dependency)
  cat > $test_zshrc << EOF
source $_test_dir/shellographer/shellographer.plugin.zsh

# caps should be available
which caps > /dev/null
EOF
  
  zsh -c "source $test_zshrc" 2>&1
  assert_equals 0 $? "caps command is available"
  
  rm -f $test_zshrc
}

# Run tests
run_test test_install_structure
run_test test_all_plugins_load
run_test test_caps_command_works

print_summary
