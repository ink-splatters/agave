{
  perSystem = {config, ...}: let
    inherit
      (config)
      craneLib
      commonArgs
      commonArgsNative
      cargoArtifacts
      cargoArtifactsNative
      ;
  in {
    packages = {
      solana-cli = craneLib.buildPackage (commonArgs
        // {
          inherit cargoArtifacts;
          doCheck = false;
        });

      solana-cli-native = craneLib.buildPackage (commonArgsNative
        // {
          cargoArtifacts = cargoArtifactsNative;
          doCheck = false;
        });
    };
  };
}
