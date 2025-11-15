{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.n8n-container;
in {
  options.services.n8n-container = {
    enable = mkEnableOption "Enable n8n container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "n8n";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.35";
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
        "/.env/.${cfg.containerName}.env" = {
          hostPath = "/mnt/data/${cfg.containerName}/.env/${cfg.containerName}.env";
          isReadOnly = true;
        };
        "/${cfg.containerName}/config" = {
          hostPath = "/mnt/data/${cfg.containerName}/config";
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
          vaapiIntel = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
        };
        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            intel-vaapi-driver
            libva-vdpau-driver
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
          n8n = {
            image = "docker.n8n.io/n8nio/n8n";
            environment = {
              N8N_HOST="${cfg.containerName}.${cfg.tailNet}";
              N8N_PORT="5678";
              N8N_PROTOCOL="https";
              NODE_ENV="production";
              WEBHOOK_URL="https://n8n.${cfg.tailNet}";
            };
            environmentFiles = [
              "/.env/.${cfg.containerName}.env"
            ];
            autoStart = true;
            ports = [
              "5678:5678"
            ];
            volumes = [
              "n8n_data:/home/node/.n8n"
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
              reverse_proxy localhost:5678
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 5678 ];

        system.stateVersion = "25.05";
      };
    };
  };
}
