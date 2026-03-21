#!/usr/bin/env zsh
# Run all tests

0=${(%):-%N}
local test_dir=${0:A:h}

# Source framework
source "$test_dir/framework.zsh"

print "════════════════════════════════════════════════"
print "Shellographer Test Suite"
print "════════════════════════════════════════════════"

# Track overall results
local _total_run=0 _total_passed=0 _total_failed=0

# Run unit tests
print ""
print "📦 UNIT TESTS"
print "────────────────────────────────────────────────"

local unit_tests=("$test_dir"/unit/test_*.zsh(N))
for test_file in $unit_tests; do
  print "\n▶ Running: ${test_file:t}"
  
  # Run in subshell to isolate
  (
    source "$test_file" 2>&1
  )
  
  local code=$?
  if (( code == 0 )); then
    (( _total_passed++ ))
  else
    (( _total_failed++ ))
  fi
  (( _total_run++ ))
done

# Run integration tests
print ""
print "🔗 INTEGRATION TESTS"
print "────────────────────────────────────────────────"

local integration_tests=("$test_dir"/integration/test_*.zsh(N))
for test_file in $integration_tests; do
  print "\n▶ Running: ${test_file:t}"
  
  (
    source "$test_file" 2>&1
  )
  
  local code=$?
  if (( code == 0 )); then
    (( _total_passed++ ))
  else
    (( _total_failed++ ))
  fi
  (( _total_run++ ))
done

# Run E2E tests
print ""
print "🎯 E2E TESTS"
print "────────────────────────────────────────────────"

local e2e_tests=("$test_dir"/e2e/test_*.zsh(N))
for test_file in $e2e_tests; do
  print "\n▶ Running: ${test_file:t}"
  
  (
    source "$test_file" 2>&1
  )
  
  local code=$?
  if (( code == 0 )); then
    (( _total_passed++ ))
  else
    (( _total_failed++ ))
  fi
  (( _total_run++ ))
done

# Run performance tests
print ""
print "⚡ PERFORMANCE TESTS"
print "────────────────────────────────────────────────"

local perf_tests=("$test_dir"/performance/test_*.zsh(N))
for test_file in $perf_tests; do
  print "\n▶ Running: ${test_file:t}"
  
  (
    source "$test_file" 2>&1
  )
  
  local code=$?
  if (( code == 0 )); then
    (( _total_passed++ ))
  else
    (( _total_failed++ ))
  fi
  (( _total_run++ ))
done

# Summary
print ""
print "════════════════════════════════════════════════"
print "SUMMARY"
print "════════════════════════════════════════════════"
printf "Test files: %d\n" $_total_run
printf "Passed:     %d\n" $_total_passed
printf "Failed:     %d\n" $_total_failed
print "════════════════════════════════════════════════"

if (( _total_failed == 0 )); then
  print "✓ All test files passed!"
  exit 0
else
  print "✗ Some test files failed"
  exit 1
fi
