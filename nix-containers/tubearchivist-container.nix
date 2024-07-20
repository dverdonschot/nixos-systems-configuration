{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.tubearchivist-container;
in {
  options.services.tubearchivist-container = {
    enable = mkEnableOption "Enable TubeArchivist Container service";
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

    containers.tubearchivist = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.14";
      bindMounts = {
        "/tubearchivist" = {
          hostPath = "/mnt/tubearchivist";
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
          vim
          wget
          iputils
          git
          bind
          jq
          zip
          openssl
        ];

        networking.nameservers = [ "1.1.1.1" ];
        networking.useHostResolvConf = false;
        virtualisation.docker = {
          enable = true;
          rootless = {
            enable = true;
            setSocketVariable = true;
          };
        };

        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };
        
        virtualisation.oci-containers.containers = {
          extcloud_database = {
		        image = "postgres:15.1";
            autoStart = true;
            volumes = [ 
              "/nextcloud/postgres_data:/var/lib/postgresql/data"
            ];
            environmentFiles = [
              /etc/nixos/oci-containers/default.env
              /etc/nixos/oci-containers/nextcloud/database.env
            ];
          };
        };

        virtualisation.oci-containers.backend = "docker";
        virtualisation.oci-containers.containers = {
          tubearchivist = {
            image = "bbilly1/tubearchivist";
            ports = ["0.0.0.0:8000:8000"];
            volumes = [
              "/tubearchivist/media:/youtube"
              "/tubearchivist/cache:/chache"
            ];
            environment = {
              ES_URL="http://archivist-es:9200";
              REDIS_HOST="archivist-redis";
              HOST_UID="1000";
              HOST_GID="1000";
              TA_HOST="tubearchivist.local 192.168.50.11 localhost tubearchivist.${cfg.tailNet}";
              TA_USERNAME="djewt1";
              TZ="Europe/Amsterdam";
            };
            environmentFiles = [
              "/tubearchivist/.env"
            ];
            dependsOn = [
              "archivist-es"
              "archivist-redis"
            ];
          };
          archivist-redis = {
            image = "redis/redis-stack-server";
            ports = ["0.0.0.0:6379:6379"];
            volumes = [
              "/tubearchivist/redis:/data"
            ];
            dependsOn = [
              "archivist-es"
            ];
          };
          archivist-es = {
            image = "bbilly1/tubearchivist-es";
            ports = ["0.0.0.0:9200:9200"];
            environment = {
              ES_JAVA_OPTS="-Xms512m -Xmx512m";
              "xpack.security.enabled"="true";
              "discovery.type"="single-node";
              "path.repo"="/usr/share/elasticsearch/data/snapshot";
            };
            volumes = [
              "/tubearchivist/es:/usr/share/elasticsearch/data"
            ];
            environmentFiles = [
              "/tubearchivist/.env"
            ];
          };
        };

        services.caddy = {
          enable = true;
          extraConfig = ''

            tubearchivist.${cfg.tailNet} {
              reverse_proxy localhost:8000
            }

          '';
        };


        # open https port
        networking.firewall.allowedTCPPorts = [ 443 53 ];

        system.stateVersion = "23.05";

      };
    };
  };
}

