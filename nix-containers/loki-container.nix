{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.loki-container;
in {
  options.services.loki-container = {
    enable = mkEnableOption "Enable loki container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "loki";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.23";
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
        "/var/lib/loki" = {
          hostPath = "/mnt/data/loki";
          isReadOnly = false;
        };
      };

      config = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
          wget
          iputils
          git
          bind
          jq
          zip
          openssl
        ];

        services.journald.extraConfig = "SystemMaxUse=100M";
        time.timeZone = "Europe/Amsterdam";
        services.loki = {
          enable = true;
          configFile = ./loki/loki.yaml;
        };

        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };

        services.caddy = {
          enable = true;
          extraConfig = ''
            loki.${cfg.tailNet} {
              reverse_proxy localhost:3100
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 3100];

        system.stateVersion = "25.05";

      };
    };
  };
}
