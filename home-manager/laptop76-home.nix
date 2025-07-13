{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./home.nix
    ./sway.nix
  ];
}
