{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.prometheus-container;
in {
  options.services.prometheus-container = {
    enable = mkEnableOption "Enable prometheus container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "prometheus";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.22";
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
        "/var/lib/prometheus" = {
          hostPath = "/mnt/data/prometheus";
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
        services.prometheus = {
          enable = true;
          globalConfig.scrape_interval = "1m";
          scrapeConfigs = [
            {
              job_name = "hosts";
              static_configs = [{
                targets = [ "media.${cfg.tailNet}:9100" "um790.${cfg.tailNet}:9100" "odroid.${cfg.tailNet}:9100" ];
              }];
            }
            {
              job_name = "tailscale";
              static_configs = [{
                targets = [
                  "odroid.${cfg.tailNet}:5252"
                  "um790.${cfg.tailNet}:5252"
                  "hoarder.${cfg.tailNet}:5252"
                  "mariadb.${cfg.tailNet}:5252"
                  "grafana.${cfg.tailNet}:5252"
                  "forgejo.${cfg.tailNet}:5252"
                  "homepage.${cfg.tailNet}:5252"
                  "loki.${cfg.tailNet}:5252"
                  "metube.${cfg.tailNet}:5252"
                  "pinchflat.${cfg.tailNet}:5252"
                  "prometheus.${cfg.tailNet}:5252"
                  "redis.${cfg.tailNet}:5252"
                  "search.${cfg.tailNet}:5252"
                  "browserless.${cfg.tailNet}:5252"
                  "librechat.${cfg.tailNet}:5252"
                  "litellm.${cfg.tailNet}:5252"
                  "meilisearch.${cfg.tailNet}:5252"
                  "nextcloud.${cfg.tailNet}:5252"
                  "mongodb.${cfg.tailNet}:5252"
                  "n8n.${cfg.tailNet}:5252"
                  "ollama.${cfg.tailNet}:5252"
                  "ragapi.${cfg.tailNet}:5252"
                  "romm.${cfg.tailNet}:5252"
                  "vectordb.${cfg.tailNet}:5252"
                ];
              }];
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
            prometheus.${cfg.tailNet} {
              reverse_proxy localhost:9090
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
