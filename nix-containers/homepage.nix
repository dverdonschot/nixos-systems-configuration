{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.homepage;
in {
  options.services.homepage = {
    enable = mkEnableOption "Enable Homepage service";
    greeter = mkOption {
      type = types.str;
      default = "world";
    };
  };
  
  config = mkIf cfg.enable {
    # Option definitions.
    # Define what other settings, services and resources should be active.
    # Usually these depend on whether a user of this module chose to "enable" it
    # using the "option" above. 
    # Options for modules imported in "imports" can be set here.

    vars = import ./homepage-vars.nix;
    
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
            layout = {
              Media = {
                style = "row";
                columns = 4;
              };
            };
          };
          bookmarks = [
            {
              Media = [
                {
                  FreshRSS = [
                    {
                      icon = "freshrss";
                      abbr = "FreshRSS";
                      href = "https://freshrss.tail5bbc4.ts.net";
                    }
                  ];
                }
              ];
            }
            {
              Entertainment = [
                {
                  YouTube = [
                    {
                      abbr = "YT";
                      href = "https://youtube.com/";
                    }
                  ];
                }
              ];
            }
          ];
          services = [
            {
              "Media" = [
                {
                  "FreshRSS" = {
                    icon = "freshrss";
                    description = "FreshRSS";
                    href = "https://freshrss.tail5bbc4.ts.net";
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
                    href = "https://immich.tail5bbc4.ts.net";
                  };
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

            homepage.tail5bbc4.ts.net {
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