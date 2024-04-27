# Nixos Workstation

This is my 2nd try at setting up a Nixos based Workstation to work on my various personal projects.
The new setup works with Nixos Flakes, but is setup to dropin a configuration.nix and start a new system configuration from there.

# Deploy this flake on a new box

Clone repository locally on a newly install nixos box.

```bash
nix-shell -p vim git wget
git clone https://github.com/dverdonschot/nixos-systems-configuration
cd nixos-systems-configuration
```

Now you can run the rebuild switch by running the flake.

```bash
# Install from folder . and select profile workstation
sudo nixos-rebuild switch --flake .#workstation --impure

#Install from full folder path (can be used anywhere) and select profile wsl
sudo nixos-rebuild switch --flake /home/user/nixos-systems-configuration#wsl --impure
```

# Update Nixos with this flake

When running a profile a flake.lock file is created, this pins all packages and dependancies to the current state.

To update nixos flake.lock file:

```bash
sudo nix flake update
# perform actual update
sudo nixos-rebuild switch --flake . --impure
```

