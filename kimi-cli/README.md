# Kimi CLI

This plugin provides comprehensive tab completion and aliases for [Kimi](https://www.moonshot.cn/) - Moonshot AI's CLI agent.

## Features

- **Dynamic completions**: Sessions, models, and modes
- **Subcommand support**: chat, run, config, session, model
- **Context-aware**: Smart suggestions based on context
- **Rich aliases**: Mode-specific and quick action shortcuts

## Installation

Add `kimi-cli` to your plugins array in `.zshrc`:

```zsh
plugins=(... kimi-cli)
```

## Requirements

- Kimi CLI must be installed

## Commands

| Command | Description |
|---------|-------------|
| `kimi chat` | Start interactive chat |
| `kimi run` | Run with prompt |
| `kimi config` | Manage configuration |
| `kimi session` | Manage sessions |
| `kimi model` | Model management |

## Global Options

- `--verbose` - Verbose output
- `--debug` - Debug logging
- `--work-dir`, `-w` - Working directory
- `--session`, `-S` - Resume session
- `--continue`, `-C` - Continue current session
- `--add-dir` - Additional workspace directories

## Models

- `moonshot-v1-8k` - 8K context
- `moonshot-v1-32k` - 32K context
- `moonshot-v1-128k` - 128K context
- `kimi-latest` - Latest model
- `kimi-k2` - K2 model

## Modes

- `agent` - Full agent mode with tool use
- `chat` - Simple chat mode
- `code` - Code-focused mode

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `k` | `kimi` | Short form |
| `kc` | `kimi chat` | Chat mode |
| `kcc` | `kimi chat --continue` | Continue chat |
| `kr` | `kimi run` | Run mode |
| `ks` | `kimi session` | Sessions |
| `ksl` | `kimi session list` | List sessions |
| `ksr` | `kimi session resume` | Resume session |
| `ka` | `kimi --mode agent` | Agent mode |
| `kcode` | `kimi --mode code` | Code mode |
| `kchat` | `kimi --mode chat` | Chat mode |
| `kfix` | `kimi run "Fix this code"` | Quick fix |
| `kexplain` | `kimi run "Explain this"` | Quick explain |
| `ktest` | `kimi run "Write tests"` | Quick test |
| `kdoc` | `kimi run "Add documentation"` | Quick doc |
| `kk2` | `kimi --model kimi-k2` | Use K2 |
| `k8k` | `kimi --model moonshot-v1-8k` | 8K context |
| `k32k` | `kimi --model moonshot-v1-32k` | 32K context |
| `k128k` | `kimi --model moonshot-v1-128k` | 128K context |

## Configuration Keys

The `kimi config` command supports tab completion for:
- `api.key` - API key
- `api.base_url` - Base URL
- `model.default` - Default model
- `agent.mode` - Default agent mode
- `agent.auto_confirm` - Auto-confirm actions
- `editor.default` - Default editor
- `output.format` - Default output format
- `session.save_dir` - Session directory
