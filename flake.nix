{
  inputs = {
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-analyzer-src.follows = "";
    };
    import-tree.url = "github:vic/import-tree";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:ink-splatters/nix-systems"; # no x86_64-darwin
  };

  nixConfig = {
    extra-substituters = [
      "https://aarch64-darwin.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "aarch64-darwin.cachix.org-1:jhPAVtbRw3N4AMjbpAiAlm2gG59yb/9U2qnqpB7NhDc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} (top @ {lib, ...}: let
      importTree = inputs.import-tree;
      systems = import inputs.systems;
      flakeModules.default = import ./nix {inherit importTree;};
    in {
      imports = [
        flakeModules.default
        flake-parts.flakeModules.partitions
      ];

      options = {
        name = lib.mkOption {
          type = lib.types.str;
        };
        src = lib.mkOption {
          type = lib.types.path;
        };
      };
      config = {
        native = "apple-m1";

        inherit systems;

        name = "solana-cli";
        src = builtins.path {
          path = ./.;
          inherit (top.config) name;
        };

        partitionedAttrs = {
          apps = "dev";
          checks = "dev";
          devShells = "dev";
          formatter = "dev";
        };
        partitions.dev = let
          dev = import ./nix/dev {inherit importTree;};
        in {
          extraInputsFlake = ./nix/dev;
          module.imports = [dev];
        };

        perSystem = {config, ...}: {
          packages.default = config.packages.solana-cli;
        };

        flake = {inherit flakeModules;};
      };
    });
}
