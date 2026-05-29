{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.services.sabnzbd-container;
in {
  options.services.sabnzbd-container = {
    enable = mkEnableOption "Enable SABnzbd container service";

    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };

    containerName = mkOption {
      type = types.str;
      default = "sabnzbd";
    };

    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.14";
    };

    hostAddress = mkOption {
      type = types.str;
      default = "192.168.100.10";
    };

    downloadPath = mkOption {
      type = types.str;
      default = "/mnt/data/downloads";
      description = "Host path used for SABnzbd downloads.";
    };

    incompletePath = mkOption {
      type = types.str;
      default = "/mnt/data/downloads/incomplete";
      description = "Host path used for incomplete SABnzbd downloads.";
    };
  };

  config = mkIf cfg.enable {

    containers.${cfg.containerName} = {
      autoStart = true;
      privateNetwork = true;
      enableTun = true;

      hostAddress = cfg.hostAddress;
      localAddress = cfg.ipAddress;

      bindMounts = {
        "/downloads" = {
          hostPath = cfg.downloadPath;
          isReadOnly = false;
        };

        "/downloads/incomplete" = {
          hostPath = cfg.incompletePath;
          isReadOnly = false;
        };
      };

      config = { pkgs, ... }: {

        system.stateVersion = "25.05";

        environment.systemPackages = with pkgs; [
          vim
          wget
          curl
          git
          jq
          zip
          unzip
          iputils
          bind
          sabnzbd
        ];

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

        services.sabnzbd = {
          enable = true;

          # SABnzbd web interface
          host = "0.0.0.0";
          port = 8080;

          # Storage paths inside container
          downloadDir = "/downloads";
          completeDir = "/downloads/complete";

          # Optional tuning
          user = "sabnzbd";
          group = "sabnzbd";
        };

        services.tailscale = {
          enable = true;

          # Allow Caddy to obtain Tailscale certs
          permitCertUid = "caddy";
        };

        services.caddy = {
          enable = true;

          extraConfig = ''
            sabnzbd.${cfg.tailNet} {
              reverse_proxy localhost:8080
            }
          '';
        };

        networking.firewall.allowedTCPPorts = [
          443
          8080
        ];

        # Ensure storage directories exist
        systemd.tmpfiles.rules = [
          "d /downloads 0755 sabnzbd sabnzbd -"
          "d /downloads/complete 0755 sabnzbd sabnzbd -"
          "d /downloads/incomplete 0755 sabnzbd sabnzbd -"
        ];
      };
    };
  };
}
