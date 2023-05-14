{
  description = "osu! releases and overlay";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";
    utils.url = "flake:flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    , ...
    }: utils.lib.eachSystem [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ]
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (self: super: {
              osu-lazer-bin = super.osu-lazer-bin.overrideAttrs (old: {
                src = builtins.fetchurl {
                  url = import (./systems + "/${system}/url.nix");
                  sha256 = import (./systems + "/${system}/sha256.nix");
                };
              });
            })
          ];
        };
      in
      {
        packages = utils.lib.flattenTree ({
          osu-lazer-bin = pkgs.osu-lazer-bin;
        });
        defaultPackage = self.packages.${system}.osu-lazer-bin;
      }
      );
}
