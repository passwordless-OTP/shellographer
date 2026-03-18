# pnpm

This plugin provides completion and aliases for [pnpm](https://pnpm.io/), the fast, disk space efficient package manager.

To use it, add `pnpm` to the plugins array in your zshrc file:

```zsh
plugins=(... pnpm)
```

## Features

- **Dynamic completions**: package.json scripts, workspace packages, filter patterns
- **Cache-aware**: completions refresh automatically
- **Monorepo support**: workspace and filter completions

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `pn` | `pnpm` | pnpm shorthand |
| `pna` | `pnpm add` | Add packages |
| `pnad` | `pnpm add --save-dev` | Add dev dependency |
| `pnap` | `pnpm add --save-peer` | Add peer dependency |
| `pnb` | `pnpm build` | Run build script |
| `pni` | `pnpm init` | Initialize project |
| `pnin` | `pnpm install` | Install dependencies |
| `pnr` | `pnpm run` | Run script |
| `pnrb` | `pnpm run build` | Run build |
| `pnrd` | `pnpm run dev` | Run dev |
| `pnrm` | `pnpm remove` | Remove package |
| `pns` | `pnpm start` | Run start |
| `pnt` | `pnpm test` | Run test |
| `pnw` | `pnpm workspace` | Workspace command |
| `pnfw` | `pnpm --filter` | Filter command |
| `pnR` | `pnpm --recursive` | Recursive command |

## Functions

- `pnpm-changed [cmd]` - Run command in changed packages
- `pnpm-all [cmd]` - Run command in all workspace packages
- `pnpm-deep-clean` - Clean store and reinstall
- `pnpm-init-workspace` - Create pnpm-workspace.yaml
