# Enhanced npm completions with package.json script and workspace support
# ============================================================================

(( $+commands[npm] )) && {
  command rm -f "${ZSH_CACHE_DIR:-$ZSH/cache}/npm_completion"

  # ============================================================================
  # NPM SCRIPT COMPLETIONS
  # ============================================================================
  
  # Complete npm scripts from package.json
  _npm_scripts() {
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
    
    _describe -t scripts "npm scripts" scripts
  }
  
  # Complete npm workspaces
  _npm_workspaces() {
    local package_json="$PWD/package.json"
    [[ -f "$package_json" ]] || return
    
    # Check for workspaces field
    local -a workspaces
    workspaces=(${(f)"$(cat "$package_json" | python3 -c '
import json, sys, os, glob
try:
    data = json.load(sys.stdin)
    ws = data.get("workspaces", [])
    if isinstance(ws, dict):
        ws = ws.get("packages", [])
    for pattern in ws:
        # Expand glob patterns
        for path in glob.glob(pattern):
            if os.path.isdir(path) and os.path.exists(os.path.join(path, "package.json")):
                pkg = json.load(open(os.path.join(path, "package.json")))
                name = pkg.get("name", path)
                print(f"{name}:{path}")
except:
    pass' 2>/dev/null)"})
    
    _describe -t workspaces "workspaces" workspaces
  }
  
  # Complete installed packages from node_modules
  _npm_packages() {
    local -a packages
    if [[ -d node_modules ]]; then
      packages=($(ls -1 node_modules 2>/dev/null | grep -v "^\.")
                $(ls -1 node_modules/@* 2>/dev/null | tr '\n' ' '))
    fi
    
    # Also add packages from package.json dependencies
    local package_json="$PWD/package.json"
    if [[ -f "$package_json" ]]; then
      local deps=(${(f)"$(cat "$package_json" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    deps = list(data.get("dependencies", {}).keys())
    deps += list(data.get("devDependencies", {}).keys())
    deps += list(data.get("peerDependencies", {}).keys())
    deps += list(data.get("optionalDependencies", {}).keys())
    for d in deps:
        print(d)
except:
    pass' 2>/dev/null)"})
      packages+=($deps)
    fi
    
    _describe -t packages "packages" packages
  }
  
  # Complete .bin commands
  _npm_binaries() {
    local -a binaries
    if [[ -d node_modules/.bin ]]; then
      binaries=($(ls -1 node_modules/.bin 2>/dev/null))
    fi
    _describe -t binaries "binaries" binaries
  }
  
  # Complete npm config keys
  _npm_config_keys() {
    local -a configs=(
      "registry:npm registry URL"
      "scope:scope for scoped packages"
      "access:package access level"
      "always-auth:always require authentication"
      "auth-type:authentication type"
      "bin-links:create bin links"
      "browser:browser to open"
      "ca:certificate authority"
      "cache:cache directory"
      "color:color output"
      "depth:dependency depth"
      "dev:install dev dependencies"
      "editor:text editor"
      "engine-strict:strict engine checking"
      "fetch-retries:fetch retry count"
      "fetch-timeout:fetch timeout"
      "force:force actions"
      "fund:show funding message"
      "git:git binary"
      "global:global installation"
      "globalconfig:global config file"
      "global-style:global style installation"
      "heading:output heading"
      "https-proxy:HTTPS proxy"
      "if-present:run only if script present"
      "ignore-scripts:ignore lifecycle scripts"
      "init-author-email:init author email"
      "init-author-name:init author name"
      "init-author-url:init author URL"
      "init-license:init license"
      "init-module:init module"
      "init-version:init version"
      "json:JSON output"
      "legacy-bundling:legacy bundling"
      "legacy-peer-deps:legacy peer deps"
      "link:link packages"
      "local-address:local address"
      "loglevel:log level"
      "logs-max:max log files"
      "maxsockets:max sockets"
      "message:commit message"
      "node-options:Node.js options"
      "noproxy:no proxy hosts"
      "npm-version:npm version"
      "offline:offline mode"
      "omit:omit dependency types"
      "only:only install types"
      "optional:install optional deps"
      "pack-destination:pack destination"
      "package:package file"
      "package-lock:package lock file"
      "package-lock-only:only package lock"
      "parseable:parseable output"
      "prefer-offline:prefer offline"
      "prefer-online:prefer online"
      "prefix:installation prefix"
      "preid:prerelease identifier"
      "production:production mode"
      "progress:show progress"
      "proxy:proxy server"
      "read-only:read only"
      "rebuild-bundle:rebuild bundle"
      "save:save to dependencies"
      "save-bundle:save bundle"
      "save-dev:save to devDependencies"
      "save-exact:save exact version"
      "save-optional:save to optionalDependencies"
      "save-peer:save to peerDependencies"
      "save-prefix:save prefix"
      "save-prod:save to dependencies"
      "scope:package scope"
      "script-shell:script shell"
      "searchexclude:search exclude"
      "searchlimit:search limit"
      "searchopts:search options"
      "searchstaleness:search staleness"
      "shell:shell to use"
      "shrinkwrap:shrinkwrap file"
      "sign-git-commit:sign git commits"
      "sign-git-tag:sign git tags"
      "sso-poll-frequency:SSO poll frequency"
      "sso-type:SSO type"
      "strict-peer-deps:strict peer deps"
      "strict-ssl:strict SSL"
      "tag:package tag"
      "timing:timing info"
      "tmp:temp directory"
      "umask:umask value"
      "unicode:unicode output"
      "update-notifier:update notifier"
      "usage:show usage"
      "user-agent:user agent"
      "userconfig:user config file"
      "version:show version"
      "versions:show versions"
      "viewer:help viewer"
      "which:which command"
      "workspace:workspace name"
      "workspaces:enable workspaces"
      "workspaces-update:update workspace lockfile"
      "yes:yes to prompts"
    )
    _describe -t configs "config keys" configs
  }
  
  # Main npm completion function
  _npm_completion() {
    local curcontext="$curcontext" state line
    typeset -A opt_args
    
    local -a npm_cmds=(
      "access:Set access level on published packages"
      "adduser:Add a registry user account"
      "audit:Run a security audit"
      "bin:Display npm bin folder"
      "bugs:Show bugs for a package in a web browser"
      "cache:Manipulates package cache"
      "ci:Install a project with a clean slate"
      "completion:Tab completion for npm"
      "config:Manage the npm configuration files"
      "dedupe:Reduce duplication in the package tree"
      "deprecate:Deprecate a version of a package"
      "diff:Show diff of locally modified deps"
      "dist-tag:Modify package distribution tags"
      "docs:Docs for a package in a web browser"
      "doctor:Check your npm environment"
      "edit:Edit an installed package"
      "exec:Execute a package binary"
      "explain:Explain installed packages"
      "explore:Browse an installed package"
      "find-dupes:Find duplication in the package tree"
      "fund:Retrieve funding information"
      "get:Get a value from the npm config"
      "help:Get help on npm"
      "help-search:Search npm help documentation"
      "hook:Manage registry hooks"
      "init:Create a package.json file"
      "install:Install a package"
      "install-ci-test:Install deps and run tests"
      "install-test:Install package(s) and run tests"
      "link:Symlink a package folder"
      "login:Log in to a registry user account"
      "logout:Log out of the registry"
      "ls:List installed packages"
      "org:Manage orgs"
      "outdated:Check for outdated packages"
      "owner:Manage package owners"
      "pack:Create a tarball from a package"
      "ping:Ping npm registry"
      "pkg:Manage your package.json"
      "prefix:Display prefix"
      "profile:Change registry profile settings"
      "prune:Remove extraneous packages"
      "publish:Publish a package"
      "query:Query the dependency tree"
      "rebuild:Rebuild a package"
      "repo:Open package repository in browser"
      "restart:Restart a package"
      "root:Display npm root"
      "run-script:Run arbitrary package scripts"
      "search:Search for packages"
      "set:Set a value in the npm config"
      "set-script:Set tasks in the scripts section"
      "shrinkwrap:Lock dependency versions"
      "star:Mark your favorite packages"
      "stars:View packages marked as favorites"
      "start:Start a package"
      "stop:Stop a package"
      "team:Manage teams and team memberships"
      "test:Test a package"
      "token:Manage your authentication tokens"
      "uninstall:Remove a package"
      "unpublish:Remove a package from the registry"
      "unstar:Unmark a package as favorite"
      "update:Update a package"
      "version:Bump a package version"
      "view:View registry info"
      "whoami:Display npm username"
    )
    
    _arguments -C \
      '(-h --help)'{-h,--help}'[Show help]' \
      '(-v --version)'{-v,--version}'[Show version]' \
      '1: :->command' \
      '*:: :->args'
    
    case "$state" in
      command)
        _describe -t commands "npm commands" npm_cmds
        ;;
      args)
        case "$line[1]" in
          run|run-script)
            _npm_scripts
            ;;
          workspace|workspaces|ws)
            _npm_workspaces
            ;;
          install|i|add|uninstall|remove|rm|update|upgrade|list|ls|ll|why|explain|prune|dedupe|audit|outdated|fund)
            _npm_packages
            ;;
          config|get|set)
            _npm_config_keys
            ;;
          exec|x|npx)
            _npm_binaries
            _npm_packages
            ;;
          init|create)
            local -a create_starters=(
              "react-app:Create React App"
              "next-app:Next.js App"
              "vue:Vue.js project"
              "svelte:Svelte project"
              "angular:Angular project"
              "vite:Vite project"
              "astro:Astro project"
              "remix:Remix project"
              "nuxt:Nuxt.js project"
              "gatsby:Gatsby project"
              "expo:Expo project"
            )
            _describe -t starters "create starters" create_starters
            ;;
          *)
            _files
            ;;
        esac
        ;;
    esac
  }
  
  compdef _npm_completion npm
  
  # ============================================================================
  # NPM ALIASES
  # ============================================================================
  
  # Install dependencies globally
  alias npmg="npm i -g "
  
  # Install and save to dependencies in your package.json
  alias npmS="npm i -S "
  
  # Install and save to dev-dependencies in your package.json
  alias npmD="npm i -D "
  
  # Force npm to fetch remote resources even if a local copy exists on disk.
  alias npmF='npm i -f'
  
  # Execute command from node_modules folder based on current directory
  alias npmE='PATH="$(npm bin)":"$PATH"'
  
  # Check which npm modules are outdated
  alias npmO="npm outdated"
  
  # Update all the packages listed to the latest version
  alias npmU="npm update"
  
  # Check package versions
  alias npmV="npm -v"
  
  # List packages
  alias npmL="npm list"
  
  # List top-level installed packages
  alias npmL0="npm ls --depth=0"
  
  # Run npm start
  alias npmst="npm start"
  
  # Run npm test
  alias npmt="npm test"
  
  # Run npm scripts
  alias npmR="npm run"
  
  # Run npm publish
  alias npmP="npm publish"
  
  # Run npm init
  alias npmI="npm init"
  
  # Run npm info
  alias npmi="npm info"
  
  # Run npm search
  alias npmSe="npm search"
  
  # Run npm run dev
  alias npmrd="npm run dev"
  
  # Run npm run build
  alias npmrb="npm run build"
  
  # ============================================================================
  # ENHANCED ALIASES
  # ============================================================================
  
  # Quick npm init with defaults
  alias npmid="npm init -y"
  
  # Install and save exact version
  alias npmE="npm install --save-exact"
  
  # Clean npm cache
  alias npmcc="npm cache clean --force"
  
  # Deep list (show all deps)
  alias npmLa="npm list --all"
  
  # Show global packages
  alias npmLg="npm list -g --depth=0"
  
  # Audit fix
  alias npmfix="npm audit fix"
  
  # Audit fix with force
  alias npmfixf="npm audit fix --force"
  
  # Check for vulnerabilities
  alias npmsec="npm audit"
  
  # Run in workspace
  alias npmw="npm run --workspace"
  
  # Run in all workspaces
  alias npmws="npm run --workspaces"
  
  # Quick publish with access public
  alias npmpp="npm publish --access public"
  
  # View package info
  alias npmv="npm view"
  
  # Open package repository
  alias npmrepo="npm repo"
  
  # Open package docs
  alias npmdocs="npm docs"
  
  # Update global packages
  alias npmug="npm update -g"
  
  # Prune extraneous packages
  alias npmprune="npm prune"
  
  # Rebuild all packages
  alias npmrebuild="npm rebuild"
  
  # Check for outdated deps (fund)
  alias npmfund="npm fund"
  
  # Link local package
  alias npmlink="npm link"
  
  # Unlink local package
  alias npmunlink="npm unlink"
  
  # Execute package binary
  alias npmx="npx"
  
  # ============================================================================
  # UTILITY FUNCTIONS
  # ============================================================================
  
  npm_toggle_install_uninstall() {
    # Look up to the previous 2 history commands
    local line
    for line in "$BUFFER" \
      "${history[$((HISTCMD-1))]}" \
      "${history[$((HISTCMD-2))]}"
    do
      case "$line" in
        "npm uninstall"*)
          BUFFER="${line/npm uninstall/npm install}"
          (( CURSOR = CURSOR + 2 ))
          ;;
        "npm install"*)
          BUFFER="${line/npm install/npm uninstall}"
          (( CURSOR = CURSOR + 2 ))
          ;;
        "npm un "*)
          BUFFER="${line/npm un/npm install}"
          (( CURSOR = CURSOR + 5 ))
          ;;
        "npm i "*)
          BUFFER="${line/npm i/npm uninstall}"
          (( CURSOR = CURSOR + 8 ))
          ;;
        *) continue ;;
      esac
      return 0
    done
  
    BUFFER="npm install"
    CURSOR=${#BUFFER}
  }
  
  zle -N npm_toggle_install_uninstall
  
  # Defined shortcut keys: [F2] [F2]
  bindkey -M emacs '^[OQ^[OQ' npm_toggle_install_uninstall
  bindkey -M vicmd '^[OQ^[OQ' npm_toggle_install_uninstall
  bindkey -M viins '^[OQ^[OQ' npm_toggle_install_uninstall
}
