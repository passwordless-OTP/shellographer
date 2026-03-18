# cargo

This plugin provides enhanced completion and aliases for [Cargo](https://doc.rust-lang.org/cargo/), the Rust package manager and build system.

To use it, add `cargo` to the plugins array in your zshrc file:

```zsh
plugins=(... cargo)
```

## Features

- **Feature flag completions**: Complete Cargo.toml features
- **Target completions**: Complete binary/example/test targets
- **Test name completions**: Complete test functions
- **Triple target completions**: Complete architecture targets
- **Dependency completions**: Complete Cargo.toml dependencies

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `cb` | `cargo build` | Build project |
| `cbr` | `cargo build --release` | Build release |
| `cc` | `cargo check` | Check project |
| `ccl` | `cargo clippy` | Run clippy |
| `cf` | `cargo fmt` | Format code |
| `cn` | `cargo new` | New project |
| `cr` | `cargo run` | Run project |
| `ct` | `cargo test` | Run tests |
| `cu` | `cargo update` | Update deps |
| `cx` | `cargo clean` | Clean build |
| `cbw` | `cargo build --workspace` | Build workspace |
| `ctall` | `cargo test --all-features` | Test all features |
| `cbnf` | `cargo build --no-default-features` | Build without default features |
| `rup` | `rustup update` | Update rustup |

## Functions

- `cbrun` - Build and run release binary
- `check-all-features` - Check each feature individually
- `clippy-all` - Run clippy with all features
- `clean-deep` - Clean everything including backups
- `rust-init [name] [--lib]` - Initialize new Rust project
