# make

This plugin provides enhanced completion and aliases for [GNU Make](https://www.gnu.org/software/make/).

To use it, add `make` to the plugins array in your zshrc file:

```zsh
plugins=(... make)
```

## Features

- **Target completions**: Parse Makefile for targets
- **Variable completions**: Complete make variables
- **Recursive Makefile discovery**: Find Makefile in parent directories
- **Documented targets**: Show help for documented targets (## comments)

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `m` | `make` | Make shorthand |
| `mb` | `make build` | Build target |
| `mc` | `make clean` | Clean target |
| `mt` | `make test` | Test target |
| `mi` | `make install` | Install target |
| `mr` | `make run` | Run target |
| `mj` | `make -j` | Parallel make |
| `mj4` | `make -j4` | 4 parallel jobs |
| `mn` | `make -n` | Dry run |
| `ms` | `make -s` | Silent make |
| `mdbg` | `make --debug` | Debug make |

## Functions

- `make-list [makefile]` - List all targets
- `make-help [makefile]` - Show documented targets
- `make-where <target>` - Find which Makefile defines target
- `make-init [name] [c/cpp]` - Create basic Makefile
- `make-compdb` - Generate compile_commands.json
