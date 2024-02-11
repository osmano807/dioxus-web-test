{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-parts.url = "flake-parts";
    systems.url = "systems";

    # Dev tools
    treefmt-nix.url = "github:numtide/treefmt-nix";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      perSystem =
        { config
        , self'
        , pkgs
        , lib
        , system
        , ...
        }:
        let
          cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
          nonRustDeps = [
            pkgs.libiconv
          ];
          fenixPkgs = inputs.fenix.packages.${system};
          fenix-toolchain = fenixPkgs.default.toolchain;

          rust-toolchain = pkgs.symlinkJoin {
            name = "rust-toolchain";
            paths = with fenixPkgs.default; [
              rustc
              cargo
              clippy
              rustfmt
              fenixPkgs.rust-analyzer
              fenixPkgs.complete.rust-src
            ];
          };
          rustPlatform = pkgs.makeRustPlatform {
            cargo = fenix-toolchain;
            rustc = fenix-toolchain;
          };
        in
        {
          # Rust package
          packages.default = rustPlatform.buildRustPackage {
            inherit (cargoToml.package) name version;
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };

          # Rust dev environment
          devShells.default = pkgs.mkShell {
            inputsFrom = [
              config.treefmt.build.devShell
            ];
            shellHook = ''
              echo
              echo "🍎🍎 Run 'just <recipe>' to get started"
              just
            '';
            buildInputs = nonRustDeps;
            nativeBuildInputs = with pkgs; [
              just
              rust-toolchain
            ];
            RUST_BACKTRACE = 1;
            # For rust-analyzer 'hover' tooltips to work.
            RUST_SRC_PATH = fenixPkgs.complete.rust-src;
          };

          # Add your auto-formatters here.
          # cf. https://numtide.github.io/treefmt/
          treefmt.config = {
            projectRootFile = "flake.nix";
            programs = {
              nixpkgs-fmt.enable = true;
              rustfmt.enable = true;
            };
          };
        };
    };
}
