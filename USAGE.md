# Shellographer Usage Guide

## Quick Start

### 1. Install

```bash
git clone https://github.com/passwordless-OTP/shellographer.git \
  ~/.oh-my-zsh/custom/plugins/shellographer
```

Add to `~/.zshrc`:
```zsh
plugins=(shellographer)
```

Reload:
```zsh
source ~/.zshrc
```

### 2. Discover Commands

Type a service name and hit **Tab** twice:

```zsh
$ wrangler-<Tab><Tab>
wrangler-deploy-worker    wrangler-kv-list
wrangler-dev-server       wrangler-r2-list
wrangler-kv-get           wrangler-secrets-list
wrangler-kv-put           wrangler-tail
```

Progressive discovery:
```zsh
$ wrangler-kv-<Tab><Tab>
wrangler-kv-get   wrangler-kv-list   wrangler-kv-put
```

### 3. Use Aliases

```zsh
# Start dev server
$ wrangler-dev-server

# Deploy worker  
$ wrangler-deploy-worker

# List KV namespaces
$ wrangler-kv-list
```

---

## Daily Workflow Examples

### Wrangler (Cloudflare Workers)

```zsh
# Start local dev server
$ wrangler-dev-server

# In another terminal - check logs
$ wrangler-tail

# Deploy to production
$ wrangler-deploy-worker

# List KV namespaces
$ wrangler-kv-list

# Get a value from KV
$ wrangler-kv-get MY_KEY --namespace-id=xxx
```

### GitHub CLI

```zsh
# Create a PR
$ gh-pr-create

# Checkout a PR
$ gh-pr-checkout 123

# Merge a PR
$ gh-pr-merge 123

# View PR in browser
$ gh-pr-view

# List open issues
$ gh-issue-list
```

### Docker

```zsh
# List running containers
$ docker-container-list

# List all containers
$ docker-container-list-all

# Exec into container
$ docker-container-exec mycontainer bash

# Build image
$ docker-image-build -t myapp:latest .

# Compose up
$ docker-compose-up
```

---

## Discovery with `caps`

List all available services:
```zsh
$ caps
gh       docker   wrangler
```

List commands for a service:
```zsh
$ caps wrangler
wrangler-deploy-worker   Deploy worker to Cloudflare
wrangler-dev-server      Start local dev server
wrangler-kv-get          Get KV value
wrangler-kv-list         List KV namespaces
wrangler-kv-put          Put KV value
wrangler-r2-list         List R2 buckets
wrangler-secrets-list    List worker secrets
wrangler-tail            Stream worker logs
```

---

## Configuration

### Customize Loaded Plugins

By default: `wrangler gh docker`

Override in `~/.zshrc`:
```zsh
# Load only specific plugins
SHELLOGRAPHER_PLUGINS="wrangler gh"
plugins=(shellographer)
```

### Enable Debug Mode

See what's happening under the hood:
```zsh
# In ~/.zshrc
SHELLOGRAPHER_DEBUG=1
plugins=(shellographer)
```

Example output:
```
[shellographer] Skip: gh-pr-create (function exists)
[shellographer] Created: wrangler-dev-server
```

### Disable Plugins

Remove from list:
```zsh
SHELLOGRAPHER_PLUGINS="gh docker"  # No wrangler
```

---

## Troubleshooting

### .zshrc won't load

```zsh
# Test in isolation
zsh -c "source ~/.zshrc; echo 'OK'"

# Enable debug mode
SHELLOGRAPHER_DEBUG=1
```

### Alias conflicts

If you have existing functions with the same name:

```zsh
# Your existing function takes priority
gh-pr-create() { echo "my custom function"; }

# Shellographer skips the alias (see debug output)
```

To use shellographer's alias instead:
```zsh
# In ~/.zshrc, define BEFORE loading shellographer
unfunction gh-pr-create 2>/dev/null
plugins=(shellographer)
```

### Tab completion not working

1. Ensure compinit is loaded:
```zsh
autoload -Uz compinit && compinit
```

2. Check if alias exists:
```zsh
alias | grep wrangler
```

3. Try reloading:
```zsh
source ~/.zshrc
```

### CLI tool not found

If `wrangler`, `gh`, or `docker` is not installed:
- Shellographer loads without errors
- Aliases are not created (silently skipped)
- Install the CLI tool and reload `.zshrc`

---

## Tips

### 1. Progressive Tab Completion

Don't memorize - discover:
```
wran<Tab> → wrangler-<Tab> → wrangler-kv-<Tab>
```

### 2. Use `caps` for Discovery

Forgot an alias?
```zsh
$ caps docker
```

### 3. Combine with Other oh-my-zsh Plugins

```zsh
plugins=(git docker shellographer)
# git for git aliases
# docker for docker completions
# shellographer for enhanced docker aliases
```

### 4. Override Individual Aliases

Define your own after shellographer loads:
```zsh
plugins=(shellographer)

# Override specific alias
alias wrangler-dev-server="wrangler dev --local-protocol=https"
```

---

## Uninstall

```bash
# Remove plugin
rm -rf ~/.oh-my-zsh/custom/plugins/shellographer

# Remove from ~/.zshrc
# Edit file and remove 'shellographer' from plugins=()
```

---

## Philosophy

**Don't memorize. Discover.**

Shellographer aliases follow the pattern:
```
<service>-<action>-<resource>
```

- `wrangler` (service) + `dev` (action) + `server` (resource)
- `gh` (service) + `pr` (resource) + `create` (action)

Just start typing the service, hit Tab, and explore.
