{
  outputs = {self}: {
    lib.versionix = {
      nixpkgs,
      self,
      attrpath,
      unwrapped,
    }: let
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
          didChange = pkgs.writeShellApplication {
            name = "did-change";
            runtimeInputs = [pkgs.nix];
            text = ''
              OTHER_REV=$1
              OTHER_OUTPATH=$(nix eval --raw ".?rev=''${OTHER_REV}#${attrpath}.drv.outPath")
              OUTPATH=${drv.outPath}
              test ! "$OTHER_OUTPATH" = "OUTPATH"
            '';
          };
        };
      });
  };
}
