# GitHub CLI

This plugin provides comprehensive tab completion and aliases for the [GitHub CLI](https://cli.github.com/).

## Features

- **Deep command hierarchy**: 4-5 levels of nested subcommands
- **Dynamic completions**: Repos, PRs, issues, workflows, branches, releases, codespaces
- **Context-aware**: Suggests relevant options based on context
- **Smart caching**: Caches API results with configurable TTL
- **Rich aliases**: Quick shortcuts for common workflows

## Installation

Add `gh` to your plugins array in `.zshrc`:

```zsh
plugins=(... gh)
```

## Requirements

- [GitHub CLI](https://cli.github.com/) must be installed and authenticated

## Command Structure

### Level 1: Main Commands

| Command | Description |
|---------|-------------|
| `auth` | Authenticate with GitHub |
| `repo` | Manage repositories |
| `pr` | Manage pull requests |
| `issue` | Manage issues |
| `run` | View workflow runs |
| `workflow` | Manage workflows |
| `release` | Manage releases |
| `gist` | Manage gists |
| `codespace` | Manage codespaces |
| `secret` | Manage secrets |
| `variable` | Manage variables |
| `label` | Manage labels |
| `cache` | Manage Actions caches |
| `config` | Manage configuration |
| `extension` | Manage extensions |
| `alias` | Manage aliases |
| `api` | Make API requests |
| `search` | Search repos, issues, PRs |
| `browse` | Open in browser |

### Level 2-3: Subcommands

Each main command has deep subcommand hierarchies. Examples:

```
gh repo → clone, create, delete, edit, fork, list, rename, sync, view
gh pr → checkout, checks, close, comment, create, diff, edit, list, merge, review, view
gh workflow → disable, enable, list, run, view
```

### Level 4-5: Arguments & Options

Dynamic completions for:
- Repository names with descriptions
- PR numbers with titles
- Issue numbers with titles
- Branch names
- Workflow names
- Release tags
- Codespace names
- Labels
- Secrets
- Extensions

## Dynamic Completions

The plugin caches and completes:

| Type | Source | TTL |
|------|--------|-----|
| Repositories | `gh repo list` | 5 min |
| PRs | `gh pr list` | 1 min |
| Issues | `gh issue list` | 1 min |
| Workflows | `gh workflow list` | 5 min |
| Runs | `gh run list` | 1 min |
| Releases | `gh release list` | 5 min |
| Gists | `gh gist list` | 5 min |
| Codespaces | `gh codespace list` | 1 min |
| Labels | `gh label list` | 5 min |
| Branches | `git branch` | Real-time |

Cache location: `$ZSH_CACHE_DIR/gh/`

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `ghcl` | `gh repo clone` | Clone repo |
| `ghcr` | `gh repo create` | Create repo |
| `ghf` | `gh repo fork` | Fork repo |
| `ghpr` | `gh pr create` | Create PR |
| `ghprv` | `gh pr view --web` | View PR in browser |
| `ghprc` | `gh pr checkout` | Checkout PR |
| `ghprm` | `gh pr merge` | Merge PR |
| `ghi` | `gh issue create` | Create issue |
| `ghiv` | `gh issue view --web` | View issue in browser |
| `ghr` | `gh repo view --web` | View repo in browser |
| `ghw` | `gh workflow list` | List workflows |
| `ghrun` | `gh run list` | List runs |
| `ghrel` | `gh release list` | List releases |
| `ghcode` | `gh codespace list` | List codespaces |
| `ghgist` | `gh gist list` | List gists |

## Examples

### Repository Operations

```zsh
gh repo clone <tab>              # Shows your repos
gh repo fork <tab>               # Shows repos to fork
gh repo create --template <tab>  # Shows template repos
```

### PR Operations

```zsh
gh pr checkout <tab>             # Shows open PRs with authors
gh pr merge <tab>                # Shows open PRs
gh pr create --base <tab>        # Shows branches
gh pr create --label <tab>       # Shows available labels
gh pr review --type <tab>        # Shows: security, performance, readability
```

### Issue Operations

```zsh
gh issue close <tab>             # Shows open issues
gh issue develop <tab>           # Shows issues to develop
gh issue create --label <tab>    # Shows available labels
```

### Workflow Operations

```zsh
gh workflow run <tab>            # Shows available workflows
gh workflow run build.yml --ref <tab>  # Shows branches
gh run watch <tab>               # Shows recent runs
```

### Codespace Operations

```zsh
gh codespace ssh <tab>           # Shows running codespaces
gh codespace stop <tab>          # Shows active codespaces
gh codespace create --repo <tab> # Shows your repos
```

## Configuration

The completion system respects these environment variables:

```zsh
# Cache TTL in seconds (defaults shown)
GH_CACHE_TTL_REPOS=300      # 5 minutes
GH_CACHE_TTL_PRS=60         # 1 minute
GH_CACHE_TTL_ISSUES=60      # 1 minute
GH_CACHE_TTL_WORKFLOWS=300  # 5 minutes
```

## Fallback

The plugin generates native `gh` shell completions as a fallback. Enhanced completions take precedence but native completions are available if needed.
