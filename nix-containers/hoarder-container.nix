{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.hoarder-container;
in {
  options.services.hoarder-container = {
    enable = mkEnableOption "Enable hoarder Container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "hoarder";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.27";
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

    containers.${cfg.containerName} = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "${cfg.hostAddress}";
      localAddress = "${cfg.ipAddress}";
      bindMounts = {
        "/${cfg.containerName}" = {
          hostPath = "/mnt/${cfg.containerName}/data";
          isReadOnly = false;
        };
        "/.env/.hoarder.env" = {
          hostPath = "/mnt/${cfg.containerName}/.env/${cfg.containerName}.env";
          isReadOnly = true;
        };
        "/meili_data" = {
          hostPath = "/mnt/${cfg.containerName}/meili_data";
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


      config = { config, pkgs, ... }: {
        boot.isContainer = true;
        systemd.services.docker.path = [ pkgs.fuse-overlayfs ];

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

        networking.nameservers = [ "1.1.1.1" ];
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
        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };
        
        virtualisation.oci-containers.backend = "docker";
        virtualisation.oci-containers.containers = {
          hoarder = {
            image = "ghcr.io/hoarder-app/hoarder:latest";
            ports = [
              "3000:3000"
            ];
            environment = {
              MEILI_ADDR = "http://meilisearch:7700";
              BROWSER_WEB_URL = "http://chrome:9222";
              OLLAMA_BASE_URL = "https://ollama.tail5bbc4.ts.net:11434";
              INFERENCE_TEXT_MODEL = "llama3.1";
              INFERENCE_IMAGE_MODEL = "llava";
              DATA_DIR = "/data";
              HOARDER_VERSION = "release";
              NEXTAUTH_URL="http://localhost:3000";
            };
            environmentFiles = [
              "/.env/.${cfg.containerName}.env"
            ];
            extraOptions = ["--pull=always"];
            autoStart = true;
            volumes = [
              "/${cfg.containerName}:/data"
            ];
          };
          chrome = {
            image = "gcr.io/zenika-hub/alpine-chrome:latest";
            autoStart = true;
            cmd = [
              "--no-sandbox"
              "--disable-gpu"
              "--disable-dev-shm-usage"
              "--remote-debugging-address=0.0.0.0"
              "--remote-debugging-port=9222"
              "--hide-scrollbars"
            ];
          };
          meilisearch = {
            image = "getmeili/meilisearch:latest";
            autoStart = true;
            environmentFiles = [
              "/.env/.${cfg.containerName}.env"
            ];
            ports = [
              "7700:7700"
            ];
            environment = {
              MEILI_NO_ANALYTICS="true";
            };
            volumes = [
              "/meili_data:/meili_data"
            ];
          };
        };

        services.caddy = {
          enable = true;
          extraConfig = ''
            ${cfg.containerName}.${cfg.tailNet} {
              reverse_proxy ${cfg.ipAddress}:3000
            }
            ${cfg.containerName}.${cfg.tailNet}:7701 {
              reverse_proxy ${cfg.ipAddress}:7700
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 12432 12433 12434 ];

        system.stateVersion = "25.05";

      };
    };
  };
}
