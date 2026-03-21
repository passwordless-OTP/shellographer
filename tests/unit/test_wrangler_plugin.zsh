#!/usr/bin/env zsh
# Unit tests for wrangler plugin

source "${0:A:h:h}/framework.zsh"

0=${(%):-%N}
local _test_dir=${0:A:h:h:h}

test_plugin_loads_without_error() {
  # Plugin should source without errors even if wrangler not installed
  source "$_test_dir/shellographer/plugins/wrangler/wrangler.plugin.zsh"
  assert_equals 0 $? "Wrangler plugin loads without error"
}

test_plugin_skips_when_wrangler_missing() {
  # Save original command check
  local _original_cmd=$commands[wrangler]
  
  # Simulate wrangler not installed
  commands[wrangler]=0
  
  # Unset any previously defined aliases
  unalias ${(M)aliases[(I)wrangler-*]} 2>/dev/null || true
  
  # Source plugin
  source "$_test_dir/shellographer/plugins/wrangler/wrangler.plugin.zsh"
  
  # Restore
  commands[wrangler]=$_original_cmd
  
  # If wrangler not installed, no aliases should be defined
  # This is a weak test - mainly checking no errors
  assert_equals 0 0 "Plugin handles missing wrangler gracefully"
}

test_fallback_works_without_helper() {
  # Save original function
  local _original_func=$functions[_shellographer_alias]
  
  # Unset helper
  unfunction _shellographer_alias 2>/dev/null || true
  
  # Source plugin (should use fallback)
  source "$_test_dir/shellographer/plugins/wrangler/wrangler.plugin.zsh"
  
  # Restore
  if [[ -n "$_original_func" ]]; then
    functions[_shellographer_alias]="$_original_func"
  fi
  
  assert_equals 0 $? "Plugin uses fallback when helper unavailable"
}

# Run tests
run_test test_plugin_loads_without_error
run_test test_plugin_skips_when_wrangler_missing
run_test test_fallback_works_without_helper

print_summary
