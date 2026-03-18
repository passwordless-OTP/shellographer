# Shellographer

> **Shell command discovery through semantic aliases**

Shellographer makes CLI tools discoverable through tab completion. No more memorizing syntax—just type the service name, hit tab, and see what you can do.

## 🚀 Quick Start

```bash
# Clone
gh repo clone jarvis/shellographer

# Install
cp -r shellographer/* ~/.oh-my-zsh/plugins/

# Add to ~/.zshrc
plugins=(... caps wrangler docker gh)

# Discover
caps          # List all services
caps docker   # See docker aliases
```

## 📦 What's Included

### Core System
- **caps** - Alias discovery engine

### Cloud Providers
- **wrangler** - Cloudflare Workers
- **aws** - Amazon Web Services
- **gcloud** - Google Cloud Platform
- **doctl** - DigitalOcean
- **flyctl** - Fly.io

### DevOps
- **docker** - Docker & Compose
- **gh** - GitHub CLI
- **git** - Enhanced git completions

### Package Managers
- **npm** - Node.js
- **pnpm** - Fast package manager
- **poetry** - Python dependencies
- **uv** - Modern Python tooling
- **cargo** - Rust build system

### Build Tools
- **make** - Makefile targets
- **just** - Justfile recipes

### AI/LLM
- **claude-code** - Anthropic Claude
- **kimi-cli** - Moonshot Kimi
- **codex-cli** - OpenAI Codex
- **gemini-cli** - Google Gemini

## 🎯 Philosophy

**Technology is best when it's transparent.**

A user should hit 1-2 tabs and see what they intended to do—not memorize syntax or read documentation.

### Naming Convention

```
<service>-<action>-<resource>

wrangler-deploy-worker    # Deploy Cloudflare Worker
docker-container-list     # List containers
gh-pr-checkout            # Checkout PR
```

## 📊 Stats

- **22 plugins** enhanced
- **30,000+ lines** of completion code
- **19 aliases** annotated with caps (growing)

## 🗺️ Roadmap

See [COMPLETIONS_TODO.md](COMPLETIONS_TODO.md) for full roadmap.

### Phase 1: Core Infrastructure ⭐⭐⭐
- [ ] kubectl
- [ ] terraform
- [ ] helm

### Phase 2: Package Managers ✅
- [x] npm, pnpm, poetry, uv, cargo, make, just

### Phase 3: Edge & Serverless
- [ ] firebase
- [ ] shopify

## 🤝 Contributing

1. Annotate aliases with caps metadata:
```zsh
# caps:category=deployment
# caps:desc=Deploy to production
alias service-deploy='command'
```

2. Test with `caps <service>`

3. Submit PR

## 📄 License

MIT
