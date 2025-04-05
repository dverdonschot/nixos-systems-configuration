# Nix flake to run home-manager on a non Nixos OS like Fedora



## How to run this flake

[Install nix on fedora](https://gist.github.com/matthewpi/08c3d652e7879e4c4c30bead7021ff73)

```bash
vi /etc/nix/nix.conf

# Add the following lines
experimental-features = nix-command flakes
build-users-group = nixbld
```

```bash
git clone https://github.com/dverdonschot/nixos-systems-configuration.git
cd nix-systems-configuration/nix-any-os-home-manager
nix run .#home-manager -- switch --flake .#fedora

## OR
nix run ~/nixos-systems-configuration/nix-any-os-home-manager/.#home-manager -- switch --flake ~/nixos-systems-configuration/nix-any-os-home-manager/.#fedora
```

