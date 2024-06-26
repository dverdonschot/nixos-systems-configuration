{ config, pkgs, inputs, ... }:

{
    home.stateVersion = "23.11";
    home.username = "ewt";
    home.homeDirectory = "/home/ewt";
    nixpkgs.config.allowUnfree = true;
    home.packages = with pkgs; [
      curl
      nnn
      lynx
    ];

    home.sessionVariables.GTK_THEME = "palenight";
    home.sessionPath = [
      "/home/ewt/.cargo/bin"
    ];
    home.file.".icons/default".source = "${pkgs.oreo-cursors-plus}/share/icons/oreo_blue_cursors";

#    home.pointerCursor = 
#      let 
#        getFrom = url: hash: name: {
#            gtk.enable = true;
#            x11.enable = true;
#            name = name;
#            size = 48;
#            package = 
#              pkgs.runCommand "moveUp" {} ''
#                mkdir -p $out/share/icons
#                ln -s ${pkgs.fetchzip {
#                  url = url;
#                  hash = hash;
#                }} $out/share/icons/${name}
#            '';
#          };
#      in
#        getFrom 
#          "https://github.com/ful1e5/fuchsia-cursor/releases/download/v2.0.0/Fuchsia-Pop.tar.gz"
#          "sha256-BvVE9qupMjw7JRqFUj1J0a4ys6kc9fOLBPx2bGaapTk="
#          "Fuchsia-Pop";
    xdg.configFile.oh-my-posh = {
      source = ../../config;
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
}
