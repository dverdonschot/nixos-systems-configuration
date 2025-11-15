{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.nextcloud-container;
in {
  options.services.nextcloud-container = {
    enable = mkEnableOption "Enable nextcloud container service";
    userName = mkOption {
      type = types.str;
      default = "user";
    };
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "nextcloud";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.16";
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
        "/${cfg.containerName}" = {
          hostPath = "/mnt/data/${cfg.containerName}/data";
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
          vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
          wget
          iputils
          git
          bind
          jq
          zip
          openssl
        ];

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

        boot.kernel.sysctl = {"kernel.keys.maxkeys" = 5000;};
        virtualisation.oci-containers.backend = "docker";
        virtualisation.oci-containers.containers = {
          nextcloud = {
            image = "nextcloud:stable";

            autoStart = true;
            pull = "newer";
            environment = {
              MYSQL_DATABASE = "nextcloud";
              MYSQL_USER = "nextcloud";
              MYSQL_HOST = "mariadb.${cfg.tailNet}";
              REDIS_HOST = "redis.${cfg.tailNet}";
            };
            ports = [
              "8080:80"
            ];
            volumes = [
              "/${cfg.containerName}:/var/www/html"
            ];
            environmentFiles = [
              "/.env/.${cfg.containerName}.env"
            ];
            log-driver = "journald";
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
            nextcloud.${cfg.tailNet} {
              reverse_proxy localhost:8080
            }

          '';
        };


        # open https port
        networking.firewall.allowedTCPPorts = [ 443 8080 ];

        system.stateVersion = "25.05";
      };
    };
  };
}
