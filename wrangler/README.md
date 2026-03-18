# wrangler

This plugin provides completion and aliases for [Wrangler](https://developers.cloudflare.com/workers/wrangler/), the Cloudflare Workers CLI.

To use it, add `wrangler` to the plugins array in your zshrc file:

```zsh
plugins=(... wrangler)
```

## Features

- **Wrangler.toml parsing**: Auto-completes environments, scripts, KV namespaces, D1 databases, R2 buckets
- **Cloudflare API integration**: Cached account and script lists
- **Hierarchical completions**: Routes, compatibility dates, log levels
- **Monorepo support**: Finds wrangler.toml in parent directories

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `w` | `wrangler` | Wrangler shorthand |
| `wd` | `wrangler dev` | Start dev server |
| `wdp` | `wrangler deploy` | Deploy worker |
| `wtail` | `wrangler tail` | Tail logs |
| `wkv` | `wrangler kv` | KV commands |
| `wd1` | `wrangler d1` | D1 database commands |
| `wr2` | `wrangler r2` | R2 storage commands |
| `wdev` | `wrangler dev --local` | Local dev mode |
| `wdevr` | `wrangler dev --remote` | Remote dev mode |
| `wdry` | `wrangler deploy --dry-run` | Dry run deploy |

## Functions

- `wdeploy-msg <message>` - Deploy with custom message
- `wd1-migrate <name>` - Create D1 migration
- `wkv-keys <binding> [prefix]` - List KV keys
- `wd1-export <db> [file.sql]` - Export database to SQL
- `wtail-search <term>` - Tail with search filter
- `winfo` - Show wrangler config summary
- `winit <name> [type]` - Initialize new project

## Completion Examples

```zsh
wrangler dev --env <tab>          # Complete environments from wrangler.toml
wrangler kv key get --binding <tab> # Complete KV namespace bindings
wrangler d1 execute --name <tab>    # Complete D1 database names
wrangler deploy <tab>               # Complete entry scripts
```

## Requirements

- Wrangler CLI installed (`npm install -g wrangler`)
- Python 3 for TOML parsing (optional, falls back gracefully)
