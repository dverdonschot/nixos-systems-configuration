{
    description = "workstation flake";

    inputs = {
      home-manager.url = "github:nix-community/home-manager/master";
      home-manager.inputs.nixpkgs.follows = "nixpkgs"; # Use system packages list where available
      microvm.url = "github:astro/microvm.nix";
      nixpkgs.url = "nixpkgs/nixos-unstable";
      faasd-nix.url = "github:welteki/faasd-nix";
    };

    outputs = {self, nixpkgs, microvm, ...}@inputs:
      let
        lib = nixpkgs.lib;
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          specialArgs = { 
            inherit inputs; 
            userName = "ewt";
            userEmail = "36795362+dverdonschot@users.noreply.github.com";
          };
          config = { allowUnfree = true; };
        };
      in rec {
        nixosConfigurations = {
          workstation = lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              userName = "ewt";
              userEmail = "36795362+dverdonschot@users.noreply.github.com"; 
            };
            modules = [ 
              ./hosts/workstation/configuration.nix
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ewt = import ./home-manager/home.nix;
              }
            ];
          };
          laptop76 = lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              userName = "ewt";
              userEmail = "36795362+dverdonschot@users.noreply.github.com"; 
            };
            modules = [ 
              ./hosts/laptop76/configuration.nix
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ewt = import ./home-manager/laptop76-home.nix;
              }
            ];
          };
          um790 = lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              userName = "ewt";
              userEmail = "36795362+dverdonschot@users.noreply.github.com"; 
            };
            modules = [ 
              ./hosts/um790/configuration.nix
              #inputs.home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ewt = import ./home-manager/home.nix;
              }
            ];
          };
          odroid = lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              userName = "ewt";
              userEmail = "36795362+dverdonschot@users.noreply.github.com";
            };
            modules = [
              ./hosts/odroid/configuration.nix
              inputs.home-manager.nixosModules.home-manager
              inputs.faasd-nix.nixosModules.default
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ewt = import ./home-manager/home-minimal.nix;
              }
            ];
          };
          wsl = lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              userName = "nixos";
              userEmail = "36795362+dverdonschot@users.noreply.github.com"; 
            };
            modules = [ 
              ./hosts/wsl/configuration.nix
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.nixos = import ./home-manager/home-nix.nix;
              }
            ];
          };
        };
    };
}
