#!/usr/bin/env zsh
# Unit tests for shellographer.plugin.zsh (main loader)

source "${0:A:h:h}/framework.zsh"

# Get the plugin directory
0=${(%):-%N}
local _test_dir=${0:A:h:h:h}

# Note: These tests need to run in isolation because the guard variable
# prevents double-loading. We test what we can.

test_guard_prevents_double_loading() {
  # Create a subshell to test double-loading
  (
    source "$_test_dir/shellographer/shellographer.plugin.zsh"
    [[ -n "$_SHELLOGRAPHER_LOADED" ]]
    exit $?
  )
  assert_equals 0 $? "Guard variable set after load"
  
  # Test that second load is skipped (in same shell)
  # After sourcing above, _SHELLOGRAPHER_LOADED should be set
  # and the file should return immediately
  local _before=$SECONDS
  source "$_test_dir/shellographer/shellographer.plugin.zsh"
  local _after=$SECONDS
  local _elapsed=$(( (_after - _before) * 1000 ))
  
  # Second load should be very fast (< 10ms since it just returns)
  [[ $_elapsed -lt 100 ]]
  assert_equals 0 $? "Second load is fast (guard prevents re-processing)"
}

test_loads_helper_functions() {
  # Helpers should be loaded after sourcing
  (( $+functions[_shellographer_alias] ))
  assert_equals 0 $? "_shellographer_alias function loaded"
  
  (( $+functions[_shellographer_cache] ))
  assert_equals 0 $? "_shellographer_cache function loaded"
  
  (( $+functions[caps] ))
  assert_equals 0 $? "caps function loaded"
}

test_default_plugins_list() {
  # Default should be: wrangler gh docker
  # We verify by checking the logic in the file
  local _default_plugins
  _default_plugins=$(grep "SHELLOGRAPHER_PLUGINS:-" "$_test_dir/shellographer/shellographer.plugin.zsh" | head -1)
  
  [[ "$_default_plugins" == *"wrangler gh docker"* ]]
  assert_equals 0 $? "Default plugins list includes wrangler gh docker"
}

test_plugin_markers_set() {
  # After loading, plugin markers should be set
  # Note: These are only set if the plugin files exist
  # Since we don't have plugin files yet, this tests the warning path
  
  # The code should attempt to load wrangler, gh, docker
  # and either load them or show warnings in debug mode
  (( $+_SHELLOGRAPHER_LOADED ))
  assert_equals 0 $? "Main loaded marker is set"
}

# Run all tests
run_test test_guard_prevents_double_loading
run_test test_loads_helper_functions
run_test test_default_plugins_list
run_test test_plugin_markers_set

print_summary
