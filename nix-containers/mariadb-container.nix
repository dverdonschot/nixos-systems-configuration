{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.mariadb-container;
in {
  options.services.mariadb-container = {
    enable = mkEnableOption "Enable mariadb container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "mariadb";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.38";
    };
    hostAddress = mkOption {
      type = types.str;
      default = "192.168.100.10";
    };
  };
  
  config = mkIf cfg.enable {
    # Option definitions.
    # Define what other settings, services and resources should be active.
    # Usually these depend on whether a user of this module chose to "enable" it
    # using the "option" above. 
    # Options for modules imported in "imports" can be set here.

    containers.mariadb = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "${cfg.hostAddress}";
      localAddress = "${cfg.ipAddress}";
      bindMounts = {
        "/.env/.${cfg.containerName}.env" = {
          hostPath = "/mnt/${cfg.containerName}/.env/${cfg.containerName}.env";
          isReadOnly = true;
        };
        "/${cfg.containerName}/mysql_data" = {
          hostPath = "/mnt/${cfg.containerName}/mysql_data";
          isReadOnly = false;
        };
      };


      extraFlags = [ "--private-users-ownership=chown" ];
      additionalCapabilities = [
        # This is a very ugly hack to add the system-call-filter flag to
        # nspawn. extraFlags is written to an env file as an env var and
        # does not support spaces in arguments, so I take advantage of
        # the additionalCapabilities generation to inject the command
        # line argument.
        ''all" --system-call-filter="add_key keyctl bpf" --capability="all''
      ];
      allowedDevices = [
        { node = "/dev/fuse"; modifier = "rwm"; }
        { node = "/dev/mapper/control"; modifier = "rw"; }
        { node = "/dev/console"; modifier = "rwm"; }
      ];
      bindMounts.fuse = {
        hostPath = "/dev/fuse";
        mountPoint = "/dev/fuse";
        isReadOnly = false;
      };

      config = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          vim 
          wget
          iputils
          git
          bind
          jq
          zip
          openssl
          mariadb
        ];

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

        networking.nameservers = [ "100.100.100.100" "1.1.1.1" ];
        networking.useHostResolvConf = false;
        virtualisation.docker = {
          enable = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
          };
          rootless = {
            enable = false;
            setSocketVariable = true;
          };
        };

        services.journald.extraConfig = "SystemMaxUse=100M";
        
        virtualisation.oci-containers.backend = "docker";
        virtualisation.oci-containers.containers = {
          mariadb = {
            image = "ghcr.io/mariadb/mariadb:11.7.1-noble-rc";
            autoStart = true;
            environment = {
              MARIADB_DATABASE = "romm";
              MARIADB_USER = "romm";
            };
            ports = [
              "3306:3306"
            ];
            environmentFiles = [
              "/.env/.${cfg.containerName}.env"
            ];
            volumes = [
              "/${cfg.containerName}/mysql_data:/var/lib/mysql:rw"
            ];
            log-driver = "journald";
            cmd = [
              "--bind-address=0.0.0.0"
            ];
            #extraOptions = [
            #  "--health-cmd=[\"healthcheck.sh\", \"--connect\", \"--innodb_initialized\"]"
            #  "--health-interval=10s"
            #  "--health-retries=5"
            #  "--health-start-period=30s"
            #  "--health-startup-interval=10s"
            #  "--health-timeout=5s"
            #  "--network-alias=mariadb-db"
            #  "--network=mariadb_default"
            #];
          };
        };

        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };

        services.caddy = {
          enable = true;
          extraConfig = ''
            ${cfg.containerName}.${cfg.tailNet} {
              reverse_proxy localhost:3306
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 3306 ];

        system.stateVersion = "25.05";
      };
    };
  };
}
