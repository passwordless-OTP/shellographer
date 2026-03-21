#!/usr/bin/env zsh
# Unit tests for caps.zsh

source "${0:A:h:h}/framework.zsh"
source "${0:A:h:h:h}/shellographer/lib/alias-helper.zsh"  # For _SHELLOGRAPHER_REGISTRY
source "${0:A:h:h:h}/shellographer/lib/caps.zsh"

# Setup: Ensure we have the registry variable
setup() {
  typeset -gA _SHELLOGRAPHER_REGISTRY
  export XDG_CACHE_HOME="${TMPDIR:-/tmp}/shellographer-caps-test-$$"
  mkdir -p "$XDG_CACHE_HOME/shellographer"
}

teardown() {
  rm -rf "${TMPDIR:-/tmp}/shellographer-caps-test-$$"
  unset _SHELLOGRAPHER_REGISTRY 2>/dev/null || true
}

test_caps_write_persists_registry() {
  setup
  
  # Populate registry
  _SHELLOGRAPHER_REGISTRY[wrangler-dev-server]="Start dev server"
  _SHELLOGRAPHER_REGISTRY[wrangler-deploy-worker]="Deploy worker"
  _SHELLOGRAPHER_REGISTRY[gh-pr-create]="Create PR"
  
  # Write to file
  _shellographer_caps_write
  
  # Verify file exists and contains entries
  local registry_file="$XDG_CACHE_HOME/shellographer/registry"
  [[ -f "$registry_file" ]]
  assert_equals 0 $? "Registry file created"
  
  # Verify content
  local count
  count=$(grep -c "^wrangler-" "$registry_file" 2>/dev/null || echo 0)
  assert_equals 2 "$count" "Two wrangler entries in registry"
  
  teardown
}

test_caps_lists_services() {
  setup
  
  # Create a registry file
  cat > "$XDG_CACHE_HOME/shellographer/registry" << 'EOF'
wrangler-dev-server:Start dev server
wrangler-deploy-worker:Deploy worker
gh-pr-create:Create PR
gh-pr-list:List PRs
docker-container-list:List containers
EOF
  
  # Test caps with no arguments lists services
  local services
  services=$(caps)
  
  [[ "$services" == *"wrangler"* ]]
  assert_equals 0 $? "Services include wrangler"
  
  [[ "$services" == *"gh"* ]]
  assert_equals 0 $? "Services include gh"
  
  [[ "$services" == *"docker"* ]]
  assert_equals 0 $? "Services include docker"
  
  teardown
}

test_caps_lists_commands_for_service() {
  setup
  
  # Create a registry file
  cat > "$XDG_CACHE_HOME/shellographer/registry" << 'EOF'
wrangler-dev-server:Start dev server
wrangler-deploy-worker:Deploy worker
wrangler-kv-list:List KV namespaces
gh-pr-create:Create PR
EOF
  
  # Test caps with service argument
  local commands
  commands=$(caps wrangler)
  
  [[ "$commands" == *"wrangler-dev-server"* ]]
  assert_equals 0 $? "Commands include wrangler-dev-server"
  
  [[ "$commands" == *"wrangler-deploy-worker"* ]]
  assert_equals 0 $? "Commands include wrangler-deploy-worker"
  
  # Should not include gh commands
  [[ "$commands" != *"gh-pr-create"* ]]
  assert_equals 0 $? "Commands do not include gh-pr-create"
  
  teardown
}

test_caps_lazy_writes_memory() {
  setup
  
  # Populate in-memory registry only
  _SHELLOGRAPHER_REGISTRY[test-alias-1]="Test description 1"
  _SHELLOGRAPHER_REGISTRY[test-alias-2]="Test description 2"
  
  # No registry file yet
  [[ ! -f "$XDG_CACHE_HOME/shellographer/registry" ]]
  assert_equals 0 $? "No registry file before caps call"
  
  # Call caps (triggers lazy write)
  caps > /dev/null
  
  # Now file should exist
  [[ -f "$XDG_CACHE_HOME/shellographer/registry" ]]
  assert_equals 0 $? "Registry file created after caps call (lazy write)"
  
  teardown
}

test_caps_clear_removes_registry() {
  setup
  
  # Create registry
  echo "test-alias:Test" > "$XDG_CACHE_HOME/shellographer/registry"
  _SHELLOGRAPHER_REGISTRY[test-alias]="Test"
  
  # Clear
  caps-clear
  
  # File should be gone
  [[ ! -f "$XDG_CACHE_HOME/shellographer/registry" ]]
  assert_equals 0 $? "Registry file removed after caps-clear"
  
  # Memory should be cleared
  (( ${#_SHELLOGRAPHER_REGISTRY} == 0 ))
  assert_equals 0 $? "Memory registry cleared after caps-clear"
  
  teardown
}

# Run all tests
setup
run_test test_caps_write_persists_registry
run_test test_caps_lists_services
run_test test_caps_lists_commands_for_service
run_test test_caps_lazy_writes_memory
run_test test_caps_clear_removes_registry
teardown

print_summary
