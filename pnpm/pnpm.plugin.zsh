# Enhanced pnpm completions with workspace and filter support
# ============================================================================

(( $+commands[pnpm] )) && {
  
  # ============================================================================
  # PNPM SCRIPT COMPLETIONS
  # ============================================================================
  
  # Complete pnpm scripts from package.json
  _pnpm_scripts() {
    local package_json="$PWD/package.json"
    [[ -f "$package_json" ]] || return
    
    local -a scripts
    scripts=(${(f)"$(cat "$package_json" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    scripts = data.get("scripts", {})
    for name, cmd in scripts.items():
        desc = cmd[:50] + "..." if len(cmd) > 50 else cmd
        print(f"{name}:{desc}")
except:
    pass' 2>/dev/null)"})
    
    _describe -t scripts "pnpm scripts" scripts
  }
  
  # Complete pnpm workspaces from pnpm-workspace.yaml
  _pnpm_workspaces() {
    local workspace_yaml="$PWD/pnpm-workspace.yaml"
    local workspace_yml="$PWD/pnpm-workspace.yml"
    
    local -a workspaces
    
    if [[ -f "$workspace_yaml" || -f "$workspace_yml" ]]; then
      local ws_file="${workspace_yaml:-$workspace_yml}"
      workspaces=(${(f)"$(cat "$ws_file" | python3 -c '
import yaml, sys, os, glob
try:
    data = yaml.safe_load(sys.stdin)
    packages = data.get("packages", [])
    for pattern in packages:
        # Expand glob patterns relative to workspace root
        for path in glob.glob(pattern):
            if os.path.isdir(path):
                pkg_json = os.path.join(path, "package.json")
                if os.path.exists(pkg_json):
                    import json
                    pkg = json.load(open(pkg_json))
                    name = pkg.get("name", path)
                    print(f"{name}:{path}")
                else:
                    print(f"{path}:{path}")
except:
    pass' 2>/dev/null)"})
    fi
    
    # Also check for packages field in package.json (rare but possible)
    local package_json="$PWD/package.json"
    if [[ -f "$package_json" ]] && [[ -z "$workspaces" ]]; then
      workspaces+=(${(f)"$(cat "$package_json" | python3 -c '
import json, sys, os, glob
try:
    data = json.load(sys.stdin)
    ws = data.get("workspaces", [])
    if isinstance(ws, dict):
        ws = ws.get("packages", [])
    for pattern in ws:
        for path in glob.glob(pattern):
            if os.path.isdir(path):
                pkg_json = os.path.join(path, "package.json")
                if os.path.exists(pkg_json):
                    pkg = json.load(open(pkg_json))
                    name = pkg.get("name", path)
                    print(f"{name}:{path}")
except:
    pass' 2>/dev/null)"})
    fi
    
    _describe -t workspaces "workspaces" workspaces
  }
  
  # Complete pnpm filter patterns
  _pnpm_filters() {
    local -a filters=()
    
    # Add package names from workspace
    local workspace_yaml="$PWD/pnpm-workspace.yaml"
    if [[ -f "$workspace_yaml" ]]; then
      filters+=(${(f)"$(cat "$workspace_yaml" | python3 -c '
import yaml, sys, os, json, glob
try:
    data = yaml.safe_load(sys.stdin)
    packages = data.get("packages", [])
    for pattern in packages:
        for path in glob.glob(pattern):
            if os.path.isdir(path):
                pkg_json = os.path.join(path, "package.json")
                if os.path.exists(pkg_json):
                    pkg = json.load(open(pkg_json))
                    name = pkg.get("name")
                    if name:
                        print(f"{name}:Package {name}")
except:
    pass' 2>/dev/null)"})
    fi
    
    # Add common filter patterns
    filters+=(
      "...<name>:Include dependents"
      "<name>...:Include dependencies"
      "...<name>...:Include dependents and dependencies"
      "./<path>:Include package by path"
      "{<glob>}:Include packages matching glob"
      "!<name>:Exclude package"
      "*[<since>]:Changed since commit/branch"
      "*[master]:Changed since master"
      "*[HEAD~1]:Changed since HEAD~1"
    )
    
    _describe -t filters "filter patterns" filters
  }
  
  # Complete installed packages
  _pnpm_packages() {
    local -a packages
    
    # From node_modules
    if [[ -d node_modules ]]; then
      packages=($(ls -1 node_modules 2>/dev/null | grep -v "^\.")
                $(ls -1 node_modules/@* 2>/dev/null 2>/dev/null | tr '\n' ' '))
    fi
    
    # From package.json
    local package_json="$PWD/package.json"
    if [[ -f "$package_json" ]]; then
      local deps=(${(f)"$(cat "$package_json" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    for key in ["dependencies", "devDependencies", "peerDependencies", "optionalDependencies"]:
        for pkg in data.get(key, {}):
            print(f"{pkg}:{key}")
except:
    pass' 2>/dev/null)"})
      packages+=($deps)
    fi
    
    _describe -t packages "packages" packages
  }
  
  # Complete store packages
  _pnpm_store_packages() {
    local -a packages
    if [[ -d ~/.local/share/pnpm/store ]]; then
      packages=($(ls -1 ~/.local/share/pnpm/store 2>/dev/null | head -50))
    elif [[ -d ~/Library/pnpm/store ]]; then
      packages=($(ls -1 ~/Library/pnpm/store 2>/dev/null | head -50))
    fi
    _describe -t packages "stored packages" packages
  }
  
  # Complete .bin commands
  _pnpm_binaries() {
    local -a binaries
    
    # Local binaries
    if [[ -d node_modules/.bin ]]; then
      binaries+=($(ls -1 node_modules/.bin 2>/dev/null))
    fi
    
    # Global binaries
    local global_bin="$(pnpm bin -g 2>/dev/null)"
    if [[ -n "$global_bin" && -d "$global_bin" ]]; then
      binaries+=($(ls -1 "$global_bin" 2>/dev/null))
    fi
    
    _describe -t binaries "binaries" binaries
  }
  
  # Complete pnpm config keys
  _pnpm_config_keys() {
    local -a configs=(
      "allow-build:Allow build scripts for packages"
      "cache-dir:Cache directory"
      "child-concurrency:Child process concurrency"
      "color:Color output"
      "dedupe-direct-deps:Deduplicate direct dependencies"
      "dedupe-injected-deps:Deduplicate injected dependencies"
      "deploy-all-files:Deploy all files"
      "enable-modules-dir:Enable node_modules directory"
      "enable-pre-post-scripts:Enable pre/post scripts"
      "exclude-links-from-lockfile:Exclude links from lockfile"
      "extend-node-path:Extend NODE_PATH"
      "fetch-retries:Fetch retry count"
      "fetch-retry-factor:Fetch retry factor"
      "fetch-retry-maxtimeout:Fetch retry max timeout"
      "fetch-retry-mintimeout:Fetch retry min timeout"
      "fetch-timeout:Fetch timeout"
      "git-branch-lockfile:Use git branch name in lockfile"
      "global-bin-dir:Global binary directory"
      "global-dir:Global directory"
      "global-pnpmfile:Global pnpmfile"
      "hoist:Hoist packages"
      "hoist-pattern:Hoist pattern"
      "ignore-compatibility-db:Ignore compatibility database"
      "ignore-dep-scripts:Ignore dependency scripts"
      "ignore-package-manager-spec:Ignore packageManager spec"
      "ignore-pnpmfile:Ignore pnpmfile"
      "ignore-workspace-root-check:Ignore workspace root check"
      "include-workspace-root:Include workspace root"
      "init-author-email:Init author email"
      "init-author-name:Init author name"
      "init-author-url:Init author URL"
      "init-license:Init license"
      "init-module:Init module"
      "init-version:Init version"
      "inject-workspace-packages:Inject workspace packages"
      "legacy-dir-filtering:Legacy directory filtering"
      "link-workspace-packages:Link workspace packages"
      "lockfile:Lockfile setting"
      "lockfile-dir:Lockfile directory"
      "lockfile-include-tarball-url:Include tarball URL in lockfile"
      "loglevel:Log level"
      "maxsockets:Max sockets"
      "modules-cache-max-age:Modules cache max age"
      "modules-dir:Modules directory"
      "network-concurrency:Network concurrency"
      "node-linker:Node linker"
      "node-version:Node version"
      "noproxy:No proxy"
      "npm-path:NPM path"
      "only-built-dependencies:Only built dependencies"
      "only-built-dependencies-file:Only built dependencies file"
      "optimistic-repeat-install:Optimistic repeat install"
      "package-import-method:Package import method"
      "package-manager-strict:Package manager strict"
      "package-manager-strict-version:Package manager strict version"
      "prefer-frozen-lockfile:Prefer frozen lockfile"
      "prefer-offline:Prefer offline"
      "prefer-symlinked-executables:Prefer symlinked executables"
      "prefer-workspace-packages:Prefer workspace packages"
      "prefix:Installation prefix"
      "prod:Production mode"
      "provenance:Provenance"
      "proxy:Proxy server"
      "public-hoist-pattern:Public hoist pattern"
      "publish-branch:Publish branch"
      "reporter:Reporter"
      "resolution-mode:Resolution mode"
      "resolve-peers-from-workspace-root:Resolve peers from workspace root"
      "save-exact:Save exact version"
      "save-prefix:Save prefix"
      "save-prod:Save to dependencies"
      "save-workspace-protocol:Save workspace protocol"
      "script-shell:Script shell"
      "shamefully-hoist:Shamefully hoist"
      "shared-workspace-lockfile:Shared workspace lockfile"
      "shell-emulator:Shell emulator"
      "side-effects-cache:Side effects cache"
      "strict-peer-dependencies:Strict peer dependencies"
      "symlink:Symlink"
      "tag:Package tag"
      "timezone:Timezone"
      "umask:Umask"
      "update-notifier:Update notifier"
      "use-beta-cli:Use beta CLI"
      "use-inline-specifiers-lockfile-format:Use inline specifiers lockfile"
      "use-node-version:Use Node version"
      "use-running-store-server:Use running store server"
      "use-store-server:Use store server"
      "verify-store-integrity:Verify store integrity"
      "virtual-store-dir:Virtual store directory"
      "virtual-store-dir-max-length:Virtual store dir max length"
      "wanted-managers:Wanted package managers"
      "workspace-root:Workspace root"
    )
    _describe -t configs "config keys" configs
  }
  
  # Complete catelog dependencies
  _pnpm_catalog_deps() {
    local workspace_yaml="$PWD/pnpm-workspace.yaml"
    [[ -f "$workspace_yaml" ]] || return
    
    local -a catalog_deps
    catalog_deps=(${(f)"$(cat "$workspace_yaml" | python3 -c '
import yaml, sys
try:
    data = yaml.safe_load(sys.stdin)
    catalog = data.get("catalog", {})
    for name, spec in catalog.items():
        print(f"{name}:{spec}")
    # Also check catalog-by-name
    for cat_name, deps in data.get("catalog-by-name", {}).items():
        for name, spec in deps.items():
            print(f"{name}:{spec} [{cat_name}]")
except:
    pass' 2>/dev/null)"})
    
    _describe -t catalog "catalog dependencies" catalog_deps
  }
  
  # Main pnpm completion function
  _pnpm_completion() {
    local curcontext="$curcontext" state line
    typeset -A opt_args
    
    local -a pnpm_cmds=(
      "add:Add packages to dependencies"
      "audit:Check for security vulnerabilities"
      "bin:Print the path to the executables directory"
      "bug:Open package issue tracker in browser"
      "cache:Manage cache"
      "config:Manage configuration"
      "create:Create a project from a starter kit"
      "dedupe:Remove redundant dependencies"
      "deploy:Deploy a package from workspace"
      "dev:Run dev script"
      "dlx:Fetch and execute a package"
      "doctor:Check installation for known issues"
      "env:Manage Node.js versions"
      "exec:Execute a command in the context of a package"
      "fetch:Fetch packages to store for offline use"
      "init:Create a package.json file"
      "install:Install dependencies"
      "install-test:Install and run tests"
      "licenses:Check licenses"
      "link:Link local packages"
      "list:List installed packages"
      "login:Login to registry"
      "logout:Logout from registry"
      "outdated:Check for outdated packages"
      "pack:Create a tarball"
      "patch:Create a patch for a package"
      "patch-commit:Commit a patch"
      "patch-remove:Remove a patch"
      "prune:Remove unused packages"
      "publish:Publish a package"
      "rebuild:Rebuild a package"
      "remove:Remove packages"
      "rename:Rename a package"
      "restart:Restart a package"
      "root:Print the effective modules directory"
      "run:Run a package script"
      "self-update:Update pnpm"
      "server:Manage store server"
      "setup:Setup pnpm"
      "start:Start a package"
      "stop:Stop a package"
      "store:Manage the store"
      "test:Test a package"
      "unlink:Unlink a local package"
      "update:Update packages"
      "version:Bump package version"
      "view:View package info"
      "why:Show why a package is installed"
    )
    
    _arguments -C \
      '(-h --help)'{-h,--help}'[Show help]' \
      '(-v --version)'{-v,--version}'[Show version]' \
      '--filter[Filter packages]:filter:_pnpm_filters' \
      '--global[Global installation]' \
      '--recursive[Recursive execution]' \
      '--workspace[Workspace execution]' \
      '1: :->command' \
      '*:: :->args'
    
    case "$state" in
      command)
        _describe -t commands "pnpm commands" pnpm_cmds
        _pnpm_binaries
        ;;
      args)
        case "$line[1]" in
          run|r)
            _pnpm_scripts
            ;;
          filter)
            _pnpm_filters
            ;;
          add|install|i|remove|rm|update|upgrade|list|ls|ll|why|outdated|rebuild|prune|audit)
            _pnpm_packages
            ;;
          config|get|set)
            _pnpm_config_keys
            ;;
          exec|x|dlx|create)
            _npm_packages
            ;;
          store)
            local -a store_cmds=("add:Add packages" "path:Print store path" "prune:Remove unused packages" "status:Check store status")
            _describe -t store_cmds "store commands" store_cmds
            _pnpm_store_packages
            ;;
          cache)
            local -a cache_cmds=("clear:Clear cache" "dir:Print cache directory")
            _describe -t cache_cmds "cache commands" cache_cmds
            ;;
          env)
            local -a env_cmds=("use:Use Node version" "list:List versions" "list-available:List available")
            _describe -t env_cmds "env commands" env_cmds
            ;;
          patch)
            _pnpm_packages
            ;;
          deploy)
            _pnpm_workspaces
            ;;
          *)
            _files
            ;;
        esac
        ;;
    esac
  }
  
  compdef _pnpm_completion pnpm
  
  # ============================================================================
  # PNPM ALIASES
  # ============================================================================
  
  alias pn='pnpm'
  alias pna='pnpm add'
  alias pnad='pnpm add --save-dev'
  alias pnap='pnpm add --save-peer'
  alias pnao='pnpm add --save-optional'
  alias pnae='pnpm add --save-exact'
  alias pnb='pnpm build'
  alias pnc='pnpm create'
  alias pnd='pnpm dev'
  alias pne='pnpm exec'
  alias pnf='pnpm format'
  alias png='pnpm add -g'
  alias pnh='pnpm help'
  alias pni='pnpm init'
  alias pnin='pnpm install'
  alias pnip='pnpm install --prod'
  alias pnl='pnpm lint'
  alias pnlf='pnpm lint --fix'
  alias pnlx='pnpm dlx'
  alias pnp='pnpm publish'
  alias pnpub='pnpm publish'
  alias pnr='pnpm run'
  alias pnrb='pnpm run build'
  alias pnrd='pnpm run dev'
  alias pnrs='pnpm run start'
  alias pnrt='pnpm run test'
  alias pnrm='pnpm remove'
  alias pns='pnpm start'
  alias pnst='pnpm store'
  alias pnsv='pnpm serve'
  alias pnt='pnpm test'
  alias pnu='pnpm update'
  alias pnui='pnpm update --interactive'
  alias pnun='pnpm uninstall'
  alias pnv='pnpm version'
  alias pnw='pnpm workspace'
  alias pnws='pnpm workspaces'
  alias pnx='pnpm exec'
  
  # Filter aliases for monorepos
  alias pnfw='pnpm --filter'
  alias pnfr='pnpm --filter="./**"'
  alias pnfm='pnpm --filter=...'
  
  # Recursive aliases
  alias pnR='pnpm --recursive'
  alias pnRa='pnpm --recursive add'
  alias pnRrm='pnpm --recursive remove'
  alias pnRr='pnpm --recursive run'
  
  # ============================================================================
  # UTILITY FUNCTIONS
  # ============================================================================
  
  # Run a command in all workspace packages that have changed
  pnpm-changed() {
    local cmd="${1:-build}"
    pnpm --filter='...[HEAD~1]' run "$cmd"
  }
  
  # Run a command in all workspace packages
  pnpm-all() {
    local cmd="${1:-build}"
    pnpm --recursive run "$cmd"
  }
  
  # List all workspace packages
  pnpm-workspaces() {
    pnpm recursive list --depth=0 2>/dev/null || pnpm ls --depth=0
  }
  
  # Clean pnpm store and caches
  pnpm-deep-clean() {
    echo "Removing node_modules..."
    rm -rf node_modules
    echo "Pruning store..."
    pnpm store prune
    echo "Installing fresh..."
    pnpm install
  }
  
  # Find which package owns a dependency
  pnpm-why-all() {
    local pkg="$1"
    [[ -z "$pkg" ]] && { echo "Usage: pnpm-why-all <package>"; return 1 }
    pnpm --recursive why "$pkg"
  }
  
  # Update all dependencies interactively
  pnpm-update-all() {
    pnpm --recursive update --interactive
  }
  
  # Check all packages for outdated dependencies
  pnpm-outdated-all() {
    pnpm --recursive outdated
  }
  
  # Run lint in all packages
  pnpm-lint-all() {
    pnpm --recursive run lint
  }
  
  # Run tests in all packages
  pnpm-test-all() {
    pnpm --recursive run test
  }
  
  # Build all packages in dependency order
  pnpm-build-all() {
    pnpm --filter=./** run build
  }
  
  # Quick setup for a new monorepo
  pnpm-init-workspace() {
    [[ -f "pnpm-workspace.yaml" ]] && { echo "Workspace already exists"; return 1 }
    
    cat > pnpm-workspace.yaml <<'EOF'
packages:
  - 'apps/*'
  - 'packages/*'
EOF
    
    mkdir -p apps packages
    
    echo "Created pnpm-workspace.yaml with apps/* and packages/*"
    echo "Run 'pnpm init' to create root package.json"
  }
}
