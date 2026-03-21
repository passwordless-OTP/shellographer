#!/usr/bin/env zsh
# Test framework for shellographer

setopt nounset local_options no_err_exit

# Test counters
typeset -gi _TESTS_RUN=0 _TESTS_PASSED=0 _TESTS_FAILED=0 _TESTS_SKIPPED=0
typeset -ga _TEST_FAILURES=()

# Assertion functions
assert_equals() {
  local expected=$1 actual=$2 name=$3
  (( _TESTS_RUN++ ))
  if [[ "$expected" == "$actual" ]]; then
    (( _TESTS_PASSED++ ))
    print "✓ $name"
    return 0
  else
    (( _TESTS_FAILED++ ))
    _TEST_FAILURES+=("$name: expected '$expected', got '$actual'")
    print "✗ $name"
    print "  Expected: $expected"
    print "  Actual:   $actual"
    return 1
  fi
}

assert_true() {
  local exit_code=$1 name=$2
  (( _TESTS_RUN++ ))
  if (( exit_code == 0 )); then
    (( _TESTS_PASSED++ ))
    print "✓ $name"
    return 0
  else
    (( _TESTS_FAILED++ ))
    _TEST_FAILURES+=("$name: expected true, got exit code $exit_code")
    print "✗ $name"
    return 1
  fi
}

assert_alias_exists() {
  local name=$1
  (( _TESTS_RUN++ ))
  if (( $+aliases[$name] )); then
    (( _TESTS_PASSED++ ))
    print "✓ Alias $name exists"
  else
    (( _TESTS_FAILED++ ))
    _TEST_FAILURES+=("Alias $name does not exist")
    print "✗ Alias $name does not exist"
  fi
}

skip_if_no_command() {
  local cmd=$1
  if (( ! $+commands[$cmd] )); then
    (( _TESTS_SKIPPED++ ))
    print "⊘ Skipped: $cmd not installed"
    return 1
  fi
  return 0
}

# Test runner
run_test() {
  local test_fn=$1
  print ""
  print "▶ $test_fn"
  $test_fn
}

# Summary
print_summary() {
  print ""
  print "═══════════════════════════════════════"
  print "Test Results: $_TESTS_PASSED/$_TESTS_RUN passed ($_TESTS_SKIPPED skipped)"
  print "═══════════════════════════════════════"
  
  if (( ${#_TEST_FAILURES} > 0 )); then
    print ""
    print "Failures:"
    local failure
    for failure in $_TEST_FAILURES; do
      print "  - $failure"
    done
  fi
  
  (( _TESTS_FAILED == 0 ))
  return $?
}
