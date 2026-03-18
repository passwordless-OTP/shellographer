# Claude Code

This plugin provides comprehensive tab completion and aliases for [Claude Code](https://claude.ai/code) - Anthropic's AI coding assistant CLI.

## Features

- **Dynamic completions**: Sessions, agents, tools, models, and beta features
- **Context-aware**: Suggests relevant options based on previous flags
- **Rich descriptions**: All completions include helpful descriptions
- **Useful aliases**: Quick shortcuts for common workflows

## Installation

Add `claude-code` to your plugins array in `.zshrc`:

```zsh
plugins=(... claude-code)
```

## Requirements

- [Claude Code](https://claude.ai/code) must be installed

## Completions

### Global Options
- `--continue`, `-c` - Continue most recent conversation
- `--resume`, `-r` - Resume specific session
- `--print`, `-p` - Non-interactive output mode
- `--agent` - Select agent (default, code, review, debug, architect)
- `--allowed-tools` - Specify allowed tools
- `--dangerously-skip-permissions` - Bypass permissions
- `--debug`, `-d` - Debug mode with categories
- `--add-dir` - Add allowed directories
- `--betas` - Enable beta features

### Dynamic Completions
- **Sessions**: Lists recent sessions for `--resume`
- **Agents**: Built-in + custom agents from config
- **Tools**: Bash, Edit, Read, Write, Grep, etc.
- **Beta features**: Token-efficient tools, prompt caching

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `c` | `claude` | Short form |
| `cc` | `claude --continue` | Continue session |
| `ccp` | `claude --continue --print` | Continue non-interactive |
| `cp` | `claude --print` | Non-interactive mode |
| `cyolo` | `claude --yolo` | Auto-approve all |
| `ccoder` | `claude --agent code` | Code-focused agent |
| `creview` | `claude --agent review` | Review agent |
| `cdebug` | `claude --agent debug` | Debug agent |
| `carch` | `claude --agent architect` | Architecture agent |
| `cfix` | `claude "Fix this code"` | Quick fix |
| `cexplain` | `claude "Explain this code"` | Quick explain |
| `ctest` | `claude "Write tests for this"` | Quick test |
| `cdoc` | `claude "Add documentation"` | Quick doc |
| `crefactor` | `claude "Refactor this"` | Quick refactor |
| `coptimize` | `claude "Optimize this"` | Quick optimize |

## Cache

Sessions and agents are cached in `$ZSH_CACHE_DIR/claude/` for 60 seconds.
