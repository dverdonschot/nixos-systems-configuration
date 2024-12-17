# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
      (fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
      ../../nix-containers/homepage.nix
      ../../nix-containers/jellyfin-container.nix
      ../../nix-containers/metube-container.nix
      ../../nix-containers/arthurtube-container.nix
      ../../nix-containers/minio-container.nix
      ../../nix-containers/alby-container.nix
      ../../nix-containers/pinchflat-container.nix
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
  hardware.graphics = {
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
  networking = {
    networkmanager.enable = true;
    # added for nixos containers
    networkmanager.unmanaged = ["interface-name:ve-*"];
    hostName = "media";
    usePredictableInterfaceNames = false;
    nameservers = [ "1.1.1.1" "192.168.50.110" "100.119.102.1" ];
    # added for nixos containers
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "eth0";
      enableIPv6 = false;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # Allow Nix Flakes
  nix.package = pkgs.nixVersions.stable;
  # Enable experimentatl features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];  

  services.vscode-server.enable = true;
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ewt = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "podman"  ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
  #     firefox
  #     tree
    ];
  };

  security.sudo.wheelNeedsPassword = false;

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
    openssl
    duplicati
    parted
    podman
    podman-compose
    podman-tui
    tree
    iputils
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
    8000
    9100
  ];
  networking.firewall.trustedInterfaces = ["ve-dashy"];
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

  services.prometheus.exporters.node.enable = true;

  services.duplicati = {
    enable = true;
    interface = "any";
    user = "root";
  };

  # promtail to forward logs to loki
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://loki.tail5bbc4.ts.net:3100/loki/api/v1/push";
      }];
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = "pihole";
          };
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }];
    };
  };
  
  ## Enable the OpenSSH daemon.
  services.openssh.enable = true;
  
  programs.bash = {
    interactiveShellInit = ''
      # Loading ohh my posh config
      eval "$(oh-my-posh --init --shell bash --config /home/ewt/.config/oh-my-posh/posh-dverdonschot.omp.json)"
    '';
  };

  services.homepage = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    proxmoxUrl = "https://proxmox.th:8006";
  };
  
  services.jellyfin-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
  };

  services.metube-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    containerName = "metube";
    ipAddress = "192.168.100.15";
  };
  
  services.arthurtube-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    containerName = "arthurtube";
    ipAddress = "192.168.100.17";
  };

  services.alby-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    containerName = "alby";
    ipAddress = "192.168.100.19";
  };

  services.pinchflat-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    containerName = "pinchflat";
    ipAddress = "192.168.100.21";
  };
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  system.stateVersion = "25.05"; # Did you read the comment?

}
