# GitHub CLI (gh) - Comprehensive completions
# Enhanced with context-aware dynamic completions

if (( ! $+commands[gh] )); then
  return
fi

# ============================================================
# CACHE AND STATE MANAGEMENT
# ============================================================

_gh_cache_dir="${ZSH_CACHE_DIR}/gh"
mkdir -p "$_gh_cache_dir"

# Get repositories for current user/org
_gh_repos() {
  local cache_file="$_gh_cache_dir/repos"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gh repo list --limit 100 --json name,description,pushedAt -q '.[] | "\(.name):\(.description // "") [\(.pushedAt | split("T")[0])]"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get issues for current repo
_gh_issues() {
  local cache_file="$_gh_cache_dir/issues"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    gh issue list --limit 50 --json number,title,state -q '.[] | "\(.number):\(.title) [\(.state)]"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get PRs for current repo
_gh_prs() {
  local cache_file="$_gh_cache_dir/prs"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    gh pr list --limit 50 --json number,title,author -q '.[] | "\(.number):\(.title) by @\(.author.login)"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get branches
_gh_branches() {
  git branch -a --format '%(refname:short)' 2>/dev/null | sed 's|^remotes/||' | sort -u
}

# Get workflows
_gh_workflows() {
  local cache_file="$_gh_cache_dir/workflows"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gh workflow list --json name,id -q '.[] | "\(.id):\(.name)"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get codespaces
_gh_codespaces() {
  local cache_file="$_gh_cache_dir/codespaces"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    gh codespace list --json name,repository,state -q '.[] | "\(.name):\(.repository) [\(.state)]"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get releases
_gh_releases() {
  local cache_file="$_gh_cache_dir/releases"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gh release list --json tagName,name -q '.[] | "\(.tagName):\(.name)"' 2>/dev/null | head -20 >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get gists
_gh_gists() {
  local cache_file="$_gh_cache_dir/gists"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gh gist list --limit 30 --json id,description -q '.[] | "\(.id):\(.description)"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get labels
_gh_labels() {
  local cache_file="$_gh_cache_dir/labels"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gh label list --json name,description -q '.[] | "\(.name):\(.description)"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get extensions
_gh_extensions() {
  local cache_file="$_gh_cache_dir/extensions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gh extension list --json name,repo -q '.[] | "\(.name):\(.repo)"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get secrets
_gh_secrets() {
  local cache_file="$_gh_cache_dir/secrets"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gh secret list --json name -q '.[] | "\(.name)"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get variables
_gh_variables() {
  local cache_file="$_gh_cache_dir/variables"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gh variable list --json name -q '.[] | "\(.name)"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get run IDs
_gh_runs() {
  local cache_file="$_gh_cache_dir/runs"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    gh run list --limit 20 --json databaseId,workflowName,status -q '.[] | "\(.databaseId):\(.workflowName) [\(.status)]"' 2>/dev/null >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# ============================================================
# MAIN COMPLETION FUNCTION
# ============================================================

_gh_enhanced() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # First level - main commands
  if (( CURRENT == 2 )); then
    if [[ "$cur" == -* ]]; then
      _gh_global_options
    else
      local commands=(
        # Core
        'auth:Authenticate gh and git'
        'browse:Open repository in browser'
        'codespace:Connect to and manage codespaces'
        'gist:Manage gists'
        'issue:Manage issues'
        'org:Manage organizations'
        'pr:Manage pull requests'
        'project:Work with GitHub Projects'
        'release:Manage releases'
        'repo:Manage repositories'
        # Actions
        'cache:Manage GitHub Actions caches'
        'run:View workflow runs'
        'workflow:View workflows'
        # Additional
        'alias:Create command shortcuts'
        'api:Make authenticated API requests'
        'attestation:Work with attestations'
        'completion:Generate shell completions'
        'config:Manage configuration'
        'extension:Manage extensions'
        'gpg-key:Manage GPG keys'
        'label:Manage labels'
        'ruleset:View repo rulesets'
        'search:Search repos, issues, PRs'
        'secret:Manage GitHub secrets'
        'ssh-key:Manage SSH keys'
        'status:Print status across repos'
        'variable:Manage GitHub Actions variables'
      )
      _describe -t commands "gh commands" commands
    fi
    return
  fi
  
  local cmd=$words[2]
  
  # Complete based on subcommand
  case "$cmd" in
    repo)
      _gh_repo_completion
      ;;
    pr)
      _gh_pr_completion
      ;;
    issue)
      _gh_issue_completion
      ;;
    run)
      _gh_run_completion
      ;;
    workflow)
      _gh_workflow_completion
      ;;
    release)
      _gh_release_completion
      ;;
    gist)
      _gh_gist_completion
      ;;
    codespace)
      _gh_codespace_completion
      ;;
    secret)
      _gh_secret_completion
      ;;
    variable)
      _gh_variable_completion
      ;;
    label)
      _gh_label_completion
      ;;
    cache)
      _gh_cache_completion
      ;;
    auth)
      _gh_auth_completion
      ;;
    config)
      _gh_config_completion
      ;;
    extension)
      _gh_extension_completion
      ;;
    alias)
      _gh_alias_completion
      ;;
    api)
      _gh_api_completion
      ;;
    search)
      _gh_search_completion
      ;;
    browse)
      _gh_browse_completion
      ;;
    *)
      _files
      ;;
  esac
}

_gh_global_options() {
  local -a options
  options=(
    '(-h --help)'{-h,--help}'[Show help]'
    '--version[Show version]'
  )
  _describe -t options "gh options" options
}

# Repository completions
_gh_repo_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'clone:Clone a repository'
      'create:Create a repository'
      'delete:Delete a repository'
      'deploy-key:Manage deploy keys'
      'edit:Edit repository settings'
      'fork:Create a fork'
      'list:List repositories'
      'rename:Rename a repository'
      'sync:Sync a repository'
      'view:View a repository'
    )
    _describe -t commands "repo commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    clone)
      _arguments \
        '--depth[Clone depth]:depth:' \
        '--[Pass flags to git clone]' \
        '*:repo:_gh_repos'
      ;;
    fork)
      _arguments \
        '--clone[Clone after forking]' \
        '--default-branch-only[Only default branch]' \
        '--description[Description]:desc:' \
        '--name[New name]:name:' \
        '--remote[Add remote]:remote:' \
        '--org[Organization]:org:' \
        '*:repo:_gh_repos'
      ;;
    delete|edit|rename|sync|view)
      _arguments \
        '(-y --yes)'{-y,--yes}'[Skip confirmation]' \
        ':repo:_gh_repos'
      ;;
    create)
      _arguments \
        '--add-readme[Add README]' \
        '--clone[Clone after creation]' \
        '--default-branch[Branch name]:branch:' \
        '--description[Description]:desc:' \
        '--disable-issues[Disable issues]' \
        '--disable-wiki[Disable wiki]' \
        '--gitignore[Gitignore template]:template:' \
        '--homepage[Homepage URL]:url:' \
        '--internal[Internal visibility]' \
        '--license[License]:license:' \
        '--private[Private visibility]' \
        '--public[Public visibility]' \
        '--push[Push local to new repo]' \
        '--remote[Remote name]:remote:' \
        '--source[Source path]:path:_files -/' \
        '--team[Team]:team:' \
        '--template[Template repo]:repo:_gh_repos' \
        ':name:'
      ;;
    deploy-key)
      if (( CURRENT == 4 )); then
        local dk_commands=(
          'add:Add deploy key'
          'delete:Delete deploy key'
          'list:List deploy keys'
        )
        _describe -t commands "deploy-key commands" dk_commands
      fi
      ;;
  esac
}

# PR completions
_gh_pr_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'checkout:Check out a PR locally'
      'checks:Show CI status'
      'close:Close PRs'
      'comment:Add a comment'
      'create:Create a PR'
      'diff:View changes'
      'edit:Edit a PR'
      'list:List PRs'
      'merge:Merge PRs'
      'ready:Mark ready for review'
      'reopen:Reopen PRs'
      'review:Add review'
      'status:Show PR status'
      'update-branch:Update branch'
      'view:View a PR'
    )
    _describe -t commands "pr commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    checkout|co)
      _arguments \
        '--branch[Local branch name]:branch:_gh_branches' \
        '--detach[Checkout detached]' \
        '--force[Force checkout]' \
        '--recurse-submodules[Update submodules]' \
        '*:pr:_gh_prs'
      ;;
    close|edit|merge|ready|reopen|view)
      _arguments \
        '(-y --yes)'{-y,--yes}'[Skip confirmation]' \
        '*:pr:_gh_prs'
      ;;
    checks)
      _arguments \
        '--fail-on-error[Exit 1 if checks fail]' \
        '--interval[Refresh interval]:seconds:' \
        '--watch[Watch checks]' \
        '*:pr:_gh_prs'
      ;;
    comment)
      _arguments \
        '(-b --body)'{-b,--body}'[Comment body]:body:' \
        '(-e --edit)'{-e,--edit}'[Edit last comment]' \
        '*:pr:_gh_prs'
      ;;
    create)
      _arguments \
        '(-a --assignee)'{-a,--assignee}'[Assignees]:assignees:' \
        '(-B --base)'{-B,--base}'[Base branch]:branch:_gh_branches' \
        '(-b --body)'{-b,--body}'[Body]:body:' \
        '--body-file[Body file]:file:_files' \
        '(-d --draft)'{-d,--draft}'[Create as draft]' \
        '--fill[Use commit info for title/body]' \
        '--fill-first[Use first commit only]' \
        '--head[Head branch]:branch:_gh_branches' \
        '--label[Labels]:labels:_gh_labels' \
        '--milestone[Milestone]:milestone:' \
        '--no-maintainer-edit[Disable maintainer edit]' \
        '--project[Project]:project:' \
        '--recover[Recover from failed push]' \
        '--reviewer[Reviewers]:reviewers:' \
        '--template[Template file]:file:_files' \
        '(-t --title)'{-t,--title}'[Title]:title:' \
        '--web[Open in browser]' \
        ':title: '
      ;;
    diff)
      _arguments \
        '--color[Color]:when:(always never auto)' \
        '--name-only[Names only]' \
        '--patch[Show patch]' \
        '*:pr:_gh_prs'
      ;;
    list)
      _arguments \
        '(-a --assignee)'{-a,--assignee}'[Filter by assignee]:assignee:' \
        '(-A --author)'{-A,--author}'[Filter by author]:author:' \
        '(-B --base)'{-B,--base}'[Filter by base]:branch:_gh_branches' \
        '(-H --head)'{-H,--head}'[Filter by head]:branch:_gh_branches' \
        '--draft[Filter by draft]' \
        '(-h --jq)'{-h,--jq}'[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '(-l --label)'{-l,--label}'[Filter by label]:label:_gh_labels' \
        '--limit[Maximum]:limit:' \
        '--state[Filter by state]:state:(open closed merged all)' \
        '--template[Format template]:template:' \
        '(-w --web)'{-w,--web}'[Open in browser]' \
        '*:pr:_gh_prs'
      ;;
    review)
      _arguments \
        '(-a --approve)'{-a,--approve}'[Approve PR]' \
        '(-b --body)'{-b,--body}'[Review body]:body:' \
        '--body-file[Body file]:file:_files' \
        '(-c --comment)'{-c,--comment}'[Comment on PR]' \
        '--request-changes[Request changes]' \
        '*:pr:_gh_prs'
      ;;
    status)
      _arguments \
        '--conflict-status[Conflict status]' \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--template[Format template]:template:'
      ;;
    update-branch)
      _arguments \
        '--rebase[Rebase instead of merge]' \
        '*:pr:_gh_prs'
      ;;
  esac
}

# Issue completions
_gh_issue_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'close:Close issues'
      'comment:Add comment'
      'create:Create issue'
      'delete:Delete issues'
      'develop:Manage linked branches'
      'edit:Edit issues'
      'list:List issues'
      'pin:Pin issues'
      'reopen:Reopen issues'
      'status:Show status'
      'transfer:Transfer issues'
      'unpin:Unpin issues'
      'view:View issue'
    )
    _describe -t commands "issue commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    close|delete|edit|reopen|view)
      _arguments \
        '(-R --repo)'{-R,--repo}'[Repository]:repo:_gh_repos' \
        '(-y --yes)'{-y,--yes}'[Skip confirmation]' \
        '*:issue:_gh_issues'
      ;;
    comment)
      _arguments \
        '(-b --body)'{-b,--body}'[Body]:body:' \
        '(-e --edit)'{-e,--edit}'[Edit last]' \
        '*:issue:_gh_issues'
      ;;
    create)
      _arguments \
        '(-a --assignee)'{-a,--assignee}'[Assignees]:assignees:' \
        '(-b --body)'{-b,--body}'[Body]:body:' \
        '--body-file[Body file]:file:_files' \
        '--label[Labels]:labels:_gh_labels' \
        '--milestone[Milestone]:milestone:' \
        '--project[Project]:project:' \
        '--recover[Recover file]:file:_files' \
        '--template[Template]:template:' \
        '(-t --title)'{-t,--title}'[Title]:title:' \
        '--web[Open in browser]' \
        ':title: '
      ;;
    develop)
      _arguments \
        '(-b --base)'{-b,--base}'[Base branch]:branch:_gh_branches' \
        '(-c --checkout)'{-c,--checkout}'[Checkout branch]' \
        '--name[Branch name]:name:' \
        '*:issue:_gh_issues'
      ;;
    list)
      _arguments \
        '(-a --assignee)'{-a,--assignee}'[Filter by assignee]:assignee:' \
        '(-A --author)'{-A,--author}'[Filter by author]:author:' \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '(-l --label)'{-l,--label}'[Filter by label]:label:_gh_labels' \
        '--limit[Maximum]:limit:' \
        '--mention[Filter by mention]' \
        '--milestone[Filter by milestone]:milestone:' \
        '--search[Search with query]:query:' \
        '--state[Filter by state]:state:(open closed all)' \
        '--template[Format template]:template:' \
        '*:issue:_gh_issues'
      ;;
    pin|unpin)
      _arguments \
        '*:issue:_gh_issues'
      ;;
    status)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--template[Format template]:template:'
      ;;
    transfer)
      _arguments \
        ':issue:_gh_issues' \
        ':destination-repo:_gh_repos'
      ;;
  esac
}

# Run completions
_gh_run_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'cancel:Cancel a workflow run'
      'delete:Delete a workflow run'
      'download:Download artifacts'
      'list:List workflow runs'
      'rerun:Rerun a workflow run'
      'view:View a workflow run'
      'watch:Watch a run'
    )
    _describe -t commands "run commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    cancel|delete|rerun|view|watch)
      _arguments \
        '*:run:_gh_runs'
      ;;
    download)
      _arguments \
        '(-D --dir)'{-D,--dir}'[Destination]:dir:_files -/' \
        '(-n --name)'{-n,--name}'[Artifact name]:name:' \
        '*:run:_gh_runs'
      ;;
    list)
      _arguments \
        '(-b --branch)'{-b,--branch}'[Filter by branch]:branch:_gh_branches' \
        '(-e --event)'{-e,--event}'[Filter by event]:event:' \
        '(-c --commit)'{-c,--commit}'[Filter by commit]:commit:' \
        '--created[Filter by created]:date:' \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--limit[Maximum]:limit:' \
        '(-s --status)'{-s,--status}'[Filter by status]:status:(completed action_required cancelled failure in_progress neutral queued skipped stale starting success timed_out waiting)' \
        '--template[Format template]:template:' \
        '(-u --user)'{-u,--user}'[Filter by user]:user:' \
        '(-w --workflow)'{-w,--workflow}'[Filter by workflow]:workflow:_gh_workflows'
      ;;
  esac
}

# Workflow completions
_gh_workflow_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'disable:Disable a workflow'
      'enable:Enable a workflow'
      'list:List workflows'
      'run:Run a workflow'
      'view:View a workflow'
    )
    _describe -t commands "workflow commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    disable|enable|view)
      _arguments \
        '(-y --yes)'{-y,--yes}'[Skip confirmation]' \
        '*:workflow:_gh_workflows'
      ;;
    list)
      _arguments \
        '(-a --all)'{-a,--all}'[Show all]' \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--limit[Maximum]:limit:' \
        '--template[Format template]:template:'
      ;;
    run)
      _arguments \
        '(-f --field)'{-f,--field}'[Input field]:field:' \
        '--json[Read inputs from JSON]:json:' \
        '--raw-field[Input field]:field:' \
        '(-r --ref)'{-r,--ref}'[Branch or tag]:ref:_gh_branches' \
        '--silent[Silent]' \
        '--watch[Watch run]' \
        '*:workflow:_gh_workflows'
      ;;
  esac
}

# Release completions
_gh_release_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'create:Create release'
      'delete:Delete release'
      'delete-asset:Delete asset'
      'download:Download assets'
      'edit:Edit release'
      'list:List releases'
      'upload:Upload assets'
      'view:View release'
    )
    _describe -t commands "release commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    create)
      _arguments \
        '--discussion-category[Discussion category]:category:' \
        '(-d --draft)'{-d,--draft}'[Draft release]' \
        '--generate-notes[Auto-generate notes]' \
        '--notes[Release notes]:notes:' \
        '--notes-file[Notes file]:file:_files' \
        '--notes-from-tag[Use tag message]' \
        '--notes-start-tag[Starting tag]:tag:' \
        '--prerelease[Mark as prerelease]' \
        '(-p --publish)'{-p,--publish}'[Publish]' \
        '--target[Target branch/commit]:target:' \
        '(-t --title)'{-t,--title}'[Title]:title:' \
        '--verify-tag[Verify tag exists]' \
        '*:tag:_gh_releases'
      ;;
    delete|edit|view)
      _arguments \
        '(-y --yes)'{-y,--yes}'[Skip confirmation]' \
        '*:release:_gh_releases'
      ;;
    delete-asset|download|upload)
      _arguments \
        '*:release:_gh_releases' \
        '*:file:_files'
      ;;
    list)
      _arguments \
        '--exclude-drafts[Exclude drafts]' \
        '--exclude-pre-releases[Exclude prereleases]' \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--limit[Maximum]:limit:' \
        '--template[Format template]:template:'
      ;;
  esac
}

# Gist completions
_gh_gist_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'clone:Clone a gist'
      'create:Create gist'
      'delete:Delete gists'
      'edit:Edit a gist'
      'list:List gists'
      'rename:Rename file'
      'view:View gist'
    )
    _describe -t commands "gist commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    clone|delete|edit|rename|view)
      _arguments \
        '*:gist:_gh_gists'
      ;;
    create)
      _arguments \
        '(-d --desc)'{-d,--desc}'[Description]:desc:' \
        '(-f --filename)'{-f,--filename}'[Filename]:filename:' \
        '--public[Make public]' \
        '(-w --web)'{-w,--web}'[Open in browser]' \
        '*:file:_files'
      ;;
    list)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--limit[Maximum]:limit:' \
        '--public[Public only]' \
        '--secret[Secret only]' \
        '--template[Format template]:template:'
      ;;
  esac
}

# Codespace completions
_gh_codespace_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'code:Open in VS Code'
      'cp:Copy files'
      'create:Create codespace'
      'delete:Delete codespaces'
      'edit:Edit codespace'
      'jupyupyter:Open in JupyterLab'
      'list:List codespaces'
      'logs:View logs'
      'ports:Manage ports'
      'rebuild:Rebuild codespace'
      'ssh:SSH into codespace'
      'stop:Stop codespaces'
      'view:View codespace'
    )
    _describe -t commands "codespace commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    code|cp|delete|edit|jupyter|logs|rebuild|ssh|stop|view)
      _arguments \
        '(-c --codespace)'{-c,--codespace}'[Codespace]:codespace:_gh_codespaces' \
        '*:codespace:_gh_codespaces'
      ;;
    create)
      _arguments \
        '(-b --branch)'{-b,--branch}'[Branch]:branch:_gh_branches' \
        '--default-permissions[Default permissions]' \
        '--devcontainer-path[Devcontainer path]:path:_files' \
        '--idle-timeout[Idle timeout]:minutes:' \
        '--machine[Machine type]:machine:' \
        '(-r --repo)'{-r,--repo}'[Repository]:repo:_gh_repos' \
        '--retention-period[Retention days]:days:' \
        '--status[Wait for completion]' \
        '--wait[Wait for completion]'
      ;;
    list)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--limit[Maximum]:limit:' \
        '--org[Organization]:org:' \
        '--repo[Repository]:repo:_gh_repos' \
        '--template[Format template]:template:' \
        '--user[User]:user:'
      ;;
    ports)
      if (( CURRENT == 4 )); then
        local port_commands=(
          'forward:Forward port'
          'visibility:Set visibility'
        )
        _describe -t commands "ports commands" port_commands
      else
        _arguments \
          ':codespace:_gh_codespaces'
      fi
      ;;
  esac
}

# Secret completions
_gh_secret_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'list:List secrets'
      'remove:Remove secrets'
      'set:Set secrets'
    )
    _describe -t commands "secret commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    list)
      _arguments \
        '--app[App]:app:' \
        '--env[Environment]:env:' \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--org[Organization]:org:' \
        '(-e --env)'{-e,--env}'[Environment]:env:' \
        '--template[Format template]:template:'
      ;;
    remove)
      _arguments \
        '--app[App]:app:' \
        '--env[Environment]:env:' \
        '--org[Organization]:org:' \
        '--user[User]:user:' \
        '*:secret:_gh_secrets'
      ;;
    set)
      _arguments \
        '--app[App]:app:' \
        '--body[Secret body]:body:' \
        '--env[Environment]:env:' \
        '--no-store[Print without storing]' \
        '--org[Organization]:org:' \
        '--repos[Repositories]:repos:_gh_repos' \
        '--user[User]:user:' \
        '--visibility[Visibility]:visibility:(all private selected)' \
        '*:secret: '
      ;;
  esac
}

# Variable completions
_gh_variable_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'list:List variables'
      'remove:Remove variables'
      'set:Set variables'
    )
    _describe -t commands "variable commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    list)
      _arguments \
        '--env[Environment]:env:' \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--org[Organization]:org:' \
        '--template[Format template]:template:'
      ;;
    remove)
      _arguments \
        '--env[Environment]:env:' \
        '--org[Organization]:org:' \
        '*:variable:_gh_variables'
      ;;
    set)
      _arguments \
        '--body[Variable body]:body:' \
        '--env[Environment]:env:' \
        '--org[Organization]:org:' \
        '*:variable: '
      ;;
  esac
}

# Label completions
_gh_label_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'clone:Clone labels'
      'create:Create label'
      'delete:Delete label'
      'edit:Edit label'
      'list:List labels'
    )
    _describe -t commands "label commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    clone)
      _arguments \
        '--force[Overwrite existing]' \
        '--source-repo[Source]:repo:_gh_repos' \
        ':repo:_gh_repos'
      ;;
    create)
      _arguments \
        '(-c --color)'{-c,--color}'[Color]:color:' \
        '(-d --description)'{-d,--description}'[Description]:desc:' \
        '--force[Overwrite]' \
        ':name:'
      ;;
    delete|edit)
      _arguments \
        '(-y --yes)'{-y,--yes}'[Skip confirmation]' \
        '--description[Description]:desc:' \
        '--name[New name]:name:' \
        '*:label:_gh_labels'
      ;;
    list)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--limit[Maximum]:limit:' \
        '--order[Order]:order:(asc desc)' \
        '--search[Search]:query:' \
        '--sort[Sort]:sort:(created name)' \
        '--template[Format template]:template:'
      ;;
  esac
}

# Cache completions
_gh_cache_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'delete:Delete caches'
      'list:List caches'
    )
    _describe -t commands "cache commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    delete)
      _arguments \
        '--all[Delete all]' \
        '(-s --sort)'{-s,--sort}'[Sort]:sort:(created_at last_accessed_at size_in_bytes)' \
        '(-o --order)'{-o,--order}'[Order]:order:(asc desc)' \
        ':cache:'
      ;;
    list)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--limit[Maximum]:limit:' \
        '(-o --order)'{-o,--order}'[Order]:order:(asc desc)' \
        '(-s --sort)'{-s,--sort}'[Sort]:sort:(created_at last_accessed_at size_in_bytes)' \
        '--template[Format template]:template:'
      ;;
  esac
}

# Auth completions
_gh_auth_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'login:Authenticate'
      'logout:Logout'
      'refresh:Refresh credentials'
      'setup-git:Configure git'
      'status:View status'
      'switch:Switch account'
      'token:Print token'
    )
    _describe -t commands "auth commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    login)
      _arguments \
        '(-h --hostname)'{-h,--hostname}'[Host]:host:' \
        '--insecure-storage[Insecure token storage]' \
        '(-p --protocol)'{-p,--protocol}'[Protocol]:protocol:(https ssh)' \
        '--scopes[Scopes]:scopes:' \
        '--skip-ssh-key[Skip SSH key]' \
        '--token[Token]:token:' \
        '--web[Open browser]' \
        '--with-token[Read from stdin]'
      ;;
    logout)
      _arguments \
        '(-h --hostname)'{-h,--hostname}'[Host]:host:' \
        '--user[User]:user:'
      ;;
    refresh)
      _arguments \
        '(-h --hostname)'{-h,--hostname}'[Host]:host:' \
        '--scopes[Scopes]:scopes:'
      ;;
    setup-git)
      _arguments \
        '(-h --hostname)'{-h,--hostname}'[Host]:host:'
      ;;
    status)
      _arguments \
        '--active[Active only]' \
        '--show-token[Show token]'
      ;;
    switch)
      _arguments \
        '--user[User]:user:'
      ;;
    token)
      _arguments \
        '(-h --hostname)'{-h,--hostname}'[Host]:host:'
      ;;
  esac
}

# Config completions
_gh_config_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'get:Print config value'
      'list:Print all config'
      'set:Set config value'
    )
    _describe -t commands "config commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    get|set)
      local keys=(
        'git_protocol:Git protocol (https/ssh)'
        'editor:Default editor'
        'prompt:Prompt setting'
        'pager:Default pager'
        'http_unix_socket:HTTP socket path'
        'browser:Web browser'
      )
      _describe -t keys "config keys" keys
      ;;
    list)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--template[Format template]:template:'
      ;;
  esac
}

# Extension completions
_gh_extension_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'browse:Browse extensions'
      'create:Create extension'
      'exec:Execute extension'
      'install:Install extension'
      'list:List extensions'
      'remove:Remove extension'
      'search:Search extensions'
      'upgrade:Upgrade extension'
    )
    _describe -t commands "extension commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    browse|exec|remove|upgrade)
      _arguments \
        '--dry-run[Show what would change]' \
        '--force[Force]' \
        '*:extension:_gh_extensions'
      ;;
    create)
      _arguments \
        '--precompiled[Precompiled binary]' \
        '--skel[Go or shell]:skel:(go script)' \
        ':name:'
      ;;
    install)
      _arguments \
        '--dry-run[Show what would change]' \
        '--force[Force]' \
        '--pin[Pin to tag/branch]:ref:' \
        ':extension:'
      ;;
    list)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--template[Format template]:template:'
      ;;
    search)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--limit[Maximum]:limit:' \
        '--template[Format template]:template:' \
        '--web[Open in browser]' \
        ':query:'
      ;;
  esac
}

# Alias completions
_gh_alias_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'delete:Delete alias'
      'import:Import aliases'
      'list:List aliases'
      'set:Set alias'
    )
    _describe -t commands "alias commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    delete|set)
      _arguments \
        ':alias:' \
        ':expansion: '
      ;;
    import)
      _arguments \
        '(-c --clobber)'{-c,--clobber}'[Overwrite' \
        ':config:_files'
      ;;
    list)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--template[Format template]:template:'
      ;;
  esac
}

# API completions
_gh_api_completion() {
  _arguments \
    '(-F --field)'{-F,--field}'[Add body field]:field:' \
    '(-f --flat)'{-f,--flat}'[Parse as flat]' \
    '--hostname[Host]:host:' \
    '(-H --header)'{-H,--header}'[Add header]:header:' \
    '--include[Include headers]' \
    '--input[Input file]:file:_files' \
    '--jq[Filter with jq]:filter:' \
    '--method[HTTP method]:method:(GET POST PUT DELETE PATCH)' \
    '--paginate[Page through results]' \
    '--preview[API preview]:preview:' \
    '--raw-field[Add string field]:field:' \
    '--silent[Silent]' \
    '--slurp[Read until EOF]' \
    '--template[Format template]:template:' \
    '-t[Output format]:format:(json jq template)' \
    ':endpoint: '
}

# Search completions
_gh_search_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'commits:Search commits'
      'issues:Search issues'
      'prs:Search PRs'
      'repos:Search repos'
    )
    _describe -t commands "search commands" commands
    return
  fi
  
  local subcmd=$words[3]
  
  case "$subcmd" in
    commits|issues|prs|repos)
      _arguments \
        '--jq[Filter with jq]:filter:' \
        '--json[JSON fields]:fields:' \
        '--limit[Maximum]:limit:' \
        '--order[Order]:order:(asc desc)' \
        '--sort[Sort]:sort:' \
        '--template[Format template]:template:' \
        '--web[Open in browser]' \
        '*:query:'
      ;;
  esac
}

# Browse completions
_gh_browse_completion() {
  _arguments \
    '(-b --branch)'{-b,--branch}'[Branch]:branch:_gh_branches' \
    '(-c --commit)'{-c,--commit}'[Commit]:commit:' \
    '(-n --no-browser)'{-n,--no-browser}'[Print URL]' \
    '(-p --projects)'{-p,--projects}'[Projects]' \
    '(-R --repo)'{-R,--repo}'[Repository]:repo:_gh_repos' \
    '(-s --settings)'{-s,--settings}'[Settings]' \
    '(-w --wiki)'{-w,--wiki}'[Wiki]' \
    ':file|number: '
}

# Register the enhanced completion
compdef _gh_enhanced gh

# ============================================================
# LEGACY: Keep generating native completions as fallback
# ============================================================

if [[ ! -f "$ZSH_CACHE_DIR/completions/_gh" ]]; then
  typeset -g -A _comps
  autoload -Uz _gh
  _comps[gh]=_gh
fi

gh completion --shell zsh >| "$ZSH_CACHE_DIR/completions/_gh" &|

# ============================================================
# ALIASES
# ============================================================

# caps:category=repo
# caps:desc=Clone repository
alias ghcl='gh repo clone'

# caps:category=pr
# caps:desc=Create pull request
alias ghpr='gh pr create'

# caps:category=pr
# caps:desc=Checkout pull request
alias ghprc='gh pr checkout'

# caps:category=issues
# caps:desc=Create issue
alias ghi='gh issue create'

# caps:category=ci
# caps:desc=List workflows
alias ghw='gh workflow list'
alias ghprv='gh pr view --web'
alias ghprc='gh pr checkout'
alias ghprm='gh pr merge'
alias ghi='gh issue create'
alias ghiv='gh issue view --web'
alias ghr='gh repo view --web'
alias ghw='gh workflow list'
alias ghrun='gh run list'
alias ghrel='gh release list'
alias ghcode='gh codespace list'
alias ghgist='gh gist list'
