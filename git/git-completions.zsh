# Git - Enhanced completions for oh-my-zsh
# Source this file after git.plugin.zsh

# Only proceed if git is available
if (( ! $+commands[git] )); then
  return
fi

# ============================================================
# CACHE AND STATE MANAGEMENT
# ============================================================

_git_cache_dir="${ZSH_CACHE_DIR}/git-enhanced"
mkdir -p "$_git_cache_dir"

# Get all branches with descriptions
_git_branches_with_desc() {
  local format='%(refname:short):%(contents:subject)'
  git for-each-ref --format="$format" refs/heads/ 2>/dev/null | \
    while IFS=: read -r branch desc; do
      if [[ -n "$desc" ]]; then
        echo "${branch//:/\\:}:${desc:0:50}"
      else
        echo "${branch//:/\\:}:(no description)"
      fi
    done
}

# Get remote branches
_git_remote_branches() {
  git branch -r --format '%(refname:short)' 2>/dev/null | grep -v HEAD
}

# Get all branches (local and remote)
_git_all_branches() {
  git branch -a --format '%(refname:short)' 2>/dev/null | sed 's|^remotes/||' | sort -u
}

# Get recent branches (from reflog)
_git_recent_branches() {
  git reflog 2>/dev/null | grep -E 'checkout: moving from' | \
    sed -E 's/.*moving from ([^ ]+) to.*/\1/' | awk '!seen[$0]++' | head -20
}

# Get tags
_git_tags() {
  git tag -l 2>/dev/null
}

# Get remotes
_git_remotes() {
  git remote 2>/dev/null
}

# Get stashes
_git_stashes() {
  git stash list --format '%gd:%s' 2>/dev/null
}

# Get tracked files
_git_tracked_files() {
  git ls-files 2>/dev/null
}

# Get modified files
_git_modified_files() {
  git diff --name-only 2>/dev/null
}

# Get untracked files
_git_untracked_files() {
  git ls-files --others --exclude-standard 2>/dev/null
}

# Get all files (tracked + untracked)
_git_all_files() {
  git ls-files --others --exclude-standard 2>/dev/null
  git ls-files 2>/dev/null
}

# Get commit hashes (recent)
_git_commits() {
  git log --oneline --format='%h:%s' -30 2>/dev/null
}

# Get configuration keys
_git_config_keys() {
  git config --list --name-only 2>/dev/null | sort -u
}

# ============================================================
# ENHANCED GIT COMPLETION FUNCTION
# ============================================================

_git_enhanced() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # Get the git subcommand
  local cmd
  local i=1
  while (( i < $#words )); do
    if [[ ${words[$i]} != -* && $i -gt 1 ]]; then
      cmd=${words[$i]}
      break
    fi
    (( i++ ))
  done
  
  # If no subcommand yet, complete git commands
  if [[ -z "$cmd" ]] && (( CURRENT == 2 )); then
    _git_commands
    return
  fi
  
  # Complete based on subcommand
  case "$cmd" in
    checkout|co)
      _git_checkout_completion
      ;;
    switch|sw)
      _git_switch_completion
      ;;
    restore)
      _git_restore_completion
      ;;
    branch|br)
      _git_branch_completion
      ;;
    merge|m)
      _git_merge_completion
      ;;
    rebase)
      _git_rebase_completion
      ;;
    cherry-pick|cp)
      _git_cherry_pick_completion
      ;;
    stash)
      _git_stash_completion
      ;;
    remote)
      _git_remote_completion
      ;;
    config)
      _git_config_completion
      ;;
    tag)
      _git_tag_completion
      ;;
    log)
      _git_log_completion
      ;;
    diff|d)
      _git_diff_completion
      ;;
    add)
      _git_add_completion
      ;;
    rm)
      _git_rm_completion
      ;;
    commit|c)
      _git_commit_completion
      ;;
    push)
      _git_push_completion
      ;;
    pull)
      _git_pull_completion
      ;;
    fetch)
      _git_fetch_completion
      ;;
    reset)
      _git_reset_completion
      ;;
    revert)
      _git_revert_completion
      ;;
    clean)
      _git_clean_completion
      ;;
    bisect)
      _git_bisect_completion
      ;;
    worktree)
      _git_worktree_completion
      ;;
    submodule)
      _git_submodule_completion
      ;;
    *)
      # Fall back to default git completion
      _git
      ;;
  esac
}

# ============================================================
# COMMAND-SPECIFIC COMPLETIONS
# ============================================================

_git_commands() {
  local -a commands
  commands=(
    'add:Add file contents to index'
    'am:Apply patches from mailbox'
    'apply:Apply patch to files'
    'archive:Create archive of files'
    'bisect:Binary search for changes'
    'blame:Show line annotations'
    'branch:List, create, delete branches'
    'bundle:Move objects by archive'
    'checkout:Switch branches'
    'cherry-pick:Apply commits from other branches'
    'citool:Graphical commit'
    'clean:Remove untracked files'
    'clone:Clone repository'
    'commit:Record changes'
    'config:Get and set repository options'
    'describe:Describe commit using tags'
    'diff:Show changes'
    'fetch:Download objects from remote'
    'format-patch:Prepare email patches'
    'gc:Cleanup unnecessary files'
    'grep:Print lines matching pattern'
    'init:Create empty repository'
    'log:Show commit logs'
    'merge:Join development histories'
    'mv:Move or rename file'
    'notes:Add or inspect object notes'
    'pull:Fetch and merge'
    'push:Update remote refs'
    'range-diff:Compare commit ranges'
    'rebase:Reapply commits'
    'reset:Reset current HEAD'
    'restore:Restore working tree files'
    'revert:Revert commits'
    'rm:Remove files'
    'shortlog:Summarize git log'
    'show:Show various types of objects'
    'sparse-checkout:Reduce working tree'
    'stash:Stash changes'
    'status:Show working tree status'
    'submodule:Manage submodules'
    'switch:Switch branches'
    'tag:Create, list, delete tags'
    'worktree:Manage working trees'
  )
  _describe -t commands "git commands" commands
}

_git_checkout_completion() {
  local cur=$words[CURRENT]
  
  # Options
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '(-b -B)'{-b,-B}'[Create branch]:branch: '
      '--orphan[Create orphan branch]:branch: '
      '--ours[Checkout our version]'
      '--theirs[Checkout their version]'
      '(-f --force)'{-f,--force}'[Force]'
      '(-m --merge)'{-m,--merge}'[Merge]'
      '--detach[Detach HEAD]'
      '--track[Set upstream tracking]'
      '--no-track[No tracking]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '--progress[Progress]'
    )
    _describe -t options "checkout options" options
    return
  fi
  
  # Complete branches, tags, commits
  local -a branches tags recent
  branches=(${(f)"$(_git_branches_with_desc)"})
  tags=(${(f)"$(_git_tags)"})
  recent=(${(f)"$(_git_recent_branches)"})
  
  _describe -t branches "branches" branches
  _describe -t tags "tags" tags
  _describe -t recent "recent branches" recent
}

_git_switch_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '(-c -C)'{-c,-C}'[Create branch]:branch: '
      '--orphan[Create orphan branch]:branch: '
      '--discard-changes[Discard changes]'
      '(-f --force)'{-f,--force}'[Force]'
      '--merge[Merge]'
      '--track[Set upstream]'
      '--no-track[No tracking]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '--progress[Progress]'
    )
    _describe -t options "switch options" options
    return
  fi
  
  local -a branches recent
  branches=(${(f)"$(_git_branches_with_desc)"})
  recent=(${(f)"$(_git_recent_branches)"})
  
  _describe -t branches "branches" branches
  _describe -t recent "recent branches" recent
}

_git_restore_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '(-s --source)'{-s,--source}'[Source]:source:_git_commits'
      '--staged[Restore staged]'
      '--worktree[Restore worktree]'
      '--ours[Restore ours]'
      '--theirs[Restore theirs]'
      '(-m --merge)'{-m,--merge}'[Merge]'
      '--overlay[Overlay]'
      '--progress[Progress]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '(-p --patch)'{-p,--patch}'[Patch]'
    )
    _describe -t options "restore options" options
    return
  fi
  
  _files
}

_git_branch_completion() {
  if (( CURRENT == 2 )); then
    local -a options
    options=(
      '(-a --all)'{-a,--all}'[List all branches]'
      '(-r --remotes)'{-r,--remotes}'[List remote branches]'
      '--show-current[Show current branch]'
      '(-v --verbose)'{-v,--verbose}'[Verbose]'
      '(-d --delete)'{-d,--delete}'[Delete branch]:branch:_git_all_branches'
      '(-D)'{-D}'[Force delete]:branch:_git_all_branches'
      '(-m --move)'{-m,--move}'[Rename branch]:old: :new: '
      '(-M)'{-M}'[Force rename]:old: :new: '
      '(-c --copy)'{-c,--copy}'[Copy branch]:old: :new: '
      '(-C)'{-C}'[Force copy]:old: :new: '
      '(-u --set-upstream-to)'{-u,--set-upstream-to}'[Set upstream]:upstream:_git_all_branches'
      '--unset-upstream[Unset upstream]'
      '--merged[List merged branches]'
      '--no-merged[List unmerged branches]'
      '--contains[Contains commit]:commit:_git_commits'
      '--no-contains[Does not contain]:commit:_git_commits'
      '--sort[Sort order]:key: '
      '--format[Format]:format: '
      '--color[Color]:when:(always never auto)'
    )
    _describe -t options "branch options" options
    return
  fi
  
  _git_all_branches
}

_git_merge_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--commit[Auto-commit]'
      '--no-commit[No auto-commit]'
      '--edit[Edit message]'
      '--no-edit[No edit]'
      '--ff[Fast-forward]'
      '--no-ff[No fast-forward]'
      '--ff-only[Fast-forward only]'
      '--squash[Squash]'
      '--no-squash[No squash]'
      '(-m --message)'{-m,--message}'[Message]:message: '
      '--into-name[Into name]:name: '
      '(-s --strategy)'{-s,--strategy}'[Strategy]:strategy:(resolve recursive octopus ours subtree)'
      '--strategy-option[Strategy option]:option: '
      '--verify-signatures[Verify signatures]'
      '--no-verify-signatures[No verify]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '(-v --verbose)'{-v,--verbose}'[Verbose]'
      '--progress[Progress]'
      '--no-progress[No progress]'
      '(-n --stat)'{-n,--stat}'[No stat]'
      '--stat[Stat]'
      '--log[Add log]'
      '--no-log[No log]'
    )
    _describe -t options "merge options" options
    return
  fi
  
  local -a branches
  branches=(${(f)"$(_git_branches_with_desc)"})
  _describe -t branches "branches to merge" branches
}

_git_rebase_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '(-i --interactive)'{-i,--interactive}'[Interactive]'
      '--continue[Continue]'
      '--abort[Abort]'
      '--skip[Skip]'
      '--quit[Quit]'
      '--edit-todo[Edit todo]'
      '--show-current-patch[Show patch]'
      '--apply[Use apply]'
      '--merge[Use merge]'
      '--onto[Rebase onto]:newbase:_git_all_branches'
      '--root[Rebase from root]'
      '(-m --merge)'{-m,--merge}'[Use merging]'
      '--no-ff[No fast-forward]'
      '(-f --force-rebase)'{-f,--force-rebase}'[Force rebase]'
      '--ignore-whitespace[Ignore whitespace]'
      '--committer-date-is-author-date[Preserve date]'
      '--ignore-date[Ignore date]'
      '--signoff[Sign off]'
      '(-n --no-stat)'{-n,--no-stat}'[No stat]'
      '--stat[Stat]'
      '--no-verify[No verify]'
      '--verify[Verify]'
      '(-C --no-rebase-merges)'{-C,--no-rebase-merges}'[No rebase merges]'
      '--rebase-merges[Rebase merges]'
      '--fork-point[Use fork-point]'
      '--no-fork-point[No fork-point]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '--autostash[Autostash]'
      '--no-autostash[No autostash]'
      '--empty[Keep empty]:mode:(drop keep ask)'
    )
    _describe -t options "rebase options" options
    return
  fi
  
  local -a branches commits
  branches=(${(f)"$(_git_branches_with_desc)"})
  commits=(${(f)"$(_git_commits)"})
  
  _describe -t branches "branch" branches
  _describe -t commits "commit" commits
}

_git_cherry_pick_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--continue[Continue]'
      '--abort[Abort]'
      '--quit[Quit]'
      '--skip[Skip]'
      '--edit[Edit message]'
      '--no-edit[No edit]'
      '(-m --mainline)'{-m,--mainline}'[Parent number]:parent:'
      '(-n --no-commit)'{-n,--no-commit}'[No commit]'
      '(-x)'{-x}'[Append line]'
      '--ff[Fast-forward]'
      '--no-ff[No fast-forward]'
      '--allow-empty[Allow empty]'
      '--allow-empty-message[Allow empty message]'
      '--keep-redundant-commits[Keep redundant]'
      '--strategy[Strategy]:strategy:(resolve recursive octopus ours subtree)'
      '--strategy-option[Option]:option: '
      '--signoff[Sign off]'
      '--no-signoff[No signoff]'
    )
    _describe -t options "cherry-pick options" options
    return
  fi
  
  _git_commits
}

_git_stash_completion() {
  if (( CURRENT == 2 )); then
    local -a commands
    commands=(
      'list:List stashes'
      'show:Show stash'
      'drop:Drop stash'
      'pop:Pop stash'
      'apply:Apply stash'
      'branch:Create branch from stash'
      'clear:Remove all stashes'
      'create:Create stash'
      'store:Store stash'
      'push:Push to stash'
      'save:Save to stash'
    )
    _describe -t commands "stash commands" commands
    return
  fi
  
  local subcmd=$words[2]
  
  case "$subcmd" in
    show|drop|pop|apply)
      _arguments \
        '(-p --patch)'{-p,--patch}'[Patch mode]' \
        '(-q --quiet)'{-q,--quiet}'[Quiet]' \
        '*:stash:_git_stashes'
      ;;
    branch)
      _arguments \
        ':branch name: ' \
        ':stash:_git_stashes'
      ;;
    push|save)
      _arguments \
        '-p[Patch mode]' \
        '-k[Keep index]' \
        '-u[Include untracked]' \
        '-a[Include all]' \
        '-m[Message]:message: ' \
        '*:path:_files'
      ;;
    list)
      _arguments \
        '--text[Show full text]'
      ;;
  esac
}

_git_remote_completion() {
  if (( CURRENT == 2 )); then
    local -a commands
    commands=(
      'add:Add remote'
      'rename:Rename remote'
      'remove:Remove remote'
      'rm:Remove remote'
      'set-head:Set default branch'
      'set-branches:Set branches'
      'get-url:Get URL'
      'set-url:Set URL'
      'show:Show remote'
      'prune:Prune remote'
      'update:Fetch updates'
    )
    _describe -t commands "remote commands" commands
    return
  fi
  
  local subcmd=$words[2]
  
  case "$subcmd" in
    add)
      _arguments \
        '-t[Track branch]:branch:_git_all_branches' \
        '-m[Master branch]:branch:_git_all_branches' \
        '--mirror[Mirror mode]:mode:(push fetch)' \
        '--tags[Import tags]' \
        '--no-tags[No tags]' \
        '--fetch[Fetch]' \
        ':name: ' \
        ':url: '
      ;;
    rename|remove|rm|set-head|set-branches|show|prune|update|get-url|set-url)
      _arguments \
        '*:remote:_git_remotes'
      ;;
  esac
}

_git_config_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--global[Global config]'
      '--system[System config]'
      '--local[Local config]'
      '--worktree[Worktree config]'
      '--file[Use file]:file:_files' \
      '--blob[Read from blob]:blob:'
      '--remove-section[Remove section]:name:'
      '--rename-section[Rename section]:old: :new:'
      '--unset[Unset value]:name:'
      '--unset-all[Unset all]:name:'
      '(-l --list)'{-l,--list}'[List]'
      '--fixed-value[Exact value match]'
      '--type[Value type]:type:(bool int bool-or-int path expiry-date color)'
      '--edit[Open editor]'
      '--get[Get value]:name:'
      '--get-all[Get all]:name:'
      '--get-regexp[Get by regexp]:regexp:'
      '--get-urlmatch[Get URL]:url:'
      '--add[Add value]:name: :value:'
      '--replace-all[Replace all]:name: :value:'
    )
    _describe -t options "config options" options
    return
  fi
  
  _git_config_keys
}

_git_tag_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '(-a --annotate)'{-a,--annotate}'[Annotated tag]'
      '(-s --sign)'{-s,--sign}'[GPG sign]'
      '--no-sign[No sign]'
      '(-u --local-user)'{-u,--local-user}'[Signing key]:key:'
      '(-f --force)'{-f,--force}'[Force]'
      '(-d --delete)'{-d,--delete}'[Delete tag]:tag:_git_tags'
      '(-v --verify)'{-v,--verify}'[Verify tag]:tag:_git_tags'
      '(-l --list)'{-l,--list}'[List tags]'
      '--sort[Sort key]:key: '
      '--color[Color]:when:(always never auto)'
      '(-i --ignore-case)'{-i,--ignore-case}'[Ignore case]'
      '--column[Column layout]:layout: '
      '--contains[Contains commit]:commit:_git_commits'
      '--no-contains[No contains]:commit:_git_commits'
      '--merged[Merged]:commit:_git_commits'
      '--no-merged[No merged]:commit:_git_commits'
      '--create-reflog[Create reflog]'
      '(-m --message)'{-m,--message}'[Tag message]:message: '
      '(-F --file)'{-F,--file}'[Read message]:file:_files'
      '--cleanup[Cleanup mode]:mode:(verbatim whitespace strip)'
    )
    _describe -t options "tag options" options
    return
  fi
  
  _git_tags
}

_git_log_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--follow[Follow renames]'
      '--no-decorate[No decorate]'
      '--decorate[Decorate]:mode:(short full auto no)'
      '--decorate-refs[Decorate refs]:pattern: '
      '--decorate-refs-exclude[Exclude refs]:pattern: '
      '--source[Print source]'
      '--use-mailmap[Use mailmap]'
      '--full-diff[Show full diff]'
      '--log-size[Print log size]'
      '(-n --max-count)'{-n,--max-count}'[Limit]:count:'
      '--skip[Skip number]:count:'
      '--since[Since date]:date:'
      '--after[After date]:date:'
      '--until[Until date]:date:'
      '--before[Before date]:date:'
      '--author[Author]:pattern: '
      '--committer[Committer]:pattern: '
      '--grep[Message pattern]:pattern: '
      '--all-match[All patterns]'
      '--invert-grep[Invert grep]'
      '-E[Extended regexp]'
      '-F[Fixed strings]'
      '--all[All refs]'
      '--branches[All branches]'
      '--tags[All tags]'
      '--remotes[All remotes]'
      '--graph[Graph]'
      '--oneline[One line]'
      '--format[Format]:format:(oneline short medium full fuller reference email raw)'
      '--date[Date format]:format:(relative iso iso-strict rfc short local default raw unix format:)'
      '--left-right[Show left/right]'
      '--cherry[Show cherry marks]'
      '--left-only[Left only]'
      '--right-only[Right only]'
      '--cherry-mark[Cherry marks]'
      '--cherry-pick[Cherry pick]'
      '--merge[Merge commits]'
      '--first-parent[First parent]'
      '--not[Not]'
    )
    _describe -t options "log options" options
    return
  fi
  
  local -a branches commits files
  branches=(${(f)"$(_git_branches_with_desc)"})
  commits=(${(f)"$(_git_commits)"})
  
  _describe -t branches "branch" branches
  _describe -t commits "commit" commits
  _files
}

_git_diff_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--cached[Staged changes]'
      '--staged[Staged changes]'
      '--no-index[Compare non-git files]'
      '--exit-code[Exit with code]'
      '--quiet[Quiet]'
      '--ext-diff[External diff]'
      '--no-ext-diff[No external diff]'
      '--text[Treat as text]'
      '--ignore-cr-at-eol[Ignore CR]'
      '--ignore-space-at-eol[Ignore space at EOL]'
      '--ignore-space-change[Ignore space change]'
      '--ignore-all-space[Ignore all space]'
      '--ignore-blank-lines[Ignore blank lines]'
      '--ignore-submodules[Ignore submodules]:when:(none untracked dirty all)'
      '--indent-heuristic[Indent heuristic]'
      '--no-indent-heuristic[No indent heuristic]'
      '--patience[Patience diff]'
      '--histogram[Histogram diff]'
      '--anchored[Anchored diff]:line: '
      '--diff-algorithm[Algorithm]:algorithm:(patience minimal histogram myers)'
      '--stat[Generate stat]'
      '--numstat[Numstat]'
      '--shortstat[Short stat]'
      '--dirstat[Dir stat]'
      '--cumulative[Accumulate]'
      '--dirstat-by-file[Dir stat by file]'
      '--check[Check]'
      '--summary[Summary]'
      '--patch-with-stat[Patch with stat]'
      '--name-only[Names only]'
      '--name-status[Name status]'
      '--color[Color]:when:(always never auto)'
      '--no-color[No color]'
      '--word-diff[Word diff]:mode:(color plain porcelain none)'
      '--word-diff-regex[Word regex]:regex: '
      '--color-words[Color words]:regex: '
      '--no-renames[No renames]'
      '--check[Check]'
      '--full-index[Full index]'
      '--binary[Binary]'
      '--abbrev[Abbrev]:n:'
      '(-B --break-rewrites)'{-B,--break-rewrites}'[Break rewrites]'
      '(-M --find-renames)'{-M,--find-renames}'[Find renames]'
      '(-C --find-copies)'{-C,--find-copies}'[Find copies]'
      '--find-copies-harder[Harder copies]'
      '--diff-filter[Filter]:filter: '
      '(-S --pickaxe-all)'{-S,--pickaxe-all}'[Pickaxe]'
      '--pickaxe-regex[Pickaxe regex]'
      '-O[Order file]:file:_files'
      '-R[Reverse]'
      '--relative[Relative]'
      '(-a --text)'{-a,--text}'[Treat as text]'
      '(-b --ignore-space-change)'{-b,--ignore-space-change}'[Ignore space]'
      '(-w --ignore-all-space)'{-w,--ignore-all-space}'[Ignore all space]'
      '--ignore-submodules[Ignore submodules]'
      '--src-prefix[Source prefix]:prefix: '
      '--dst-prefix[Dest prefix]:prefix: '
      '--no-prefix[No prefix]'
    )
    _describe -t options "diff options" options
    return
  fi
  
  local -a branches commits
  branches=(${(f)"$(_git_branches_with_desc)"})
  commits=(${(f)"$(_git_commits)"})
  
  _describe -t branches "branch" branches
  _describe -t commits "commit" commits
  _files
}

_git_add_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '(-n --dry-run)'{-n,--dry-run}'[Dry run]'
      '(-v --verbose)'{-v,--verbose}'[Verbose]'
      '(-f --force)'{-f,--force}'[Force]'
      '(-i --interactive)'{-i,--interactive}'[Interactive]'
      '(-p --patch)'{-p,--patch}'[Patch]'
      '(-e --edit)'{-e,--edit}'[Edit]'
      '(-u --update)'{-u,--update}'[Update tracked]'
      '(-A --all --no-ignore-removal)'{-A,--all,--no-ignore-removal}'[Add all]'
      '--no-all[No all]'
      '--ignore-removal[Ignore removal]'
      '--refresh[Refresh]'
      '--ignore-errors[Ignore errors]'
      '--ignore-missing[Ignore missing]'
      '--chmod[Set mode]:mode:(+x -x)'
      '--pathspec-from-file[Pathspec file]:file:_files'
      '--pathspec-file-nul[NUL separator]'
    )
    _describe -t options "add options" options
    return
  fi
  
  local -a modified untracked
  modified=(${(f)"$(_git_modified_files)"})
  untracked=(${(f)"$(_git_untracked_files)"})
  
  _describe -t modified "modified" modified
  _describe -t untracked "untracked" untracked
  _files
}

_git_rm_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '(-n --dry-run)'{-n,--dry-run}'[Dry run]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '--cached[Cached only]'
      '--ignore-unmatch[Ignore nomatch]'
      '(-r)'{-r}'[Recursive]'
      '--sparse[Sparse checkout]'
    )
    _describe -t options "rm options" options
    return
  fi
  
  _git_tracked_files
}

_git_commit_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '(-a --all)'{-a,--all}'[Commit all]'
      '(-p --patch)'{-p,--patch}'[Patch mode]'
      '(-C --reuse-message)'{-C,--reuse-message}'[Reuse message]:commit:_git_commits'
      '(-c --reedit-message)'{-c,--reedit-message}'[Reedit message]:commit:_git_commits'
      '--fixup[Fixup]:commit:_git_commits'
      '--squash[Squash]:commit:_git_commits'
      '--reset-author[Reset author]'
      '(-m --message)'{-m,--message}'[Message]:message: '
      '(-F --file)'{-F,--file}'[Read message]:file:_files'
      '--author[Author]:author: '
      '--date[Date]:date: '
      '(-s --signoff)'{-s,--signoff}'[Sign off]'
      '--no-signoff[No signoff]'
      '(-n --no-verify)'{-n,--no-verify}'[No verify]'
      '--verify[Verify]'
      '--allow-empty[Allow empty]'
      '--allow-empty-message[Allow empty message]'
      '--cleanup[Cleanup]:mode:(strip whitespace verbatim scissors default)'
      '--edit[Edit]'
      '--no-edit[No edit]'
      '--amend[Amend]'
      '--no-post-rewrite[No post-rewrite]'
      '(-i --include)'{-i,--include}'[Include]'
      '--only[Only]'
      '(-o --only)'{-o,--only}'[Only specified]'
      '(-u --untracked-files)'{-u,--untracked-files}'[Untracked files]:mode:(all normal no)'
      '(-v --verbose)'{-v,--verbose}'[Verbose]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '--dry-run[Dry run]'
      '--status[Include status]'
      '--no-status[No status]'
      '(-S --gpg-sign)'{-S,--gpg-sign}'[GPG sign]'
      '--no-gpg-sign[No GPG sign]'
    )
    _describe -t options "commit options" options
    return
  fi
  
  _files
}

_git_push_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--all[Push all refs]'
      '--mirror[Push all refs]'
      '--tags[Push all tags]'
      '--follow-tags[Push annotated tags]'
      '--atomic[Atomic]'
      '--no-atomic[No atomic]'
      '(-n --dry-run)'{-n,--dry-run}'[Dry run]'
      '--porcelain[Machine-readable]'
      '(-d --delete)'{-d,--delete}'[Delete refs]'
      '--tags[Push tags]'
      '--follow-tags[Follow tags]'
      '--signed[Signed push]:mode:(if-asked true false yes no)'
      '--no-signed[No signed push]'
      '--atomic[Atomic]'
      '(-f --force)'{-f,--force}'[Force]'
      '--force-with-lease[Force with lease]:refspec: '
      '--force-if-includes[Force if includes]'
      '(-o --push-option)'{-o,--push-option}'[Push option]:option: '
      '--receive-pack[Receive pack]:path: '
      '--repo[Repository]:repo:_git_remotes'
      '--set-upstream[Set upstream]'
      '--thin[Thin pack]'
      '--no-thin[No thin]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '(-v --verbose)'{-v,--verbose}'[Verbose]'
      '--progress[Progress]'
      '--no-recurse-submodules[No recurse]'
      '--recurse-submodules[Recurse]:mode:(check on-demand only)'
    )
    _describe -t options "push options" options
    return
  fi
  
  _git_remotes
  _git_all_branches
}

_git_pull_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--quiet[Quiet]'
      '--verbose[Verbose]'
      '--recurse-submodules[Recurse]:mode:(yes on-demand no)'
      '--no-recurse-submodules[No recurse]'
      '--commit[Autocommit]'
      '--no-commit[No autocommit]'
      '--edit[Edit message]'
      '--no-edit[No edit]'
      '--cleanup[Cleanup]:mode:(strip whitespace verbatim scissors default)'
      '--ff[Fast-forward]'
      '--no-ff[No fast-forward]'
      '--ff-only[Fast-forward only]'
      '--log[Log]'
      '--no-log[No log]'
      '--signoff[Signoff]'
      '--no-signoff[No signoff]'
      '--stat[Stat]'
      '--no-stat[No stat]'
      '--squash[Squash]'
      '--no-squash[No squash]'
      '--strategy[Strategy]:strategy:(resolve recursive octopus ours subtree)'
      '--strategy-option[Option]:option: '
      '--verify-signatures[Verify signatures]'
      '--no-verify-signatures[No verify]'
      '--autostash[Autostash]'
      '--no-autostash[No autostash]'
      '--rebase[Rebase]:mode:(false true merges interactive)'
      '--no-rebase[No rebase]'
      '--all[All remotes]'
      '-a[Append refmap]'
      '--depth[Depth]:depth:'
      '--deepen[Deepen]:depth:'
      '--shallow-since[Shallow since]:date:'
      '--shallow-exclude[Shallow exclude]:revision: '
      '--unshallow[Unshallow]'
      '--update-shallow[Update shallow]'
      '--refmap[Refmap]:refmap: '
      '--force[Force]'
      '(-t --tags)'{-t,--tags}'[Fetch all tags]'
      '--no-tags[No tags]'
      '--prune[Prune]'
      '--no-prune[No prune]'
      '--dry-run[Dry run]'
    )
    _describe -t options "pull options" options
    return
  fi
  
  _git_remotes
  _git_all_branches
}

_git_fetch_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--all[Fetch all remotes]'
      '--prune[Prune]'
      '--unshallow[Unshallow]'
      '--dry-run[Dry run]'
      '(-t --tags)'{-t,--tags}'[Fetch tags]'
      '--no-tags[No tags]'
      '--force[Force]'
      '--keep[Keep downloaded pack]'
      '--depth[Depth]:depth:'
      '--deepen[Deepen]:depth:'
      '--shallow-since[Since]:date:'
      '--shallow-exclude[Exclude]:revision: '
      '--update-shallow[Update shallow]'
      '--negotiation-tip[Negotiation tip]:commit: '
      '--negotiate-only[Negotiate only]'
      '--filter[Filter]:filter: '
      '--refmap[Refmap]:refmap: '
      '--multiple[Multiple remotes]'
      '--auto-maintenance[Auto maintenance]'
      '--no-auto-maintenance[No auto]'
      '--auto-gc[Auto gc]'
      '--no-auto-gc[No auto]'
      '--write-commit-graph[Write graph]'
      '--no-write-commit-graph[No write]'
      '--prefetch[Prefetch]'
      '-p[Prune]'
      '--jobs[Parallel jobs]:n:'
      '--atomic[Atomic]'
      '--no-atomic[No atomic]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '(-v --verbose)'{-v,--verbose}'[Verbose]'
      '--progress[Progress]'
      '--no-progress[No progress]'
    )
    _describe -t options "fetch options" options
    return
  fi
  
  _git_remotes
}

_git_reset_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--soft[Soft reset]'
      '--mixed[Mixed reset]'
      '--hard[Hard reset]'
      '--merge[Merge reset]'
      '--keep[Keep reset]'
      '--intent-to-add[Intent to add]'
      '-p[Patch mode]'
      '--pathspec-from-file[Pathspec file]:file:_files'
      '--pathspec-file-nul[NUL separator]'
    )
    _describe -t options "reset options" options
    return
  fi
  
  local -a branches commits
  branches=(${(f)"$(_git_branches_with_desc)"})
  commits=(${(f)"$(_git_commits)"})
  
  _describe -t branches "branch" branches
  _describe -t commits "commit" commits
  _files
}

_git_revert_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '--continue[Continue]'
      '--abort[Abort]'
      '--quit[Quit]'
      '--skip[Skip]'
      '--cleanup[Cleanup]:mode:(strip whitespace verbatim scissors default)'
      '--no-edit[No edit]'
      '--edit[Edit]'
      '-s[Signoff]'
      '--no-signoff[No signoff]'
      '(-n --no-commit)'{-n,--no-commit}'[No commit]'
      '-m[Mainline parent]:parent:'
      '--strategy[Strategy]:strategy:(resolve recursive octopus ours subtree)'
      '--strategy-option[Option]:option: '
      '(-S --gpg-sign)'{-S,--gpg-sign}'[GPG sign]'
      '--no-gpg-sign[No GPG sign]'
    )
    _describe -t options "revert options" options
    return
  fi
  
  _git_commits
}

_git_clean_completion() {
  local cur=$words[CURRENT]
  
  if [[ "$cur" == -* ]]; then
    local -a options
    options=(
      '(-d)'{-d}'[Remove untracked directories]'
      '(-f --force)'{-f,--force}'[Force]'
      '-i[Interactive]'
      '-n[Don'\''t remove]'
      '(-q --quiet)'{-q,--quiet}'[Quiet]'
      '(-e --exclude)'{-e,--exclude}'[Exclude pattern]:pattern: '
      '-x[Remove ignored]'
      '-X[Remove only ignored]'
    )
    _describe -t options "clean options" options
    return
  fi
  
  _files
}

_git_bisect_completion() {
  if (( CURRENT == 2 )); then
    local -a commands
    commands=(
      'start:Start bisect'
      'bad:Mark as bad'
      'new:Mark as new (alias for bad)'
      'good:Mark as good'
      'old:Mark as old (alias for good)'
      'skip:Skip commit'
      'reset:Finish and clean up'
      'replay:Replay bisect log'
      'log:Show bisect log'
      'run:Run script'
      'terms:Show terms'
      'visualize:Visualize remaining commits'
      'view:Alias for visualize'
    )
    _describe -t commands "bisect commands" commands
    return
  fi
  
  local subcmd=$words[2]
  
  case "$subcmd" in
    bad|good|new|old|skip)
      _git_commits
      ;;
    reset)
      _arguments \
        ':commit:_git_commits'
      ;;
    run)
      _arguments \
        ':command:_command_names' \
        '*::args:_files'
      ;;
  esac
}

_git_worktree_completion() {
  if (( CURRENT == 2 )); then
    local -a commands
    commands=(
      'add:Add worktree'
      'list:List worktrees'
      'lock:Lock worktree'
      'move:Move worktree'
      'prune:Prune worktrees'
      'remove:Remove worktree'
      'repair:Repair worktree'
      'unlock:Unlock worktree'
    )
    _describe -t commands "worktree commands" commands
    return
  fi
  
  local subcmd=$words[2]
  
  case "$subcmd" in
    add)
      _arguments \
        '-f[Force]' \
        '--detach[Detach HEAD]' \
        '(-b -B)'{-b,-B}'[Create branch]:branch:_git_all_branches' \
        '--lock[Lock worktree]' \
        '--reason[Reason]:reason: ' \
        '--quiet[Quiet]' \
        '--track[Track remote]' \
        ':path:_files -/' \
        '::commit:_git_commits'
      ;;
    lock|move|remove|unlock)
      _arguments \
        '-f[Force]' \
        '--reason[Reason]:reason: ' \
        ':path:_files -/'
      ;;
    prune)
      _arguments \
        '-n[Don'\''t prune]' \
        '-v[Verbose]' \
        '--expire[Expire]:time: '
      ;;
    repair)
      _arguments \
        ':path:_files -/'
      ;;
  esac
}

_git_submodule_completion() {
  if (( CURRENT == 2 )); then
    local -a commands
    commands=(
      'add:Add submodule'
      'status:Show status'
      'init:Initialize submodules'
      'deinit:Unregister submodule'
      'update:Update submodules'
      'set-branch:Set default branch'
      'set-url:Set URL'
      'summary:Show summary'
      'foreach:Run command on all'
      'sync:Sync submodules'
      'absorbgitdirs:Move .git to superproject'
    )
    _describe -t commands "submodule commands" commands
    return
  fi
  
  local subcmd=$words[2]
  
  case "$subcmd" in
    add)
      _arguments \
        '--branch[Branch]:branch:_git_all_branches' \
        '-f[Force]' \
        '--name[Name]:name: ' \
        '--reference[Reference]:repo: ' \
        '--depth[Depth]:depth:' \
        '--progress[Progress]' \
        '--dissociate[Dissociate]' \
        ':repository: ' \
        '::path:_files -/'
      ;;
    status|init|deinit|update|sync)
      _arguments \
        '--progress[Progress]' \
        '--all[All]' \
        ':path: '
      ;;
    set-branch)
      _arguments \
        '--default[Default]' \
        '--branch[Branch]:branch:_git_all_branches' \
        ':path: '
      ;;
    set-url)
      _arguments \
        ':path: ' \
        ':newurl: '
      ;;
    foreach)
      _arguments \
        '--recursive[Recursive]' \
        '--quiet[Quiet]' \
        ':command:_command_names' \
        '*::args:_files'
      ;;
  esac
}

# Register enhanced completion
compdef _git_enhanced git
