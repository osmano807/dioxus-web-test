A template Dioxus Fullstack Rust project with fully functional and no-frills Nix support, as well as builtin VSCode configuration to get IDE experience without any manual setup (just [install direnv](https://nixos.asia/en/direnv), open in VSCode and accept the suggestions).

>[!NOTE]  
> If you are looking for the original template see [rust-nix-template](https://github.com/srid/rust-nix-template/releases).

## Adapting this template

- Run `nix develop` to have a working shell ready before name change.
- Change `name` in Cargo.toml.
- Run `cargo generate-lockfile` in the nix shell
- There are two CI workflows, and one of them uses Nix which is slower (unless you configure a cache) than the other that is based on rustup. Pick one or the other depending on your trade-offs.

## Development (Flakes)

This repo uses [Flakes](https://nixos.wiki/wiki/Flakes) from the get-go.

```bash
# Dev shell
nix develop

# or run via cargo
nix develop -c cargo run

# build
nix build
```

We also provide a [`justfile`](https://just.systems/) for Makefile'esque commands.

For now, not fully tested builds using `nix build`, currently experimenting with `justfile`. Adapt as you need.

## See Also
- [rust-nix-template](https://github.com/srid/rust-nix-template/releases)
- [fenix Rust toolchains](https://github.com/nix-community/fenix)
- [nixos.wiki: Packaging Rust projects with nix](https://nixos.wiki/wiki/Rust#Packaging_Rust_projects_with_nix)
