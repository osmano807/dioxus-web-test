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
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import inputs.systems;
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      perSystem = {
        config,
        self',
        pkgs,
        lib,
        system,
        ...
      }: let
        cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        nonRustDeps = [
          pkgs.libiconv
        ];
        fenixPkgs = inputs.fenix.packages.${system};

        fenix-channel = fenixPkgs.latest;
        # rust targets
        fenix-targets = with fenixPkgs.targets; [
          x86_64-unknown-linux-gnu.latest.rust-std
          wasm32-unknown-unknown.latest.rust-std
        ];

        fenix-toolchain = fenixPkgs.combine ([
            fenix-channel.rustc
            fenix-channel.cargo
            fenix-channel.clippy
            fenix-channel.rust-analysis
            fenix-channel.rust-src
            fenix-channel.rustfmt
            #fenix-channel.llvm-tools-preview
          ]
          ++ fenix-targets);

        rust-toolchain = fenix-toolchain;
        rustPlatform = pkgs.makeRustPlatform {
          cargo = fenix-toolchain;
          rustc = fenix-toolchain;
        };
      in {
        # Rust package
        packages.default = rustPlatform.buildRustPackage {
          inherit (cargoToml.package) name version;
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
        };

        # TODO: refactor
        packages.dioxus-cli =
          rustPlatform.buildRustPackage
          rec {
            pname = "dioxus-cli";
            version = "0.4.3";

            src = pkgs.fetchCrate {
              inherit pname version;
              hash = "sha256-TWcuEobYH2xpuwB1S63HoP/WjH3zHXTnlXXvOcYIZG8=";
            };

            cargoHash = "sha256-ozbGK46uq3qXZifyTY7DDX1+vQuDJuSOJZw35vwcuxY=";

            nativeBuildInputs = [pkgs.pkg-config pkgs.cacert];
            buildInputs = [pkgs.openssl];

            OPENSSL_NO_VENDOR = 1;

            checkFlags = [
              # requires network access
              "--skip=server::web::proxy::test::add_proxy"
              "--skip=server::web::proxy::test::add_proxy_trailing_slash"
            ];

            # Omitted: --doc
            # Can be removed after 0.4.3 or when https://github.com/DioxusLabs/dioxus/pull/1706 is resolved
            # Matches upstream package test CI https://github.com/DioxusLabs/dioxus/blob/544ca5559654c8490ce444c3cbd85c1bfb8479da/Makefile.toml#L94-L108
            cargoTestFlags = [
              "--lib"
              "--bins"
              "--tests"
              "--examples"
            ];

            meta = with lib; {
              homepage = "https://dioxuslabs.com";
              description = "CLI tool for developing, testing, and publishing Dioxus apps";
              license = with licenses; [mit asl20];
              maintainers = with maintainers; [xanderio cathalmullan];
              mainProgram = "dx";
            };
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
            nixd
            # Using locally build dioxus-cli files a strange bug with wasm-bindgen mismatch
            # like this https://github.com/rustwasm/wasm-bindgen/discussions/3515
            self'.packages.dioxus-cli
          ];
          RUST_BACKTRACE = 1;
          # For rust-analyzer 'hover' tooltips to work.
          RUST_SRC_PATH = "${fenix-channel.rust-src}/lib/rustlib/src/rust/library";
        };

        # Add your auto-formatters here.
        # cf. https://numtide.github.io/treefmt/
        treefmt.config = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            rustfmt.enable = true;
          };
        };
      };
    };
}
