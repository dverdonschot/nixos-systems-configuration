{
  # based on https://github.com/jonringer/nixpkgs-config/blob/master/flake.nix
  description = "Home-manager configuration";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, home-manager, nixpkgs, utils }:
    let
      pkgsForSystem = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      mkHomeConfiguration = args: home-manager.lib.homeManagerConfiguration (rec {
        modules = [ (import ../home-manager/home.nix) ] ++ (args.modules or []);
        pkgs = pkgsForSystem (args.system or "x86_64-linux");
      } // { inherit (args) extraSpecialArgs; });

    in utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ] (system: rec {
      legacyPackages = pkgsForSystem system;
  }) // {
    nixosModules.home = import ../home-manager/home.nix; # attr set or list

    homeConfigurations.fedora = mkHomeConfiguration {
      extraSpecialArgs = {
        #withGUI = true;
      };
    };

    inherit home-manager;
    inherit (home-manager) packages;
  };
}
