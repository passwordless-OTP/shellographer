#!/usr/bin/env zsh
# Unit tests for alias-helper.zsh

source "${0:A:h:h}/framework.zsh"
source "${0:A:h:h:h}/shellographer/lib/alias-helper.zsh"

test_alias_created_when_no_conflict() {
  _shellographer_alias "test-create" "echo test"
  assert_equals 0 $? "Alias creation returns 0"
  assert_alias_exists "test-create"
  unalias test-create 2>/dev/null || true
}

test_alias_skipped_when_function_exists() {
  test-skip-func() { echo "existing"; }
  _shellographer_alias "test-skip-func" "echo new"
  assert_equals 1 $? "Conflict with function returns 1"
  unfunction test-skip-func 2>/dev/null || true
}

test_alias_skipped_when_alias_exists() {
  alias test-skip-alias="echo existing"
  _shellographer_alias "test-skip-alias" "echo new"
  assert_equals 1 $? "Conflict with alias returns 1"
  unalias test-skip-alias 2>/dev/null || true
}

test_debug_mode_shows_output() {
  SHELLOGRAPHER_DEBUG=1
  alias test-debug="echo test"
  local output
  output=$(_shellographer_alias "test-debug" "echo new" 2>&1)
  SHELLOGRAPHER_DEBUG=0
  [[ "$output" == *"Skip"* ]]
  assert_equals 0 $? "Debug mode shows skip message"
  unalias test-debug 2>/dev/null || true
}

test_validation_empty_name() {
  _shellographer_alias "" "echo test"
  assert_equals 2 $? "Empty name returns error 2"
}

test_validation_empty_command() {
  _shellographer_alias "test-empty-cmd" ""
  assert_equals 2 $? "Empty command returns error 2"
}

test_registry_populated() {
  _shellographer_alias "test-registry" "echo test" "Test description"
  [[ -n "${_SHELLOGRAPHER_REGISTRY[test-registry]}" ]]
  assert_equals 0 $? "Registry populated with description"
  unalias test-registry 2>/dev/null || true
}

# Run all tests
run_test test_alias_created_when_no_conflict
run_test test_alias_skipped_when_function_exists
run_test test_alias_skipped_when_alias_exists
run_test test_debug_mode_shows_output
run_test test_validation_empty_name
run_test test_validation_empty_command
run_test test_registry_populated

print_summary
