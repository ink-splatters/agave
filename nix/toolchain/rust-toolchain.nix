{
  inputs,
  lib,
  ...
}: {
  # The monthly Fenix pin predates its stdenv platform deprecation fix.
  # https://github.com/nix-community/fenix/commit/b9c35c531d33e4775d222a6ac0de515750ee05fb
  perInput = system: input:
    lib.optionalAttrs (input.outPath == inputs.fenix.outPath) {
      packages = lib.mkForce (let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        compatibilityPkgs =
          pkgs
          // {
            stdenv =
              pkgs.stdenv
              // {
                inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
              };
            callPackage = lib.callPackageWith compatibilityPkgs;
          };
      in
        import input.outPath {
          inherit (pkgs) lib;
          inherit system;
          pkgs = compatibilityPkgs;
          rust-analyzer-src = input.inputs.rust-analyzer-src;
        });
    };

  perSystem = {
    inputs',
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv) hostPlatform;
    inherit (inputs') fenix;

    installNameTool = lib.getExe' pkgs.darwin.cctools "install_name_tool";

    darwinRustc = fenix.packages.default.rustc-unwrapped.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + ''
          # Fenix Darwin LLVM tools can miss their bundled libLLVM rpath.
          # https://github.com/nix-community/fenix/issues/242
          ${installNameTool} -add_rpath "$out/lib" "$out/lib/rustlib/${hostPlatform.rust.rustcTarget}/bin/rust-lld"
          ${installNameTool} -add_rpath "$out/lib" "$out/lib/rustlib/${hostPlatform.rust.rustcTarget}/bin/rust-objcopy"
        '';
    });

    darwinToolchain = pkgs.symlinkJoin {
      name = "rust-mixed";
      paths =
        (with fenix.packages.default; [
          cargo
          clippy-preview-unwrapped
          rust-docs
          rust-std
          rustfmt-preview
        ])
        ++ [darwinRustc];
      postBuild = ''
        while IFS= read -r -d $'\0' file; do
          install -m 755 "$(realpath "$file")" "$file"
        done < <(find "$out/bin" -maxdepth 1 -xtype f -print0)

        while IFS= read -r -d $'\0' file; do
          install "$(realpath "$file")" "$file"
        done < <(find "$out/lib" -name 'librustc_driver-*' -xtype f -print0)
      '';
    };
  in {
    options.rust-toolchain = lib.mkOption {
      type = lib.types.package;
      default =
        if hostPlatform.isDarwin
        then darwinToolchain
        else fenix.packages.default.toolchain;
    };
  };
}
