{
  outputs = {
    self,
  }: {
    lib.versionix = pkgs: self: attrpath: drv: let
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
            PREV_REV=$1
            PREV_OUTPATH=$(nix eval --raw ".?rev=''${PREV_REV}#${attrpath}.drv.outPath")
            CUR_OUTPATH=${drv.outPath}
            test ! "$PREV_OUTPATH" = "$CUR_OUTPATH"
          '';
        };
      };
    });
  };
}
