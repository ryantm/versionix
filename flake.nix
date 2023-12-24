{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  inputs.systems.url = "github:nix-systems/default";
  outputs = {
    self,
    nixpkgs,
    systems,
  }: let
    long_rev = self.rev or "dirty";
    rev = "0.0.0-${builtins.substring 0 7 long_rev}";

    eachSystem = nixpkgs.lib.genAttrs (import systems);
    versionix = drv: let
      pkgs = nixpkgs.legacyPackages.${drv.system};
    in (pkgs.writeShellApplication {
      name = drv.name;
      text = ''
        export VERSION="${rev}"
        ${drv}/bin/print-version
      '';
    }).overrideAttrs (_: _: {
      passthru = {
        inherit drv;
        didChange = pkgs.writeShellApplication {
          name = "did-change";
          runtimeInputs = [ pkgs.nix ];
          text = ''
            PREV_REV=$1
            PREV_OUTPATH=$(nix eval --raw ".?rev=''${PREV_REV}#print-version.drv.outPath")
            CUR_OUTPATH=${drv.outPath}
            echo "$PREV_OUTPATH"
            echo "$CUR_OUTPATH"
          '';
        };
      };
    });
  in {
    formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.alejandra);

    packages = eachSystem (system: {
      print-version = versionix (nixpkgs.legacyPackages.${system}.writeShellApplication {
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
