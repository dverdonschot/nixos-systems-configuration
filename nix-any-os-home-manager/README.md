# Nix flake to run home-manager on a non Nixos OS like Fedora

## How to run this flake

```bash
git clone https://github.com/dverdonschot/nixos-systems-configuration.git
cd nix-systems-configuration/nix-any-os-home-manager
nix run .#home-manager -- switch --flake .#fedora

## OR
nix run ~/code/nixos-systems-configuration/nix-any-os-home-manager/.#home-manager -- switch --flake ~/code/nixos-systems-configuration/nix-any-os-home-manager/.#fedora
```

