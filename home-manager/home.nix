{ config, lib, pkgs, inputs, specialArgs, ... }:

let
  packages = import ./packages.nix;

  inherit (specialArgs) withGUI;

  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;
in

{
    home.stateVersion = "23.11";
    home.username = "ewt";
    home.homeDirectory = "/home/ewt";
    nixpkgs.config.allowUnfree = true;
    home.packages = packages pkgs;

    home.sessionVariables.GTK_THEME = "palenight";
    home.sessionVariables.XDG_DATA_DIRS="/home/ewt/.nix-profile/share:$XDG_DATA_DIRS";
    home.sessionVariables.PATH="/home/ewt/.cargo/bin:/home/ewt/.local/bin:$PATH";
    home.sessionVariables.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    home.file.".icons/default".source = "${pkgs.oreo-cursors-plus}/share/icons/oreo_blue_cursors";

    programs.bash = {
      enable = true;
      initExtra = ''
        source $HOME/.profile
      '';
      profileExtra = ''
        #export PATH=$HOME/.cargo/bin:$PATH
        export EDITOR=nvim
        alias vim=nvim
        #alias v=nvim
        set -o vi
        eval "$(oh-my-posh --init --shell bash --config ~/ohhmyposh/posh-dverdons.opm.json)"
      '';
    };

    xdg.configFile.oh-my-posh = {
      source = ../config;
      recursive = true;
    };

    programs.home-manager.enable = true;
    programs.git = {
      enable = true;
      userName = "ewt";
      userEmail = "36795362+dverdonschot@users.noreply.github.com";
      aliases = { 
        undo = "reset --soft HEAD^"; 
      };
      difftastic = {
        enable = true;
      };
      extraConfig = {
        push = { autoSetupRemote = true; default = "current"; };
      };

    };
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      plugins = with pkgs.vimPlugins; [
        dracula-nvim
        nerdtree
        LazyVim
        nnn-vim
        (nvim-treesitter.withPlugins (p: [p.rust p.python p.nix p.json p.yaml p.toml ]))
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
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        yzhang.markdown-all-in-one
        ms-python.python
        bbenoist.nix
        jnoortheen.nix-ide
        ms-toolsai.jupyter
        rust-lang.rust-analyzer
        eamodio.gitlens
        redhat.vscode-yaml
        wholroyd.jinja
        dart-code.dart-code
        dart-code.flutter
      ];
      keybindings = [
        {
          key = "ctrl+b left";
          command = "workbench.action.navigateLeft";
        }
        {
          key = "ctrl+b right";
          command = "workbench.action.navigateRight";
        }
      ];
    };
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
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
