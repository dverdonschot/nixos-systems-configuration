{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "laptop76";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      #allowedTCPPorts = [ ... ];
    };
  };
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  time.timeZone = "Europe/Amsterdam";
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  nixpkgs.config.allowUnfree = true;
  
  # Enable the X11 windowing system.
  services = {
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };
    xserver.xkb = {
      layout = "us";
      variant = "";
    };
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    power-profiles-daemon.enable = false;
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

       #Optional helps save long term battery health
       START_CHARGE_THRESH_BAT0 = 40; # 40 and bellow it starts to charge
       STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging

      };
    };
    #openssh.enable = true;
  };
  
  users.users.ewt = {
    isNormalUser = true;
    description = "ewt";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  programs.firefox.enable = true;

<<<<<<< HEAD
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
<<<<<<< HEAD
  
  # Enable nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.package = pkgs.nixVersions.stable;

  # Allow flatpak
  services.flatpak.enable = true;

  # Allow Docker
  virtualisation.podman = {
    dockerCompat = true;
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
    #enableOnBoot = true;
#    rootless = {
#      enable = true;
#      setSocketVariable = true;
#    };
  };
  
  programs.dconf.enable = true;
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  programs.virt-manager.enable = true;
  services.spice-vdagentd.enable = true;

=======
>>>>>>> e6e4eea (nix on laptop)

  # List packages installed in system profile. To search, run:
  # $ nix search wget
=======
>>>>>>> e151d50 (changes to laptop)
  environment.systemPackages = with pkgs; [
    git # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    oh-my-posh
    hack-font
    powerline-fonts
    font-awesome
    tmux
    libgcc
  ];

<<<<<<< HEAD
<<<<<<< HEAD
  fonts.fontDir.enable = true; 
  fonts.packages = with pkgs; [ pkgs.hack-font ]; 
=======
  fonts.fontDir.enable = true; 
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
>>>>>>> e151d50 (changes to laptop)
  fonts.fontconfig = {
    defaultFonts = {
      monospace = ["FiraCode"];
    };
  };
<<<<<<< HEAD

  services.tailscale.enable = true;

  programs.bash = {
    interactiveShellInit = ''
      # initializing Tmux
      [ "$EUID" -ne 0 ] && [ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
      # Loading ohh my posh config
      eval "$(oh-my-posh --init --shell bash --config /home/ewt/.config/oh-my-posh/posh-dverdonschot.omp.json)"
    '';
  };

  # nvim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ''
        set number relativenumber
        set paste
        syntax on
        colorscheme tokyonight
        set tabstop=4
        set autoindent
        set expandtab
        set softtabstop=4
        set ruler
      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [ tokyonight-nvim];
      };
    };
  };

  # vscode wayland support
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
  #environment.sessionVariables.LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib/:${pkgs.libudev-zero}/lib/:$LD_LIBRARY_PATH";
  environment.sessionVariables.LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib/:$LD_LIBRARY_PATH";
=======
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
>>>>>>> e6e4eea (nix on laptop)
=======
>>>>>>> e151d50 (changes to laptop)

  services.tailscale.enable = true;

  programs.bash = {
    interactiveShellInit = ''
      # initializing Tmux
      [ "$EUID" -ne 0 ] && [ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
      # Loading ohh my posh config
      eval "$(oh-my-posh --init --shell bash --config /home/ewt/.config/oh-my-posh/posh-dverdonschot.omp.json)"
    '';
  };

  # nvim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ''
        set number relativenumber
        set paste
        syntax on
        colorscheme tokyonight
        set tabstop=4
        set autoindent
        set expandtab
        set softtabstop=4
        set ruler
      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [ tokyonight-nvim];
      };
    };
  };

  system.stateVersion = "24.05"; # Did you read the comment?

}
