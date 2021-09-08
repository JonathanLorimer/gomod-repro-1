{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gomod2nix.url = "github:tweag/gomod2nix";
    regen-src = {
      flake = false;
      url = github:regen-network/regen-ledger;
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , gomod2nix
    , regen-src
    }:
    let
      overlays = [ gomod2nix.overlay ];
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system overlays; };
        genGomod = pkgs.writeShellScriptBin "genGomod" ''
          SOURCE_HOME=$(pwd)
          mkdir "$SOURCE_HOME/tmp"
          cd tmp
          cp -r ${regen-src}/* "$SOURCE_HOME/tmp"
          ${pkgs.gomod2nix}/bin/gomod2nix
          cd "$SOURC_HOME"
          mv "$SOURCE_HOME/tmp/gomod2nix.toml" "$SOURCE_HOME/go-modules.toml"
        '';
      in
      rec {
        # nix build .#<app>
        packages = flake-utils.lib.flattenTree
          { regen = pkgs.buildGoApplication {
              name = "regen";
              src = "${regen-src}";
              modules = ./go-modules.toml;
            };
          };


      devShell =
        pkgs.mkShell {
          buildInputs = [ genGomod ];
        };

        apps.regen = flake-utils.lib.mkApp { name = "regen"; drv = packages.regen; };
      });
}
