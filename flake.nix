{
    description = "workstation flake";

    inputs = {
      #nixpkgs = {
      #  url = "github:NixOs/nixpkgs/nixos-23.05";
      #};

      # short:
      nixpkgs.url = "nixpkgs/nixos-unstable";
      home-manager.url = "github:nix-community/home-manager/master";
      home-manager.inputs.nixpkgs.follows = "nixpkgs"; # Use system packages list where available
    };

    outputs = {self, nixpkgs, home-manager, ...}@inputs:
      let
        username = "ewt";
        lib = nixpkgs.lib;
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          specialArgs = { inherit inputs; };
          config = { allowUnfree = true; };
        };
      in {
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs; };
          #system = "x86_64-linux";
          modules = [ 
            ./configuration.nix
          ];
        };
      };
  };
}
