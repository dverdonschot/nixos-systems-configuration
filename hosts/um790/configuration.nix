# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
      #../../nix-containers/loki-container.nix
      ../../nix-containers/search-container.nix
      ../../nix-containers/forgejo-container.nix
      ../../nix-containers/prometheus-container.nix
      ../../nix-containers/grafana-container.nix
      ../../nix-containers/immich-container.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking = {
    networkmanager = {
      enable = true;
      # added for nixos containers
      unmanaged = ["interface-name:ve-*"];
    };
    hostName = "um790";
    usePredictableInterfaceNames = false;
    nameservers = [ "1.1.1.1" "192.168.50.110" "100.119.102.1" ];
    # added for nixos containers
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "wlan0";
      enableIPv6 = false;
    };
  };

  # Added weekly garbage collection
  nix = {
    gc = {
      dates = "weekly";
      automatic = true;
    };
    extraOptions = ''
      trusted-users = root ewt
    '';
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security = {
    rtkit.enable = true;
    sudo.extraConfig = ''
      Defaults        timestamp_timeout=30
    '';
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ewt = {
    isNormalUser = true;
    description = "ewt";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "docker" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ewt";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable nix flakes
  nix.package = pkgs.nixVersions.stable;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow flatpak
  services.flatpak.enable = true;

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
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


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    unzip
    pciutils
    fzf
    btop
    tmux
    wl-clipboard
    gnome-remote-desktop
    gnome-terminal
    google-chrome
    tree
    nix-index
    niv
    monitor
    bottom
    # AMD powertuning
    lact
    # images
    pinta
    tiv
    # virtualization
    virt-manager
    virt-viewer
    spice spice-gtk
    spice-protocol
    win-virtio
    win-spice
    quickemu
    #quickgui
    # containers
    # services
    tailscale
    steam
    ollama
    alpaca
    # cli 
    oh-my-posh
    powerline-fonts
    font-awesome
    # development
    devenv
    direnv
    vscode
    nodejs_22
  ];

  fonts.fontDir.enable = true; 
  fonts.packages = with pkgs; [ pkgs.hack-font ]; 
  fonts.fontconfig = {
    defaultFonts = {
      monospace = ["FiraCode"];
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
  };
  services.tailscale.enable = true;
  services.gnome.gnome-remote-desktop.enable = true;

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" ];
  };

  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = ["multi-user.target"];
  # 3389 is for gnome RDP
  networking.firewall.allowedTCPPorts = [ 3389 ];
  networking.firewall.allowedUDPPorts = [ 3389 ];

  programs.bash = {
    interactiveShellInit = ''
      # initializing Tmux
      [ "$EUID" -ne 0 ] && [ -z "$TMUX"  ] && { tmux attach || exec tmux new-session && exit;}
      # Loading ohh my posh config
      eval "$(oh-my-posh --init --shell bash --config /home/ewt/.config/oh-my-posh/posh-dverdonschot.omp.json)"
    '';
  };

  environment.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = 1;
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

  services.search-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    ipAddress = "192.168.100.25";
  };
  services.forgejo-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    ipAddress = "192.168.100.26";
  };

  services.prometheus-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    containerName = "prometheus";
    ipAddress = "192.168.100.22";
  };

  services.grafana-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
  };

  # Secret for immich postgress db : https://github.com/ryantm/agenix
  age.secrets.dbpw.file = ../../secrets/DBPW.age;

  services.immich-container = {
    enable = true;
    immichVersion = "v1.23.0";
    postgresqlImage = "tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
    redisImage = "redis:6.2-alpine@sha256:51d6c56749a4243096327e3fb964a48ed92254357108449cb6e23999c37773c5";
    backupImage = "prodrigestivill/postgres-backup-local";
    immichUpload = "/mnt/immich/immich-photos";
    immichModelcache = "/mnt/immich/immich-modelcache";
    postgresqlPath = "/mnt/immich/postgresql";
    postgresqlBackup = "/mnt/immich/backup-postgresql";
    databasePw = config.age.secrets.dbpw.path;
    tailNet = "tail5bbc4.ts.net";
    ipAddress = "192.168.100.27";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
