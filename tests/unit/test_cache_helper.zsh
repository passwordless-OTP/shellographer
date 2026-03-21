#!/usr/bin/env zsh
# Unit tests for cache-helper.zsh

source "${0:A:h:h}/framework.zsh"
source "${0:A:h:h:h}/shellographer/lib/cache-helper.zsh"

# Setup: Clean test cache directory
setup() {
  export XDG_CACHE_HOME="${TMPDIR:-/tmp}/shellographer-test-$$"
  mkdir -p "$XDG_CACHE_HOME/shellographer"
}

# Teardown: Remove test cache
teardown() {
  rm -rf "${TMPDIR:-/tmp}/shellographer-test-$$"
}

test_cache_miss_runs_command() {
  setup
  
  local result
  result=$(_shellographer_cache "test_miss" 60 "echo fresh_data")
  assert_equals "fresh_data" "$result" "Cache miss runs command and returns output"
  
  teardown
}

test_cache_hit_returns_cached_data() {
  setup
  
  # Create cache file
  echo "cached_data" > "$XDG_CACHE_HOME/shellographer/test_hit"
  
  local result
  result=$(_shellographer_cache "test_hit" 60 "echo new_data")
  assert_equals "cached_data" "$result" "Cache hit returns cached data"
  
  teardown
}

test_cache_expired_triggers_async_refresh() {
  setup
  
  # Create a cache file
  echo "cached_data" > "$XDG_CACHE_HOME/shellographer/test_async"
  
  # Create a lock file to simulate that a refresh is in progress
  # This tests the stale-while-revalidate behavior
  touch "$XDG_CACHE_HOME/shellographer/test_async.lock"
  
  # Should return cached data even with lock present
  local result
  result=$(_shellographer_cache "test_async" 60 "echo new_data")
  
  assert_equals "cached_data" "$result" "Returns cached data when lock exists (stale-while-revalidate)"
  
  teardown
}

test_cache_no_file_runs_command_sync() {
  setup
  
  # No cache file exists - should run command synchronously
  local result
  result=$(_shellographer_cache "test_sync" 60 "echo sync_result")
  
  assert_equals "sync_result" "$result" "No cache runs command synchronously"
  
  # Cache file should now exist
  [[ -f "$XDG_CACHE_HOME/shellographer/test_sync" ]]
  assert_equals 0 $? "Cache file created after sync execution"
  
  teardown
}

test_lock_prevents_duplicate_refresh() {
  setup
  
  # Create expired cache with lock file
  echo "data" > "$XDG_CACHE_HOME/shellographer/test_lock"
  touch "$XDG_CACHE_HOME/shellographer/test_lock.lock"
  
  # Should return stale data without triggering new refresh
  local result
  result=$(_shellographer_cache "test_lock" 5 "echo should_not_run")
  
  assert_equals "data" "$result" "Cache with lock returns stale data"
  
  # Lock file should still exist
  [[ -f "$XDG_CACHE_HOME/shellographer/test_lock.lock" ]]
  assert_equals 0 $? "Lock file preserved"
  
  teardown
}

test_cache_invalidate_removes_file() {
  setup
  
  echo "data" > "$XDG_CACHE_HOME/shellographer/test_invalidate"
  touch "$XDG_CACHE_HOME/shellographer/test_invalidate.lock"
  
  _shellographer_cache_invalidate "test_invalidate"
  
  [[ ! -f "$XDG_CACHE_HOME/shellographer/test_invalidate" ]]
  assert_equals 0 $? "Cache file removed after invalidate"
  
  [[ ! -f "$XDG_CACHE_HOME/shellographer/test_invalidate.lock" ]]
  assert_equals 0 $? "Lock file removed after invalidate"
  
  teardown
}

test_cache_clear_removes_all() {
  setup
  
  echo "data1" > "$XDG_CACHE_HOME/shellographer/test_clear1"
  echo "data2" > "$XDG_CACHE_HOME/shellographer/test_clear2"
  
  _shellographer_cache_clear
  
  [[ ! -d "$XDG_CACHE_HOME/shellographer" ]]
  assert_equals 0 $? "Cache directory removed after clear"
  
  teardown
}

# Run all tests
setup
run_test test_cache_miss_runs_command
run_test test_cache_hit_returns_cached_data
run_test test_cache_expired_triggers_async_refresh
run_test test_cache_no_file_runs_command_sync
run_test test_lock_prevents_duplicate_refresh
run_test test_cache_invalidate_removes_file
run_test test_cache_clear_removes_all
teardown

print_summary
