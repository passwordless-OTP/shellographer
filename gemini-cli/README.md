# Gemini CLI

This plugin provides comprehensive tab completion and aliases for Google's [Gemini CLI](https://ai.google.dev/gemini-api/docs/cli) - Google's AI assistant.

## Features

- **Subcommand completions**: mcp, extensions, skills
- **Dynamic context**: Sessions, extensions, models
- **Multiple modes**: default, auto_edit, yolo, plan
- **Rich aliases**: Model-specific and quick action shortcuts

## Installation

Add `gemini-cli` to your plugins array in `.zshrc`:

```zsh
plugins=(... gemini-cli)
```

## Requirements

- Gemini CLI must be installed

## Commands

| Command | Description |
|---------|-------------|
| `gemini mcp` | Manage MCP servers |
| `gemini extensions` | Manage extensions |
| `gemini skills` | Manage agent skills |

## Global Options

- `--debug`, `-d` - Debug mode
- `--model`, `-m` - Model selection
- `--prompt`, `-p` - Non-interactive mode
- `--prompt-interactive`, `-i` - Execute and continue
- `--sandbox`, `-s` - Run in sandbox
- `--approval-mode` - Approval mode (default, auto_edit, yolo, plan)
- `--yolo`, `-y` - Auto-approve all
- `--extensions`, `-e` - Extensions to use
- `--list-extensions`, `-l` - List extensions
- `--resume`, `-r` - Resume session
- `--list-sessions` - List sessions
- `--experimental-acp` - ACP mode

## Models

| Model | Description |
|-------|-------------|
| `gemini-2.5-pro` | Gemini 2.5 Pro |
| `gemini-2.0-flash` | Gemini 2.0 Flash |
| `gemini-2.0-flash-lite` | Gemini 2.0 Flash Lite |
| `gemini-1.5-pro` | Gemini 1.5 Pro |
| `gemini-1.5-flash` | Gemini 1.5 Flash |
| `gemini-1.5-flash-8b` | Gemini 1.5 Flash 8B |
| `gemini-exp` | Experimental |

## Approval Modes

| Mode | Description |
|------|-------------|
| `default` | Prompt for approval |
| `auto_edit` | Auto-approve edits |
| `yolo` | Auto-approve all |
| `plan` | Read-only mode |

## Skills

| Skill | Description |
|-------|-------------|
| `code` | Code generation |
| `debug` | Debugging |
| `explain` | Code explanation |
| `test` | Test generation |
| `doc` | Documentation |
| `review` | Code review |

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `g` | `gemini` | Short form |
| `gm` | `gemini` | Short form |
| `gmi` | `gemini` | Short form |
| `gyolo` | `gemini --yolo` | YOLO mode |
| `gplan` | `gemini --approval-mode plan` | Plan mode |
| `gauto` | `gemini --approval-mode auto_edit` | Auto edit |
| `gpro` | `gemini --model gemini-2.5-pro` | Pro model |
| `gflash` | `gemini --model gemini-2.0-flash` | Flash model |
| `glite` | `gemini --model gemini-2.0-flash-lite` | Lite model |
| `gfix` | `gemini -p "Fix this code"` | Quick fix |
| `gtest` | `gemini -p "Write tests"` | Quick test |
| `gdoc` | `gemini -p "Add documentation"` | Quick doc |
| `gexplain` | `gemini -p "Explain this"` | Quick explain |
| `grefactor` | `gemini -p "Refactor this"` | Quick refactor |
| `greview` | `gemini -p "Review this"` | Quick review |
| `gresume` | `gemini --resume latest` | Resume latest |
| `gr` | `gemini --resume` | Resume |

## Extensions Management

```zsh
gemini extensions list          # List extensions
gemini extensions install       # Install extension
gemini extensions uninstall     # Uninstall extension
gemini extensions enable        # Enable extension
gemini extensions disable       # Disable extension
gemini extensions update        # Update extensions
```

## Skills Management

```zsh
gemini skills list              # List skills
gemini skills enable            # Enable skill
gemini skills disable           # Disable skill
gemini skills info              # Show skill info
```
