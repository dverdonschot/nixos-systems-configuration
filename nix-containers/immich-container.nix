{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.immich-container;
in {
  options.services.immich-container = {
    enable = mkEnableOption "Enable immich container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.27";
    };
    immichVersion = mkOption {
      type = types.str;
      default = "v1.22.2";
    };
    databasePw = mkOption {
      type = types.str;
    };
    hostAddress = mkOption {
      type = types.str;
      default = "192.168.100.10";
    };
    immichUpload = mkOption {
      type = types.str;
      default = "/mnt/immich/immich-photos";
    };
    immichModelcache = mkOption {
      type = types.str;
      default = "/mnt/immich/immich-modelcache";
    };
    postgresqlPath = mkOption {
      type = types.str;
      default = "/mnt/immich/postgresql";
    };
    postgresqlBackup = mkOption {
      type = types.str;
      default = "/mnt/immich/backup-postgresql";
    };
    postgresqlImage = mkOption {
      type = types.str;
      default = "tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0"
    };
    redisImage = mkOption {
      type = types.str;
      default = "redis:6.2-alpine@sha256:51d6c56749a4243096327e3fb964a48ed92254357108449cb6e23999c37773c5";
    };
    backupImage = mkOption {
      type = types.str;
      default = "prodrigestivill/postgres-backup-local";
    }
  };
  
  immichVars = {
    upload = "/immich/data-upload";
    modelcache = "/immich/modelcache";
    postgresql = "/immich/postgresql";
    backupPostgresql = "/immich/backup-postgresql";
  };

  config = mkIf cfg.enable {
    # Option definitions.
    # Define what other settings, services and resources should be active.
    # Usually these depend on whether a user of this module chose to "enable" it
    # using the "option" above. 
    # Options for modules imported in "imports" can be set here.

    containers.immich = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = cfg.hostAddress;
      localAddress = cfg.ipAddress;
      bindMounts = {
        immichVars.upload = {
          hostPath = cfg.immichUpload;
          isReadOnly = false;
        };
        immichVars.modelcache = {
          hostPath = cfg.immichModelcache;
          isReadOnly = false;
        };
        immichVars.postgresql = {
          hostPath = cfg.postgresqlPath;
          isReadOnly = false;
         };
        immichVars.backupPostgresql = {
          hostPath = cfg.postgresqlBackup;
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

        nixpkgs.config.packageOverrides = pkgs: {
          vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
        };

        hardware.graphics = {
          enable = true;
          enable32Bit = true;
          # Intel
          #extraPackages = with pkgs; [
          #  intel-media-driver
          #  vaapiIntel
          #  vaapiVdpau
          #  libvdpau-va-gl
          #  intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
          #];
        };

        networking.nameservers = [ "1.1.1.1" ];
        networking.useHostResolvConf = false;

        virtualisation = {
          podman = {
            enable = true;
            autoPrune.enable = true;
            dockerCompat  = true;
            defaultNetwork.settings = {
              dns_enabled = true;
            };
          };
        };

        # Define Immich containers
        virtualisation.oci-containers.containers."immich_machine_learning" = {
          image = "ghcr.io/immich-app/immich-machine-learning:${cfg.immichVersion}";
          environment = {
            "DB_DATABASE_NAME" = "immich";
            "DB_HOSTNAME" = "immich_postgres";
            "DB_PASSWORD" = cfg.databasePw;
            "DB_USERNAME" = "postgres";
            "IMMICH_VERSION" = cfg.immichVersion;
            "REDIS_HOSTNAME" = "immich_redis";
            "TYPESENSE_API_KEY" = cfg.databasePw;
            "UPLOAD_LOCATION" = immichVars.upload;
          };
          volumes = [
            "${immichVars.modelcache}:/cache:rw"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=immich-machine-learning"
            "--network=immich_default"
          ];
        };
        systemd.services."podman-immich_machine_learning" = {
          serviceConfig = {
            Restart = lib.mkOverride 90 "always";
          };
          after = [
            "podman-network-immich_default.service"
          ];
          requires = [
            "podman-network-immich_default.service"
          ];
          partOf = [
            "podman-compose-immich-root.target"
          ];
          wantedBy = [
            "podman-compose-immich-root.target"
          ];
        };
        virtualisation.oci-containers.containers."immich_postgres" = {
          image = cfg.postgresqlImage;
          environment = {
            "POSTGRES_DB" = "immich";
            "POSTGRES_PASSWORD" = cfg.databasePw;
            "POSTGRES_USER" = "postgres";
          };
          volumes = [
            "${immichVars.postgresql}:/var/lib/postgresql/data:rw"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=database"
            "--network=immich_default"
          ];
        };
        systemd.services."podman-immich_postgres" = {
          serviceConfig = {
            Restart = lib.mkOverride 90 "always";
          };
          after = [
            "podman-network-immich_default.service"
          ];
          requires = [
            "podman-network-immich_default.service"
          ];
          partOf = [
            "podman-compose-immich-root.target"
          ];
          wantedBy = [
            "podman-compose-immich-root.target"
          ];
        };
        virtualisation.oci-containers.containers."immich_redis" = {
          image = cfg.redisImage;
          log-driver = "journald";
          extraOptions = [
            "--network-alias=redis"
            "--network=immich_default"
          ];
        };
        systemd.services."podman-immich_redis" = {
          serviceConfig = {
            Restart = lib.mkOverride 90 "always";
          };
          after = [
            "podman-network-immich_default.service"
          ];
          requires = [
            "podman-network-immich_default.service"
          ];
          partOf = [
            "podman-compose-immich-root.target"
          ];
          wantedBy = [
            "podman-compose-immich-root.target"
          ];
        };
        virtualisation.oci-containers.containers."immich_server" = {
          image = "ghcr.io/immich-app/immich-server:${cfg.immichVersion}";
          environment = {
            "DB_DATABASE_NAME" = "immich";
            "DB_HOSTNAME" = "immich_postgres";
            "DB_PASSWORD" = cfg.databasePw;
            "DB_USERNAME" = "postgres";
            "IMMICH_VERSION" = cfg.immichVersion;
            "REDIS_HOSTNAME" = "immich_redis";
            "TYPESENSE_API_KEY" = cfg.databasePw;
            "UPLOAD_LOCATION" = immichVars.upload;
          };
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${immichVars.upload}:/usr/src/app/upload:rw"
          ];
          ports = [
            "2283:2283/tcp"
          ];
          dependsOn = [
            "immich_postgres"
            "immich_redis"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=immich-server"
            "--network=immich_default"
          ];
        };
        systemd.services."podman-immich_server" = {
          serviceConfig = {
            Restart = lib.mkOverride 90 "always";
          };
          after = [
            "podman-network-immich_default.service"
          ];
          requires = [
            "podman-network-immich_default.service"
          ];
          partOf = [
            "podman-compose-immich-root.target"
          ];
          wantedBy = [
            "podman-compose-immich-root.target"
          ];
        };

        virtualisation.oci-containers.containers."immich_db_dumper" = {
          image = cfg.backupImage;
          environment = {
            "BACKUP_DIR" = "/db_dumps";
            "BACKUP_NUM_KEEP" = "4";
            "POSTGRES_DB" = "immich";
            "POSTGRES_HOST" = "database";
            "POSTGRES_PASSWORD" = cfg.databasePw;
            "POSTGRES_USER" = "postgres";
            "SCHEDULE" = "@daily";
          };
          volumes = [
            "${immichVars.backupPostgresql}:/db_dumps:rw"
          ];
          dependsOn = [
            "immich_postgres"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=backup"
            "--network=immich_default"
          ];
        };

        systemd.services."podman-immich_db_dumper" = {
          serviceConfig = {
            Restart = lib.mkOverride 90 "no";
          };
          after = [
            "podman-network-immich_default.service"
          ];
          requires = [
            "podman-network-immich_default.service"
          ];
          partOf = [
            "podman-compose-immich-root.target"
          ];
          wantedBy = [
            "podman-compose-immich-root.target"
          ];
        };

        # Networks
        systemd.services."podman-network-immich_default" = {
          path = [ pkgs.podman ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "podman network rm -f immich_default";
          };
          script = ''
            podman network inspect immich_default || podman network create immich_default
          '';
          partOf = [ "podman-compose-immich-root.target" ];
          wantedBy = [ "podman-compose-immich-root.target" ];
        };

        # Root service
        # When started, this will automatically create all resources and start
        # the containers. When stopped, this will teardown all resources.
        systemd.targets."podman-compose-immich-root" = {
          unitConfig = {
            Description = "Root target generated by compose2nix.";
          };
          wantedBy = [ "multi-user.target" ];
        };
        
        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };
        
        services.caddy = {
          enable = true;
          extraConfig = ''
            immich.${cfg.tailNet} {
              reverse_proxy localhost:2283
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 2283 ];

        system.stateVersion = "25.05";

      };
    };
  };
};

