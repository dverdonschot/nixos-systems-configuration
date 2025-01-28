{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.librechat-container;
in {
  options.services.librechat-container = {
    enable = mkEnableOption "Enable librechat container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "librechat";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.34";
    };
  };
  
  config = mkIf cfg.enable {
    # Option definitions.
    # Define what other settings, services and resources should be active.
    # Usually these depend on whether a user of this module chose to "enable" it
    # using the "option" above. 
    # Options for modules imported in "imports" can be set here.

    containers.librechat = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "${cfg.ipAddress}";
      bindMounts = {
        "/.env/.librechat.env" = {
          hostPath = "/home/ewt/.env/librechat.env";
          isReadOnly = true;
        };
        "/${cfg.containerName}/config" = {
          hostPath = "/mnt/${cfg.containerName}/config";
          isReadOnly = false;
        };
        "/${cfg.containerName}/logs" = {
          hostPath = "/mnt/${cfg.containerName}/logs";
          isReadOnly = false;
        };
        "/${cfg.containerName}/public-images" = {
          hostPath = "/mnt/${cfg.containerName}/public-images";
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
          librechat = {
            image = "ghcr.io/danny-avila/librechat-dev:latest";
            environment = {
              HOST = "0.0.0.0";
              MONGO_URI = "mongodb://mongodb.${cfg.tailNet}:/vectordb";
              MEILI_HOST = "https://meilisearch.${cfg.tailNet}";
              RAG_PORT = "8000";
              RAG_API_URL = "http://ragapi.${cfg.tailNet}";
            };
            environmentFiles = [
              "/.env/.${cfg.containerName}.env"
            ];
            autoStart = true;
            ports = [
              "3080:3080"
            ];
            volumes = [
              "/${cfg.containerName}/config/librechat.yaml:/app/librechat.yaml"
              "/${cfg.containerName}/public-images:/app/client/public/images"
              "/${cfg.containerName}/logs/:/app/api/logs"
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
              reverse_proxy localhost:3080
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 3080 ];

        system.stateVersion = "25.05";
      };
    };
  };
}
