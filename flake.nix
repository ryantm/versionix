{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  inputs.systems.url = "github:nix-systems/default";
  outputs = {
    self,
    nixpkgs,
    systems,
  }: let
    eachSystem = nixpkgs.lib.genAttrs (import systems);
    versionix = self: attrpath: drv: let
      pkgs = nixpkgs.legacyPackages.${drv.system};
      long_rev = self.rev or "dirty";
      rev = "0.0.0-${builtins.substring 0 7 long_rev}";
    in
      (pkgs.writeShellApplication {
        name = drv.name;
        text = ''
          export VERSION="${rev}"
          ${drv}/bin/${drv.meta.mainProgram}
        '';
      })
      .overrideAttrs (_: _: {
        passthru = {
          inherit drv;
          unchanged = pkgs.writeShellApplication {
            name = "did-change";
            runtimeInputs = [pkgs.nix];
            text = ''
              PREV_REV=$1
              PREV_OUTPATH=$(nix eval --raw ".?rev=''${PREV_REV}#${attrpath}.drv.outPath")
              CUR_OUTPATH=${drv.outPath}
              test "$PREV_OUTPATH" = "$CUR_OUTPATH"
            '';
          };
        };
      });
  in {
    formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.alejandra);
    lib.versionix = versionix;
    packages = eachSystem (system: {
      print-version = versionix self "print-version" (nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = "print-version";
        text = ''
          echo "$VERSION"
          echo "$VERSION"
          echo "$VERSION"
        '';
      });
    });
  };
}
