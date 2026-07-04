{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.rustfs-container;
in {
  options.services.rustfs-container = {
    enable = mkEnableOption "Enable rustfs container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "rustfs";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.40";
    };
    hostAddress = mkOption {
      type = types.str;
      default = "192.168.100.10";
    };
    accessKeyFile = mkOption {
      type = types.path;
      default = "/mnt/data/rustfs/secrets/access-key";
      description = "Path to the access key file on the host";
    };
    secretKeyFile = mkOption {
      type = types.path;
      default = "/mnt/data/rustfs/secrets/secret-key";
      description = "Path to the secret key file on the host";
    };
    prometheusTokenFile = mkOption {
      type = types.path;
      default = "/mnt/data/rustfs/secrets/prometheus-token";
      description = "Path to the prometheus bearer token file on the host";
    };
    package = mkOption {
      type = types.package;
      description = "Rustfs package to use";
      # NOTE: this option must be set from the host flake's rustfs input.
      # Example in flake.nix specialArgs:   inherit inputs;
      # Then in configuration.nix: package = inputs.rustfs.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };

  config = mkIf cfg.enable {
    containers.${cfg.containerName} = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "${cfg.hostAddress}";
      localAddress = "${cfg.ipAddress}";
      hostAddress6 = "fd00::10";
      localAddress6 = "fd00::40";
      bindMounts = {
        "/.env/.${cfg.containerName}.env" = {
          hostPath = "/mnt/data/${cfg.containerName}/.env/${cfg.containerName}.env";
          isReadOnly = true;
        };
        "/${cfg.containerName}/data" = {
          hostPath = "/mnt/data/${cfg.containerName}/data";
          isReadOnly = false;
        };
        "/${cfg.containerName}/secrets" = {
          hostPath = "/mnt/data/${cfg.containerName}/secrets";
          isReadOnly = true;
        };
      };

      extraFlags = [ "--private-users-ownership=chown" ];
      additionalCapabilities = [
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
        boot.isContainer = true;

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

        networking.nameservers = [ "100.100.100.100" "1.1.1.1" ];
        networking.useHostResolvConf = false;

        services.journald.extraConfig = "SystemMaxUse=100M";

        # Rustfs user and group
        users.groups.rustfs = {};
        users.users.rustfs = {
          isSystemUser = true;
          group = "rustfs";
          description = "RustFS service user";
        };

        # RustFS service - defined inline to avoid flake import inside config
        systemd.tmpfiles.rules = [
          "d /${cfg.containerName}/data 0755 rustfs rustfs -"
        ];

        systemd.services.rustfs = {
          description = "RustFS Object Storage Server";
          after = [ "network-online.target" ];
          wants  = [ "network-online.target" ]; 
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            User = "rustfs";
            Group = "rustfs";
            ExecStart = "${cfg.package}/bin/rustfs";
            LoadCredential = [
              "access-key:/${cfg.containerName}/secrets/access-key"
              "secret-key:/${cfg.containerName}/secrets/secret-key"
            ];
            # Security hardening
            CapabilityBoundingSet = "";
            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";
            RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
            MemoryDenyWriteExecute = true;
            LockPersonality = true;
            UMask = "0077";
            Restart = "always";
            RestartSec = "10s";
            ReadWritePaths = [ "/${cfg.containerName}/data" ];
            # Logging
            StandardOutput = "journal";
            StandardError = "journal";
          };
          environment = {
            RUSTFS_VOLUMES = "/${cfg.containerName}/data";
            RUSTFS_ADDRESS = "0.0.0.0:9000";
            RUSTFS_CONSOLE_ENABLE = "true";
            # Bind to 0.0.0.0 so the in-container Caddy can reverse-proxy
            # /gui on the rustfs.<tailNet> vhost to the console. nspawn
            # `privateNetwork` keeps the port off the host firewall.
            RUSTFS_CONSOLE_ADDRESS = "0.0.0.0:9001";
            RUST_LOG = "info";
            RUSTFS_ACCESS_KEY_FILE = "%d/access-key";
            RUSTFS_SECRET_KEY_FILE = "%d/secret-key";
          };
        };

        services.tailscale = {
          enable = true;
          permitCertUid = "caddy";
        };

        services.caddy = {
          enable = true;
          extraConfig = ''
            ${cfg.containerName}.${cfg.tailNet} {
              # The rustfs console and its admin/SigV4 API must share the
              # same origin (host + port + path base). The console's JS
              # hard-codes /rustfs/admin/v3/* and /rustfs/console/*, and
              # the SigV4 middleware on port 9000 (built via s3s) only
              # honors signatures when the request lands on that origin.
              # Reverse-proxying /gui to a *different* port (9001) breaks
              # this — see rustfs/rustfs issues #2433, #3062, #151, and
              # the "Signature is required" error reproduced from issue
              # #2924. So: send /rustfs/* (and everything else) to 9000
              # and only use a 302 redirect for the /gui convenience
              # alias. Port 9001 stays bound for tailscale-internal
              # debugging only — the public path always lands on 9000.
              handle /rustfs/* {
                reverse_proxy ${cfg.ipAddress}:9000
              }
              # /gui -> canonical rustfs console entrypoint, same origin.
              # Caddyfile: only one matcher token is allowed in the
              # directive position. Multi-path OR uses a named @block.
              @gui path /gui /gui/*
              handle @gui {
                redir https://{host}/rustfs/console/ 302
              }
              handle {
                reverse_proxy ${cfg.ipAddress}:9000
              }
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 9000 ];

        system.stateVersion = "25.05";
      };
    };
  };
}
