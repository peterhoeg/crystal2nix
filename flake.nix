{
  description = "Crystal 2 Nix";

  inputs = {
    crystal = {
      url = "github:peterhoeg/crystal-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, crystal }:
    (with flake-utils.lib; eachSystem [ "x86_64-linux" ]) (system:
      let
        pkgs = import nixpkgs {
          overlays = [ crystal.overlay ];
          inherit system;
        };

        specFile =
          let
            base = ref: name: attrs:
              pkgs.lib.recursiveUpdate
                {
                  enabled = 1;
                  type = 1;
                  hidden = false;
                  description = "crystal2nix - ${name}";
                  checkinterval = 600;
                  schedulingshares = 1;
                  enableemail = false;
                  emailoverride = "";
                  keepnr = 3;
                  flake = "github:crystal-community/crystal2nix.git?ref=${ref}";
                }
                attrs;
          in
          (pkgs.formats.json { }).generate "hydra.json" {
            main = base "refs/heads/main" "main" { };
          };

      in
      rec {
        packages = flake-utils.lib.flattenTree rec {
          crystal2nix = pkgs.callPackage ./package.nix { };
          default = crystal2nix;
        };

        checks = flake-utils.lib.flattenTree rec {
          specs = packages.crystal2nix;
        };

        devShell = pkgs.mkShell (
          let
            drv = self.packages.${system}.crystal2nix;
          in
          {
            shellHook = ''
              install -Dm444 ${specFile} $(git rev-parse --show-toplevel)/.ci/${specFile.name}
              make meta.json
            '';

            buildInputs = drv.buildInputs ++ (with pkgs; [ ]);

            nativeBuildInputs = drv.nativeBuildInputs ++ (with pkgs; [ ]);
          }
        );

        hydraJobs = {
          build = self.packages.${system}.crystal2nix;
        };
      });
}
