# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, modulesPath, userName, userEmail, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  # 1. enable vaapi on OS-level
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
    ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Enable SSH in the boot process.
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  services.qemuGuest.enable = true;
  users.users.userName.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCchj6sbAoMdefpGxb/NSi1oO+Nxj8HFvp3b8RjIJP+vLs5OtwMEksd+QB9Ssbl0ovs5HiUcT6Il0p4Qrir8xf7tvTGblQGQAaYcGSsgw0NMmCgSAYuDYrwn6yTR1d9dtIugl4kcU8xUikBkrmTbNiA0bP0LOXvkuwkl/SaUowznBbQK7Q2uLVRWEi6RmfSil+3UPF7o/UWLTyOrE4RW0Ggr5GTvvQPmjg0Mj7aSZwMBz9PMJTJgVoRq/R/OY7PDuF+Y8KlTvpIRutTCgE7Jt+i2IOYLEmQkdfjrq8yvHxbsWSLM8Fj+l6n3VJUhmfH/U5GTm/i/ZcvnVDjbNLHu4YN07ExX9sXh8ZZPHBjImUTXO7Db5NRo+AVZ/Kr8F1yjLB4hwTP33avfi0yqM+niLFb2eRHQN3P0+db5skSi6S5IDpqHKcPPrux2cLXT4+8DoRIQO+ICkTei9qvd424kF6IhrfVJxHm+wlUCbY2fWbnUH/r36uJSrbqemMkGgOa0lE= ewt@fedora"
  ];
  networking = {
    hostName = "media";
    networkmanager.enable = true;
    usePredictableInterfaceNames = false;
    interfaces.ens18.ipv4.addresses = [{
      address = "192.168.50.11";
      prefixLength = 24;
    }];
    defaultGateway = {
      address = "192.168.50.1";
      interface = "ens18";
    };
    nameservers = [ "192.168.50.110" ];
  };


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # Allow Nix Flakes
  nix.package = pkgs.nixFlakes;
  # Enable experimentatl features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];  

  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.userName = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "podman"  ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
  #     firefox
  #     tree
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    bind
    jq
    zip
    oh-my-posh
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    openssl
    duplicati
    parted
    podman
    podman-compose
    podman-tui
    tree
    awscli2
    nodePackages.aws-cdk 
  ];

  virtualisation = {
    podman = {
      enable = true;
      # docker alias
      dockerCompat = true;

      defaultNetwork.settings.dns_enabled = true;
   };
  };
	
  networking.firewall.allowedUDPPorts = [
    53 # DNS
    5353 # Multicast
  ];
  networking.firewall.allowedTCPPorts = [
    8200
  ];
  # Setup DNS.
  services.resolved = {
    enable = true;
  };
  services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user=userName;
  };

  services.duplicati = {
    enable = true;
    interface = "any";
    user = "root";
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  
  programs.bash = {
    interactiveShellInit = ''
      # Loading ohh my posh config
      eval "$(oh-my-posh --init --shell bash --config /home/${userName}/.config/oh-my-posh/posh-dverdonschot.omp.json)"
    '';
  };




  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  system.stateVersion = "23.11"; # Did you read the comment?

}
