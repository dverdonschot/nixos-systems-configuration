{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.homepage;
in {
  options.services.homepage = {
    enable = mkEnableOption "Enable Homepage service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    proxmoxUrl = mkOption {
      type = types.str;
      default = "https://proxmox:8006";
    };
  };
  
  config = mkIf cfg.enable {
    # Option definitions.
    # Define what other settings, services and resources should be active.
    # Usually these depend on whether a user of this module chose to "enable" it
    # using the "option" above. 
    # Options for modules imported in "imports" can be set here.

    containers.homepage = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.12";
      bindMounts = {
        "/films" = {
          hostPath = "/mnt/films";
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

        services.homepage-dashboard = {
          enable = true;
          listenPort = 8082;
          openFirewall = true;
          settings = {
            title = "My Home Services";
            favicon = "https://www.google.com/favicon.ico";
          };
          services = [
            {
              "News" = [
                {
                  "FreshRSS" = {
                    icon = "freshrss";
                    description = "FreshRSS";
                    href = "https://freshrss.${cfg.tailNet}";
                  };
                }
              ];
            }
            {
              "Photos" = [
                {
                  "Immich" = {
                    icon = "immich";
                    description = "Immich Photo Collection";
                    href = "https://immich.${cfg.tailNet}";
                  };
                }
                {
                  "Immich Backup" = {
                    icon = "duplicati";
                    description = "Immich backup";
                    href = "https://immich.${cfg.tailNet}:8200";
                  };
                }
              ];
            }
            {
              "Infra" = [
                {
                  "Proxmox" = {
                    icon = "proxmox";
                    description = "Proxmox";
                    href = "${cfg.proxmoxUrl}";
                  };
                }
                {
                  "Home Assistant" = {
                    icon = "home-assistant";
                    description = "Home Assistant";
                    href = "http://homeassistant.${cfg.tailNet}:8123"
                  }
                }
              ];
            }
          ];
        };
        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };
        


        services.caddy = {
          enable = true;
          extraConfig = ''

            homepage.${cfg.tailNet} {
              reverse_proxy localhost:8082
            }

          '';
        };


        # open https port
        networking.firewall.allowedTCPPorts = [ 443 ];

        system.stateVersion = "23.05";

      };
    };
  };
}