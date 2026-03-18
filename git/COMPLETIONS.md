# Git Enhanced Completions

This document describes the enhanced completions added to the git plugin.

## Overview

The enhanced completions provide:
- **Context-aware suggestions**: Different suggestions based on command context
- **Rich descriptions**: Branches with descriptions, commits with messages
- **Dynamic caching**: Recent branches, modified files, etc.
- **Deep command coverage**: 20+ git commands with comprehensive options

## Completion Depth

| Command | Levels | Description |
|---------|--------|-------------|
| `checkout` | 3 | Branches, tags, commits, recent branches |
| `switch` | 3 | Branches with descriptions, recent branches |
| `restore` | 2 | Options, staged/worktree/ours/theirs |
| `branch` | 3 | Commands, branches, options |
| `merge` | 3 | Branches, merge strategies, options |
| `rebase` | 3 | Branches, commits, rebase actions |
| `cherry-pick` | 3 | Commits, options |
| `stash` | 3 | Subcommands, stashes |
| `remote` | 3 | Subcommands, remotes |
| `config` | 3 | Keys, values |
| `tag` | 3 | Tags, options |
| `log` | 3 | Branches, commits, format options |
| `diff` | 3 | Branches, commits, diff options |
| `add` | 3 | Modified files, untracked files, options |
| `rm` | 2 | Tracked files |
| `commit` | 3 | Options, previous commits |
| `push` | 3 | Remotes, branches, options |
| `pull` | 3 | Remotes, branches, merge options |
| `fetch` | 3 | Remotes, options |
| `reset` | 3 | Branches, commits, modes |
| `revert` | 3 | Commits, options |
| `clean` | 2 | Options, untracked files |
| `bisect` | 3 | Subcommands, commits |
| `worktree` | 3 | Subcommands, paths, branches |
| `submodule` | 3 | Subcommands, paths, repos |

## Dynamic Data Sources

| Function | Purpose | Cache |
|----------|---------|-------|
| `_git_branches_with_desc` | Local branches with commit subjects | No |
| `_git_remote_branches` | Remote tracking branches | No |
| `_git_all_branches` | All branches (local + remote) | No |
| `_git_recent_branches` | Recently checked out branches | No |
| `_git_tags` | All tags | No |
| `_git_remotes` | Configured remotes | No |
| `_git_stashes` | Stash list with messages | No |
| `_git_tracked_files` | Files tracked by git | No |
| `_git_modified_files` | Modified files | No |
| `_git_untracked_files` | Untracked files | No |
| `_git_all_files` | All files in repo | No |
| `_git_commits` | Recent commits with messages | No |
| `_git_config_keys` | Config keys | No |

## Usage Examples

### Branch Operations

```zsh
git checkout <tab>
# Shows:
# - Local branches with commit descriptions
# - Recent branches (from reflog)
# - Tags

git switch <tab>
# Shows:
# - Local branches with descriptions
# - Recent branches

git merge <tab>
# Shows:
# - Branches with descriptions
# - Suggests merge strategies
```

### Commit Operations

```zsh
git cherry-pick <tab>
# Shows recent commits with messages

git revert <tab>
# Shows recent commits with messages

git commit --reuse-message=<tab>
# Shows recent commits
```

### Stash Operations

```zsh
git stash pop <tab>
# Shows stashes with descriptions

git stash branch <tab>
# Shows stashes, then prompts for branch name
```

### Worktree Operations

```zsh
git worktree add <tab>
# Shows: -b/-B for branch creation, paths, commit selection

git worktree remove <tab>
# Shows worktree paths
```

### Status-Based Completions

```zsh
git add <tab>
# Shows:
# - Modified files
# - Untracked files
# Distinguishes between them

git restore <tab>
# Shows all files with --staged/--worktree options
```

## Integration with Existing Aliases

The enhanced completions work seamlessly with git aliases:

```zsh
gco <tab>    # git checkout with enhanced completions
gsw <tab>    # git switch with enhanced completions
gbd <tab>    # git branch -d with branch completions
gsta <tab>   # git stash with stash completions
```

## Performance

All data is fetched on-demand with no background processes. Cache files are stored in:
- `$ZSH_CACHE_DIR/git-enhanced/`

## Fallback

If enhanced completions don't match, the system falls back to standard git completions.
