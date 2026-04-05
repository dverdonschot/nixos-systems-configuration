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
  };

  config = mkIf cfg.enable {
    # Import rustfs flake module
    imports = [
      (builtins.getFlake "github:rustfs/rustfs-flake").nixosModules.rustfs
    ];

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

        # rustfs service - native NixOS service from rustfs-flake
        services.rustfs = {
          enable = true;
          volumes = "/${cfg.containerName}/data";
          address = ":9000";
          consoleEnable = true;
          consoleAddress = "127.0.0.1:9001";
          logLevel = "info";
          # Use secrets from bind-mounted directory
          accessKeyFile = "/${cfg.containerName}/secrets/access-key";
          secretKeyFile = "/${cfg.containerName}/secrets/secret-key";
        };

        services.tailscale = {
          enable = true;
          permitCertUid = "caddy";
        };

        services.caddy = {
          enable = true;
          extraConfig = ''
            ${cfg.containerName}.${cfg.tailNet} {
              reverse_proxy ${cfg.ipAddress}:9000
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