{lib, ...}: {
  perSystem = {config, ...}: let
    inherit (config) craneLib commonArgs commonArgsNative;
    dummySrc = craneLib.mkDummySrc (commonArgs
      // {
        # Crane does not stub auto-discovered tests in test-only workspace crates.
        extraDummyScript = ''
          mkdir -p \
            "$out/client-test/tests" \
            "$out/programs/bpf-loader-tests/tests" \
            "$out/programs/ed25519-tests/tests" \
            "$out/programs/zk-elgamal-proof-tests/tests" \
            "$out/rpc-test/tests"
          touch "$out/client-test/tests/client.rs"
          touch "$out/programs/bpf-loader-tests/tests/common.rs"
          touch "$out/programs/ed25519-tests/tests/process_transaction.rs"
          touch "$out/programs/zk-elgamal-proof-tests/tests/process_transaction.rs"
          touch "$out/rpc-test/tests/rpc.rs"
        '';
      });
    mkArtifactsArgs = args:
      (builtins.removeAttrs args ["src"])
      // {
        inherit dummySrc;
        doCheck = false;
        buildPhaseCargoCommand = "cargoWithProfile build ${args.cargoExtraArgs}";
      };
  in {
    options = {
      cargoArtifacts = lib.mkOption {
        type = lib.types.package;
        default = craneLib.buildDepsOnly (mkArtifactsArgs commonArgs
          // {
            pname = "solana-cli";
            # Include dev dependencies for clippy offline mode:
            # cargoCheckExtraArgs = "--all-targets --all-features";
          });
      };
      cargoArtifactsNative = lib.mkOption {
        type = lib.types.package;
        default = craneLib.buildDepsOnly (mkArtifactsArgs commonArgsNative
          // {
            pname = "solana-cli-native";
          });
      };
    };
  };
}
