{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.loki;
in {
  options.services.loki-container = {
    enable = mkEnableOption "Enable loki container service";
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

    containers.loki = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.23";
      bindMounts = {
        "/var/lib/loki" = {
          hostPath = "/mnt/loki";
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
        services.loki = 
          let
            lokiDir = "/var/lib/loki";
          in
          {
            enable = true;
            configuration = {
              analytics.reporting_enabled = false;
              auth_enabled = false;

              server = {
                http_listen_address = "0.0.0.0";
                http_listen_port = 3100;
                log_level = "warn";
              };

              ingester = {
                lifecycler = {
                  address = "127.0.0.1";
                  ring = {
                    kvstore.store = "inmemory";
                    replication_factor = 1;
                  };
                  final_sleep = "0s";
                };
                chunk_idle_period = "5m";
                chunk_retain_period = "30s";
              };

              schema_config.configs = [
                {
                  from = "2023-06-01";
                  store = "tsdb";
                  object_store = "filesystem";
                  schema = "v13";
                  index = {
                    prefix = "index_";
                    period = "24h";
                  };
                }
              ];

              storage_config = {
                tsdb_shipper = {
                  active_index_directory = "${lokiDir}/tsdb-index";
                  cache_location = "${lokiDir}/tsdb-cache";
                  cache_ttl = "24h";
                };
                filesystem.directory = "${lokiDir}/chunks";
              };

              # Do not accept new logs that are ingressed when they are actually already old.
              limits_config = {
                reject_old_samples = true;
                reject_old_samples_max_age = "168h";
                allow_structured_metadata = false;
              };
              compactor = {
                working_directory = lokiDir;
                compactor_ring.kvstore.store = "inmemory";
              };
            };
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
            loki.${cfg.tailNet} {
              reverse_proxy localhost:3100
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 3100 ];

        system.stateVersion = "24.11";

      };
    };
  };
}
