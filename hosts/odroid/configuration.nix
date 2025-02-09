# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
      ../../nix-containers/search-container.nix
      ../../nix-containers/forgejo-container.nix
      ../../nix-containers/loki-container.nix
      ../../nix-containers/prometheus-container.nix
      ../../nix-containers/grafana-container.nix
      ../../nix-containers/hoarder-container.nix
      ../../nix-containers/homepage.nix
      ../../nix-containers/jellyfin-container.nix
      ../../nix-containers/metube-container.nix
      ../../nix-containers/pinchflat-container.nix
      ../../nix-containers/nextcloud-container.nix
      ../../nix-containers/mariadb-container.nix
      ../../nix-containers/redis-container.nix
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
    hostName = "odroid";
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

  # Disable the GNOME3/GDM auto-suspend feature that cannot be disabled in GUI!
  # If no user is logged in, the machine will power down after 20 minutes.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.journald.extraConfig = "SystemMaxUse=200M";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
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
    extraGroups = [ "networkmanager" "wheel" "libvitd" "docker" "audio" "video" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

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
    btop
    tmux
    wl-clipboard
    gnome-remote-desktop
    gnome-terminal
    tree
    nix-index
    niv
    monitor
    bottom
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
    forgejo-runner
    quickemu
    #quickgui
    # containers
    # services
    tailscale
    # cli 
    oh-my-posh
    powerline-fonts
    nerd-fonts._0xproto
    font-awesome
    # development
    devenv
    direnv
    vscode
    # create fhs environments
    steam-run
  ];

  fonts.fontDir.enable = true; 
  fonts.packages = with pkgs; [ 
    pkgs.hack-font 
    pkgs.powerline-fonts
    pkgs.font-awesome
    pkgs.nerd-fonts._0xproto
  ]; 


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

  services.tailscale = {
    enable = true;
    # permit caddy to get certs from tailscale
    permitCertUid = "caddy";
  };
#  services.gnome.gnome-remote-desktop.enable = true;

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" "cpu" "diskstats" "ethtool" "filesystem" "hwmon" "interrupts" "netdev" "sysctl" ];
  };

  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = ["multi-user.target"];
  # 3389 is for gnome RDP # 1999 for netdata
  networking.firewall.allowedTCPPorts = [ 3389 1999 ];
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

  # promtail
  users.extraGroups.docker.members = [ "promtail" ];
  systemd.services.promtail.serviceConfig = {
    ExecStartPost = [
      "-/bin/sh -c 'ln -sf /var/run/docker.sock /run/promtail/docker.sock'"
    ];
  };
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
        url = "https://loki.tail5bbc4.ts.net:/loki/api/v1/push";
      }];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            path = "/var/log/journal";
            labels = {
              job = "systemd-journal";
              host = "um790";
            };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }
        {
          job_name = "docker";
          docker_sd_configs = [
            {
              host = "unix:///var/run/docker.sock";
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__meta_docker_container_name" ];
              target_label = "container";
              action = "replace";
              regex = "/?(.*)";
            }
            {
              source_labels = [ "__meta_docker_container_label_com_docker_swarm_service_name" ];
              target_label = "swarm_service";
              action = "replace";
            }
            {
              source_labels = [ "__meta_docker_container_label_org_label_schema_group" ];
              target_label = "group";
              action = "replace";
            }
            {
              source_labels = [ "__meta_docker_container_label_org_label_schema_stack_name" ];
              target_label = "stack";
              action = "replace";
            }
            {
              source_labels = [ "__meta_docker_container_id" ];
              target_label = "container_id";
            }
            {
              source_labels = [ "__meta_docker_network_name" ];
              target_label = "network";
            }
            {
              source_labels = [ "__meta_docker_container_port_publish_mode" ];
              target_label = "port_mode";
            }
            {
              source_labels = [ "__meta_docker_container_port_published" ];
              target_label = "port_published";
            }
            {
              source_labels = [ "__meta_docker_container_port_target" ];
              target_label = "port_target";
            }
            {
              source_labels = [ "__meta_docker_container_port_protocol" ];
              target_label = "port_protocol";
            }
          ];
          pipeline_stages = [
            { docker = {}; }
            {
              json = {
                expressions = {
                  level = "level";
                  msg = "msg";
                };
              };
            }
            {
              labels = {
                level = "level";
              };
            }
          ];
        }
      ];
    };
  };

  # netdata is turned to false to prevent it from eating cpu when not used.
  services.netdata = {
    enable = false;
    config = {
      global = {
        "memory mode" = "ram";
        "debug log" = "none";
        "access log" = "none";
        "error log" = "syslog";
      };
    };
  };

  services.caddy = {
    enable = true;
    extraConfig = ''
      um790.tail5bbc4.ts.net:1999 {
        reverse_proxy localhost:19999
      }
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
  
  services.loki-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
  };

  services.hoarder-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
  };

  services.homepage = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
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

  services.pinchflat-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    containerName = "pinchflat";
    ipAddress = "192.168.100.21";
  };

  services.nextcloud-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    containerName = "nextcloud";
    ipAddress = "192.168.100.16";
  };

  services.mariadb-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    containerName = "mariadb";
    ipAddress = "192.168.100.38";
  };

  services.redis-container = {
    enable = true;
    tailNet = "tail5bbc4.ts.net";
    containerName = "redis";
    ipAddress = "192.168.100.39";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
