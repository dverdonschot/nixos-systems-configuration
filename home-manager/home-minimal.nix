{ config, pkgs, inputs, ... }:

{
    home.stateVersion = "25.05";
    home.username = "ewt";
    home.homeDirectory = "/home/ewt";
    nixpkgs.config.allowUnfree = true;
    home.packages = with pkgs; [
      curl
      librewolf-bin
    ];

    xdg.configFile.oh-my-posh = {
      source = ../config;
      recursive = true;
    };

    programs.home-manager.enable = true;

    programs.git = {
      enable = true;
      userName = "ewt";
      userEmail = "36795362+dverdonschot@users.noreply.github.com";
    };
    
    programs.neovim = {
      enable = true;
      #defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      plugins = with pkgs.vimPlugins; [
        dracula-nvim
        nerdtree
        LazyVim
        nnn-vim
        (nvim-treesitter.withPlugins (p: [p.rust p.python p.nix p.json p.yaml p.toml p.typescript ]))
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
        set hlsearch
        set showmatch
        set clipboard=unnamedplus
        set cursorline
        packadd! nvim-treesitter
        packadd! nerdtree
        packadd! LazyVim
      '';
    };
    programs.tmux = {
      enable = false;
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
    programs.direnv.enable = true;
    programs.htop = {
      enable = true;
      settings = {
        left_meters = [ "LeftCPUs2" "Memory" "Swap" ];
        left_right = [ "RightCPUs2" "Tasks" "LoadAverage" "Uptime" ];
        setshowProgramPath = false;
        treeView = true;
      };
    };
    programs.jq.enable = true;
}
