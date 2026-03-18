# just

This plugin provides enhanced completion and aliases for [just](https://github.com/casey/just), a handy way to save and run project-specific commands.

To use it, add `just` to the plugins array in your zshrc file:

```zsh
plugins=(... just)
```

## Features

- **Recipe completions**: Parse Justfile for recipes
- **Variable completions**: Complete just variables
- **Recursive Justfile discovery**: Find Justfile in parent directories
- **Documented recipes**: Show help for documented recipes (# comments)

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `j` | `just` | Just shorthand |
| `jl` | `just --list` | List recipes |
| `js` | `just --summary` | Show summary |
| `je` | `just --edit` | Edit Justfile |
| `jd` | `just --dump` | Dump Justfile |
| `jf` | `just --fmt` | Format Justfile |
| `ji` | `just --init` | Init new Justfile |
| `jn` | `just --dry-run` | Dry run |
| `jv` | `just --verbose` | Verbose mode |
| `jb` | `just build` | Build recipe |
| `jt` | `just test` | Test recipe |
| `jc` | `just clean` | Clean recipe |
| `jrun` | `just run` | Run recipe |
| `jdev` | `just dev` | Dev recipe |

## Functions

- `just-list [justfile]` - List all recipes
- `just-help [justfile]` - Show documented recipes
- `just-edit [justfile]` - Edit the Justfile
- `just-show <recipe>` - Show recipe source
- `just-watch [recipe]` - Watch and re-run on changes
- `just-init [name] [lang]` - Create Justfile for language
- `just-dev-init` - Create Justfile with dev recipes

## Just Init Languages

The `just-init` function supports:
- `rust`/`cargo` - Rust projects
- `python`/`py`/`uv` - Python projects
- `node`/`js`/`npm`/`pnpm` - Node.js projects
- `go`/`golang` - Go projects
- `generic` (default) - Generic template

Example:
```zsh
just-init myproject rust
```
