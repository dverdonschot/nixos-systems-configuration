{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./home-minimal.nix
    ./laptop76-sway.nix
  ];
}