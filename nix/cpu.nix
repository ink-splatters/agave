{lib, ...}: {
  perSystem = {pkgs, ...}: {
    options.cpu = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default =
        if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64
        then "apple-m1"
        else null;
      description = "Baseline CPU for Rust and C compilation; null uses the target default.";
    };
  };
}
