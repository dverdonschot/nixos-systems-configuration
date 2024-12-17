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
          vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
          wget
          iputils
          git
          bind
          jq
          zip
          openssl
        ];

        virtualisation.docker = {
          enable = true;
          rootless = {
            enable = true;
            setSocketVariable = true;
          };
        };

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
                {
                  "SearXNG" = {
                    icon = "searxng";
                    description = "Private Internet search";
                    href = "https://search.${cfg.tailNet}";
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
              "Monitoring" = [
                {
                  "Prometheus" = {
                    icon = "prometheus";
                    description = "Prometheus";
                    href = "https://prometheus.${cfg.tailNet}";
                  };
                }
                {
                  "Loki" = {
                    icon = "loki";
                    description = "Loki";
                    href = "https://loki.${cfg.tailNet}";
                  };
                }
                {
                  "Grafana" = {
                    icon = "grafana";
                    description = "Grafana";
                    href = "https://grafana.${cfg.tailNet}";
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
                    href = "https://homeassistant.${cfg.tailNet}";
                  };
                }
                {
                  "Minio S3" = {
                    icon = "minio";
                    description = " Minio S3";
                    href = "https://minio.${cfg.tailNet}";
                  };
                }
              ];
            }
            {
              "Media" = [
                {
                  "JellyFin" = {
                    icon = "jellyfin";
                    description = "JellyFin";
                    href = "https://jellyfin.${cfg.tailNet}";
                  };
                }
                {
                  "Metube" = {
                    icon = "youtube";
                    description = "Download things from youtube with metube";
                    href = "https://metube.${cfg.tailNet}";
                  };
                }
                {
                  "Arthurtube" = {
                    icon = "youtube";
                    description = "Download things from youtube with metube";
                    href = "https://arthurtube.${cfg.tailNet}";
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

            homepage.${cfg.tailNet} {
              reverse_proxy localhost:8082
            }

          '';
        };


        # open https port
        networking.firewall.allowedTCPPorts = [ 443 ];

        system.stateVersion = "25.05";

      };
    };
  };
}