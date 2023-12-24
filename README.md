# versionix

Provide a git-based rev version to binaries via the VERSION environment variable, and a way to see if the unwrapped binary has changed compared to a different rev.

# Example usage

```
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  inputs.systems.url = "github:nix-systems/default";
  inputs.versionix.url = "/home/ryantm/p/versionix";
  outputs = {
    self,
    nixpkgs,
    systems,
    versionix,
  }: let
    eachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    packages = eachSystem (system: rec {
      default = print-version;
      print-version = versionix.lib.versionix self "print-version" (nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = "print-version";
        text = ''
          echo "$VERSION"
        '';
      });
    });
  };
}
```

Running the wrapped binary:

```
$ nix run .#print-version
0.0.0-5881273
```

Checking if the unwrapped binary changed compared to a previous rev:

```
nix run .#print-version.didChange 5881273bbf0beb55a8e1187b3ebbfce4e5d94e5c
$ echo $?
0
```

If the unwrapped binary's outPath is differnet from the outPath in the provided rev, the exit code is 0. If they are the same, the exit code is 1.
