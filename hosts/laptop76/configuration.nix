# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, modulesPath, ... }:
  # nix-software-center requirements
let
  nix-software-center = import (pkgs.fetchFromGitHub {
    owner = "snowfallorg";
    repo = "nix-software-center";
    rev = "0.1.2";
    sha256 = "xiqF1mP8wFubdsAQ1BmfjzCgOD3YZf7EGWl9i69FTls=";
  }) {};
in


{
  imports =
    [
      #"${modulesPath}/profiles/minimal.nix"
      ./hardware-configuration.nix
      <home-manager/nixos>
      ./user.nix
#      ./home.nix
    ];

  nixpkgs.overlays = [
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # trying to prevent nixos rebuild issue where this service fails
  systemd.services.NetworkManager-wait-online.enable = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  # Enable networking
  networking.networkmanager.enable = true;

  # prepare network for finding printer and autodetection in general
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
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
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };



  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;


  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ewt = {
    isNormalUser = true;
    description = "ewt";
    shell = pkgs.bashInteractive;
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    packages = with pkgs; [
      firefox
    ];
  };

  security.sudo.extraRules = [
    { 
      users = [ "ewt" ];
      commands = [
        { command = "ALL" ;
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ewt";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
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


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    nmap
    git
    tree
    gnome.gnome-tweaks
    gnome.gnome-terminal
    btop
    fzf
    unzip
    pciutils
    dpkg
    tmux
    wl-clipboard
    libstdcxx5 ## fooocus
    libz
    lshw
    nix-software-center
    nix-index
    vscode-fhs
    #images
    pinta
    tiv
    # ai
    ollama
    # microcrontrollers
    pciutils
    usbutils
    qmk
    esptool
    esphome
    arduino
    haskellPackages.udev
    # cli bautification
    oh-my-posh
    oh-my-git
    hack-font
    powerline-fonts
    font-awesome
    # compiling
    stdenv.cc.cc
    gcc
    gcc-unwrapped
    pkg-config
    gnumake
    pkgsCross.avr.buildPackages.gcc
    appimage-run
    podman
    podman-tui
    podman-compose
    lazydocker
    # virtualization
    virt-manager
    virt-viewer
    spice spice-gtk
    spice-protocol
    win-virtio
    win-spice
    quickemu
    quickgui
    gnome.adwaita-icon-theme
    # services
    tailscale
    awscli2
    s3fs
    steam 
    octoprint
  ];

  fonts.fontDir.enable = true; 
  fonts.packages = with pkgs; [ pkgs.hack-font ]; 
  fonts.fontconfig = {
    defaultFonts = {
      monospace = ["FiraCode"];
    };
  };

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

  # List services that you want to enable:

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
