# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

let
  username_var = "ewt";
in

{
  imports = [
    # include NixOS-WSL modules
    <nixos-wsl/modules>
    <home-manager/nixos>
    (fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
  ];
  
  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "nixos";
    startMenuLaunchers = true;
  };

  networking.hostName = "nixos-wsl";
  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    wget
    tmux
    vim
    git
    curl
    oh-my-posh
    tree
    nmap
    tree
    gtk3
    powerline-fonts
    hack-font
    awscli
    openvscode-server
    git-remote-codecommit
    nodePackages.aws-cdk
    azure-cli
    # python3.11
    python311
    python311Packages.virtualenv
    python311Packages.pyyaml
    # Node
    nodejs
    nodePackages.npm
    nodePackages.eslint
    # Docker
    docker-compose
  ];

  # https://github.com/nix-community/nixos-vscode-server
  # Start service in nixos user: systemctl --user enable auto-fix-vscode-server.service --now
  services.vscode-server.enable = true;

  virtualisation.docker = { 
    enable = true;
    enableOnBoot = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  users.users.nixos.extraGroups = ["wheel" "docker"];

  fonts.fontDir.enable = true; 
  fonts.packages = with pkgs; [ pkgs.hack-font ]; 
  fonts.fontconfig = {
    defaultFonts = {
      monospace = ["FiraCode"];
    };
  };

  programs.bash = {
    interactiveShellInit = ''
      # initializing Tmux
      # [ "$EUID" -ne 0 ] && [ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
      # Loading ohh my posh config
      eval "$(oh-my-posh --init --shell bash --config /home/nixos/.config/oh-my-posh/posh-dverdonschot.omp.json)"
    '';
  };


  # Home-manager

  # Nixos user

  home-manager.users.nixos = { pkgs, ... }: {
    home.stateVersion = "23.05";
    home.packages = with pkgs; [
      curl
    ];
     programs.git = {
      enable = true;
      userName = "${username_var}";
      userEmail = "${username_var}@mail.com";
    };
    programs.neovim = {
      enable = true;
      #defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      plugins = with pkgs.vimPlugins; [
        dracula-nvim
      ];
      extraConfig = ''
        set number relativenumber
        set paste
        syntax on
        colorscheme dracula
        set tabstop=4
        set autoindent
        set expandtab
        set softtabstop=4
        set ruler
      '';
    };
    programs.tmux = {
      enable = true;
      clock24 = true;
      plugins = with pkgs.tmuxPlugins; [
          sensible
	  yank
	  {
	      plugin = dracula;
	      extraConfig = ''
	          set -g @plugin "dracula/tmux"
	      '';
	  }
      ];
      extraConfig = ''
          set -sg escape-time 50
      '';
    };
    xdg.configFile.oh-my-posh = {
      source = ../../config;
      recursive = true;
    };
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}

