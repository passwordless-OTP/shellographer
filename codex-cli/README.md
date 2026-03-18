# Codex CLI

This plugin provides comprehensive tab completion and aliases for [OpenAI Codex](https://github.com/openai/codex) - OpenAI's coding agent CLI.

## Features

- **Subcommand completions**: exec, review, mcp, resume, cloud, debug, and more
- **Dynamic context**: Sessions, MCP servers, models
- **Approval modes**: suggest, auto-edit, full-auto
- **Extensive aliases**: Quick access to common workflows

## Installation

Add `codex-cli` to your plugins array in `.zshrc`:

```zsh
plugins=(... codex-cli)
```

## Requirements

- [Codex CLI](https://github.com/openai/codex) must be installed

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `codex exec` | `codex e` | Run non-interactively |
| `codex review` | - | Run code review |
| `codex mcp` | - | Manage MCP servers |
| `codex resume` | - | Resume session |
| `codex fork` | - | Fork session |
| `codex apply` | `codex a` | Apply latest diff |
| `codex cloud` | - | Browse Codex Cloud |
| `codex debug` | - | Debugging tools |

## Global Options

- `--model` - Model selection (gpt-4o, gpt-4o-mini, o1, o1-mini, o3-mini)
- `--approval-mode` - Approval mode (suggest, auto-edit, full-auto)
- `--quiet`, `-q` - Non-interactive mode
- `--yes`, `-y` - Auto-approve all (YOLO mode)
- `--context` - Context files
- `--image` - Image files
- `--output` - Output file
- `--format` - Output format
- `--debug` - Debug mode
- `-v` - Verbose

## Approval Modes

| Mode | Description |
|------|-------------|
| `suggest` | Only suggest changes |
| `auto-edit` | Auto-approve edits only |
| `full-auto` | Auto-approve all actions |

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `cx` | `codex` | Short form |
| `cxe` | `codex exec` | Execute |
| `cxr` | `codex review` | Review |
| `cxl` | `codex resume --last` | Resume last |
| `cxm` | `codex mcp` | MCP management |
| `cxs` | `codex resume` | Resume |
| `cxfix` | `codex exec "Fix this code"` | Quick fix |
| `cxtest` | `codex exec "Write tests"` | Quick test |
| `cxdoc` | `codex exec "Add documentation"` | Quick doc |
| `cxreview` | `codex exec "Review this"` | Quick review |
| `cxrefactor` | `codex exec "Refactor this"` | Quick refactor |
| `cxyolo` | `codex --approval-mode full-auto` | Full auto |
| `cxsuggest` | `codex --approval-mode suggest` | Suggest only |
| `cxedit` | `codex --approval-mode auto-edit` | Auto edit |
| `cx4o` | `codex --model gpt-4o` | GPT-4o |
| `cx4m` | `codex --model gpt-4o-mini` | GPT-4o Mini |
| `cxo1` | `codex --model o1` | O1 |

## MCP Management

```zsh
codex mcp list          # List MCP servers
codex mcp add           # Add MCP server
codex mcp remove        # Remove MCP server
codex mcp enable        # Enable MCP server
codex mcp disable       # Disable MCP server
codex mcp config        # Show MCP config
```

## Session Management

```zsh
codex resume            # Interactive session picker
codex resume --last     # Resume most recent
codex fork              # Fork session
codex fork --last       # Fork most recent
```
