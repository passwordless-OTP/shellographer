# shellographer/plugins/gh/gh.plugin.zsh
# GitHub CLI aliases and completions

0=${(%):-%N}
local _pdir=${0:A:h}

# Add completions to fpath
fpath+=("$_pdir")

# Guard: Skip if gh not installed
if (( ! $+commands[gh] )); then
  unset _pdir
  return 0
fi

# Load shellographer helpers if available
if (( ! $+functions[_shellographer_alias] )); then
  local _helper="${_pdir:h:h}/lib/alias-helper.zsh"
  [[ -f "$_helper" ]] && source "$_helper"
fi

# Define aliases
local _aliases=(
  "gh-pr-create:gh pr create:Create PR"
  "gh-pr-checkout:gh pr checkout:Checkout PR"
  "gh-pr-merge:gh pr merge:Merge PR"
  "gh-pr-view:gh pr view:View PR"
  "gh-pr-list:gh pr list:List PRs"
  "gh-pr-status:gh pr status:Show PR status"
  "gh-issue-create:gh issue create:Create issue"
  "gh-issue-list:gh issue list:List issues"
  "gh-issue-view:gh issue view:View issue"
  "gh-repo-view:gh repo view:View repository"
  "gh-workflow-list:gh workflow list:List workflows"
  "gh-run-list:gh run list:List workflow runs"
  "gh-release-list:gh release list:List releases"
)

for _entry in $_aliases; do
  local _parts=(${(s/:/)_entry})
  local _name=$_parts[1] _cmd=$_parts[2] _desc=$_parts[3]
  
  if (( $+functions[_shellographer_alias] )); then
    _shellographer_alias "$_name" "$_cmd" "$_desc"
  else
    (( $+functions[$_name] || $+aliases[$_name] )) || alias "$_name=$_cmd"
  fi
done

# Dynamic completions (using cache)
_gh_complete_prs() {
  local cache_key="gh/prs"
  local cmd="gh pr list --json number,title --limit 50 2>/dev/null | jq -r '.[] | \"\(.number):\(.title)\"'"
  
  if (( $+functions[_shellographer_cache] )); then
    _shellographer_cache "$cache_key" 60 "$cmd"
  fi
}

_gh_complete_workflows() {
  local cache_key="gh/workflows"
  local cmd="gh workflow list --json name 2>/dev/null | jq -r '.[].name'"
  
  if (( $+functions[_shellographer_cache] )); then
    _shellographer_cache "$cache_key" 300 "$cmd"
  fi
}

# Register completions if compinit available
if (( $+functions[compdef] )); then
  # Basic completions for now
  compdef '_path_files -/' gh-pr-create 2>/dev/null || true
fi

unset _pdir _helper _aliases _entry _parts _name _cmd _desc
