{
    description = "workstation flake";

    inputs = {
      home-manager.url = "github:nix-community/home-manager/master";
      home-manager.inputs.nixpkgs.follows = "nixpkgs"; # Use system packages list where available
      nixpkgs.url = "nixpkgs/nixos-unstable";
    };

    outputs = {self, nixpkgs, ...}@inputs:
      let
        username = "ewt";
        lib = nixpkgs.lib;
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          specialArgs = { inherit inputs; };
          config = { allowUnfree = true; };
        };
      in rec {
        nixosConfigurations = {
          workstation = lib.nixosSystem {
            inherit system;
            specialArgs = {inherit inputs; };
            modules = [ 
              ./hosts/workstation/configuration.nix
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ewt = import hosts/workstation/home.nix;
              }
            ];
          };
          wsl = lib.nixosSystem {
            inherit system;
            specialArgs = {inherit inputs; };
            modules = [ 
              ./hosts/wsl/configuration.nix
            ];
          };
          media-server = lib.nixosSystem {
            inherit system;
            specialArgs = {inherit inputs; };
            modules = [ 
              ./hosts/media-server/configuration.nix
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ewt = import home-manager/home.nix;
              }
            ];
          };
         };
    };
}
