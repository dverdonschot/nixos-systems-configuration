{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.grafana;
in {
  options.services.grafana-container = {
    enable = mkEnableOption "Enable grafana container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
  };
  
  config = mkIf cfg.enable {
    # Option definitions.
    # Define what other settings, services and resources should be active.
    # Usually these depend on whether a user of this module chose to "enable" it
    # using the "option" above. 
    # Options for modules imported in "imports" can be set here.

    containers.grafana = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.24";

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

        nixpkgs.config.packageOverrides = pkgs: {
          vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
        };
        hardware.opengl = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            vaapiIntel
            vaapiVdpau
            libvdpau-va-gl
            intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
          ];
        };

        services.promtail = {
          enable = true;
          configuration = {
            server = {
              http_listen_port = 3031;
              grpc_listen_port = 0;
            };
            positions = {
              filename = "/tmp/positions.yaml";
            };
            clients = [{
              url = "http://loki.${cfg.tailNet}:3100/loki/api/v1/push";
            }];
            scrape_configs = [{
              job_name = "journal";
              journal = {
                max_age = "12h";
                labels = {
                  job = "systemd-journal";
                  host = "pihole";
                };
              };
              relabel_configs = [{
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }];
            }];
          };
        };

        services.grafana = {
          protocol = "http";
          addr = "0.0.0.0";
          analytics.reporting.enable = false;
          enable = true;

          provision = {
            enable = true;
            datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                access = "proxy";
                url = "https://prometheus.${cfg.tailNet}:443";
              }
              {
                name = "Loki";
                type = "loki";
                access = "proxy";
                url = "https://loki.${cfg.tailNet}:443";
              }
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
            grafana.${cfg.tailNet} {
              reverse_proxy localhost:3000
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 3000 ];

        system.stateVersion = "25.05";

      };
    };
  };
}
