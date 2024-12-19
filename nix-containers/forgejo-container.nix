{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.forgejo-container;
in {
  options.services.forgejo-container = {
    enable = mkEnableOption "Enable forgejo Container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "forgejo";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.26";
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
      hostAddress = "192.168.100.10";
      localAddress = "${cfg.ipAddress}";
      bindMounts = {
        "/${cfg.containerName}" = {
          hostPath = "/mnt/${cfg.containerName}";
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
            enable = false;
            setSocketVariable = true;
          };
        };

        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };
        
        virtualisation.oci-containers.backend = "docker";
        virtualisation.oci-containers.containers = {
          forgejo = {
            image = "codeberg.org/forgejo/forgejo:9";
            ports = [
              "3000:3000"
              "12322:22"
              ];
            environment = {
              USER_UID = "1000";
              USER_GID = "1000";
              ROOT_URL = "https://${cfg.containerName}.${cfg.tailNet}";
            };
            extraOptions = ["--pull=always"];
            autoStart = true;
            volumes = [
              "/${cfg.containerName}:/data"
              "/etc/timezone:/etc/timezone:ro"
              "/etc/localtime:/etc/localtime"
            ];
          };
        };

        services.caddy = {
          enable = true;
          extraConfig = ''
            ${cfg.containerName}.${cfg.tailNet} {
              reverse_proxy ${cfg.ipAddress}:3000
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 3000 12322 ];

        system.stateVersion = "25.05";

      };
    };
  };
}
