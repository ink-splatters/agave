top @ {lib, ...}: let
  inherit (lib) optionals concatStringsSep toString;
  inherit (top.config) src;
in {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    inherit
      (pkgs.llvmPackages_latest)
      stdenv
      clang
      bintools
      libcxx
      ;
    inherit (stdenv.hostPlatform) isDarwin;
    inherit (config) craneLib;

    bindgenHook = pkgs.rustPlatform.bindgenHook.override {
      inherit clang;
    };
    metaInfo = craneLib.crateNameFromCargoToml {
      cargoToml = "${src}/Cargo.toml";
    };

    mkFlags = flags: concatStringsSep " " (map (x: "-C ${x}") flags);

    flags = [
      "linker=${clang}/bin/cc"
      "link-args=-fuse-ld=lld"
    ];

    CFLAGS = ["-O3 -pipe"];
    LDFLAGS = ["-fuse-ld=lld"];

    mkCommonArgs = args @ {flags, ...}:
      {
        pname = top.config.name;
        src = craneLib.cleanCargoSource src;

        inherit (metaInfo) version;
        cargoExtraArgs = concatStringsSep " " [
          "--locked"
          "-p solana-cli"
          "-p solana-keygen"
        ];
        strictDeps = true;
        enableParallelBuilding = true;
        doCheck = false;

        RUSTFLAGS = mkFlags flags;

        nativeBuildInputs = with pkgs;
          [
            pkg-config
            protobuf
          ]
          ++ optionals isDarwin [
            darwin.DarwinTools
          ]
          ++ [
            clang
            bintools
            bindgenHook
          ];

        buildInputs = with pkgs;
          [
            bzip2
            jemalloc
            libusb1
            openssl
            zstd
          ]
          ++ optionals isDarwin [
            pkgs.apple-sdk_15
            libcxx
          ];

        env = {
          OPENSSL_NO_VENDOR = true;
          ZSTD_SYS_USE_PKG_CONFIG = true;
        };

        CFLAGS = toString CFLAGS;
        LDFLAGS = toString LDFLAGS;
      }
      // (builtins.removeAttrs args ["flags"]);
  in {
    options = {
      commonArgs = lib.mkOption {
        type = lib.types.attrs;
        default = mkCommonArgs {inherit flags;};
      };

      commonArgsNative = lib.mkOption {
        type = lib.types.attrs;

        default = mkCommonArgs {
          flags = flags ++ ["target-cpu=${top.config.native}"];
          NIX_ENFORCE_NO_NATIVE = 0;

          CFLAGS = concatStringsSep " " (
            CFLAGS
            ++ ["-mcpu=${top.config.native}"]
          );
        };
      };
    };
  };
}
