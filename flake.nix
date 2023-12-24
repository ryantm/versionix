{
  outputs = {self}: {
    lib.versionix = {
      nixpkgs,
      self,
      attrpath,
      unwrapped,
    }: let
      pkgs = nixpkgs.legacyPackages.${unwrapped.system};
      long_rev = self.rev or "dirty";
      rev = "0.0.0-${builtins.substring 0 7 long_rev}";
    in
      (pkgs.writeShellApplication {
        name = unwrapped.name;
        text = ''
          export VERSION="${rev}"
          exec "${unwrapped}/bin/${unwrapped.meta.mainProgram}" "$@"
        '';
      })
      .overrideAttrs (_: _: {
        passthru = {
          inherit unwrapped;
          didChange = pkgs.writeShellApplication {
            name = "did-change";
            runtimeInputs = [pkgs.nix];
            text = ''
              OTHER_REV=$1
              OTHER_OUTPATH=$(nix eval --raw ".?rev=''${OTHER_REV}#${attrpath}.unwrapped.outPath")
              OUTPATH=${unwrapped.outPath}
              test ! "$OTHER_OUTPATH" = "$OUTPATH"
            '';
          };
        };
      });
  };
}
