{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.romm-container;
in {
  options.services.romm-container = {
    enable = mkEnableOption "Enable romm container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "romm";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.36";
    };
  };
  
  config = mkIf cfg.enable {
    # Option definitions.
    # Define what other settings, services and resources should be active.
    # Usually these depend on whether a user of this module chose to "enable" it
    # using the "option" above. 
    # Options for modules imported in "imports" can be set here.

    containers.romm = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "${cfg.ipAddress}";
      bindMounts = {
        "/.env/.romm.env" = {
          hostPath = "/home/ewt/.env/romm.env";
          isReadOnly = true;
        };
        "/${cfg.containerName}/library" = {
          hostPath = "/mnt/${cfg.containerName}/library";
          isReadOnly = false;
        };
        "/${cfg.containerName}/assets" = {
          hostPath = "/mnt/${cfg.containerName}/assets";
          isReadOnly = false;
        };
        "/${cfg.containerName}/config" = {
          hostPath = "/mnt/${cfg.containerName}/config";
          isReadOnly = false;
        };
        "/${cfg.containerName}/resources" = {
          hostPath = "/mnt/${cfg.containerName}/resources";
          isReadOnly = false;
        };
        "/${cfg.containerName}/redis_data" = {
          hostPath = "/mnt/${cfg.containerName}/redis_data";
          isReadOnly = false;
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
          romm-db = {
            image = "mariadb:latest";
            autoStart = true;
            environment = {
              MARIADB_DATABASE = "romm";
              MARIADB_USER = "romm-user";
            };
            environmentFiles = [
              "/.env/.${cfg.containerName}.env"
            ];
            volumes = [
              "/${cfg.containerName}/mysql_data:/var/lib/mysql:rw"
            ];
            log-driver = "journald";
            extraOptions = [
              "--health-cmd=[\"healthcheck.sh\", \"--connect\", \"--innodb_initialized\"]"
              "--health-interval=10s"
              "--health-retries=5"
              "--health-start-period=30s"
              "--health-startup-interval=10s"
              "--health-timeout=5s"
              "--network-alias=romm-db"
              "--network=romm_default"
            ];
          };
          romm = {
            image = "rommapp/romm:latest";
            autoStart = true;
            environment = {
              DB_HOST = "romm-db";
              DB_NAME = "romm";
              DB_USER = "romm-user";
            };
            environmentFiles = [
              "/.env/.${cfg.containerName}.env"
            ];
            volumes = [
              "/${cfg.containerName}/resources:/romm/resources:rw" # Resources fetched from IGDB (covers, screenshots, etc.)
              "/${cfg.containerName}/redis_data:/redis-data:rw" # Cached data for background tasks
              "/${cfg.containerName}/library:/romm/library:rw" # Your game library. Check https://github.com/rommapp/romm?tab=readme-ov-file#folder-structure for more details.
              "/${cfg.containerName}/assets:/romm/assets:rw" # Uploaded saves, states, etc.
              "/${cfg.containerName}/config:/romm/config:rw" # Path where config.yml is stored
            ];
            ports = [
              "8080:8080"
            ];
            dependsOn = [
              "romm-db"
            ];
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
              reverse_proxy localhost:5432
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 5432 ];

        system.stateVersion = "25.05";
      };
    };
  };
}
