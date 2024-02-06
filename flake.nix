{
  description = ''
    A sample flake that shows how Home Manager module can be turned into a package.

    To run:

    ```
    nix run .#helix
    ```
  '';

  inputs.home-manager.url = "github:rycee/home-manager";

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;
        in
        {
          helix =
            (builtins.head
              (import (self.inputs.home-manager + "/modules/programs/helix.nix") {
                inherit pkgs;

                lib = lib // self.inputs.home-manager.lib;

                inherit
                  (lib.evalModules {
                    specialArgs = {
                      inherit pkgs;
                    };
                    modules = [
                      self.inputs.home-manager.nixosModules.home-manager
                      { _module.check = false; } # This skips some checks that can be (apparently) safely bypassed

                      (self.inputs.home-manager + "/modules/programs/helix.nix") # This module is needed to pass the default values taken from options
                      {
                        # The configuration section
                        programs.helix = {
                          enable = true;
                          extraPackages = [
                            pkgs.nls # A sample package to be exposed to Helix
                          ];
                        };
                      }
                    ];
                  })
                  config
                  ;
              }).config.content.home.packages
            )
            // {
              meta.mainProgram = "hx"; # Seems to be specific to helix, for some reason the resulting binary is "hx"
            };
        }
      );
    };
}
