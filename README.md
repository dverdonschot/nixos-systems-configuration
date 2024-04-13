# Nixos Workstation

This is my 2nd try at setting up a Nixos based Workstation to work on my various personal projects.

# Deploy this flake on a new box

Clone repository locally on a newly install nixos box.

```bash
nix-shell -p vim git wget
git clone https://github.com/dverdonschot/nixos-workstation
cd nixos-workstation
```

Now you can run the rebuild switch by running the flake.

```bash
sudo nixos-rebuild switch --flake .#workstation --impure
sudo nixos-rebuild switch --flake /home/user/nixos-workstation#wsl --impure
```

Remeber this uses the lock file and uses that stage, so you may want to update.

# Update Nixos with this flake

Update nixos flake.lock file

```bash
sudo nix flake update
# perform actual update
sudo nixos-rebuild switch --flake . --impure

```

