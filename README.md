# Nixos Workstation

This is my 2nd try at setting up a Nixos based Workstation to work on my various personal projects.
The new setup works with Nixos Flakes, but is setup to dropin a configuration.nix and start a new system configuration from there.

By now it contains multiple configurations:

* workstation
* laptop76
* wsl
* um790
* odroid

If you make a new machine you can create a folder in hosts, and then edit flake.nix and add your machine, like the other examples on top.

#  nix-containers

In the nix-containers folders you can find all the seperate nix-containers I made to host different services.

Nixos containers are based on systemd-nspawn containers and work like chroot on steroids.

Nixos Containers have their own host-name, combine that with tailscale and you can have a tailscale dns name for each container that will automaticly get a ssl certificate.
The ssl certificate is used with caddy to host any service on port 443 with a valid certificate.

Nix-containers requires a little setup to create a NAT interface for the nixos-containers.

# Deploy this flake on a new box

Clone repository locally on a newly install nixos box.

```bash
nix-shell -p vim git wget
git clone https://github.com/dverdonschot/nixos-systems-configuration
cd nixos-systems-configuration
```

Change channels to unstable and add Home manager.
```
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
sudo nix-channel --update
```

Now you can run the rebuild switch by running the flake.

```bash
# Install from folder . and select profile workstation
sudo nixos-rebuild switch --flake .#workstation --impure

#Install from full folder path and select profile wsl (change user for your username) (can be used anywhere)
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

# Fedora workstation

```bash
nix run ~/code/nixos-systems-configuration/nix-any-os-home-manager/.#home-manager -- switch --flake ~/code/nixos-systems-configuration/nix-any-os-home-manager/.#fedora --impure
```
