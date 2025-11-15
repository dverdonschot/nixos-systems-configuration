{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.homepage;
in {
  options.services.jellyfin-container = {
    enable = mkEnableOption "Enable jellyfin container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "jellyfin";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.13";
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
        "/metube" = {
          hostPath = "/mnt/data/metube";
        };
        "/pinchflat" = {
          hostPath = "/mnt/data/pinchflat";
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
          jellyfin
          jellyfin-ffmpeg
          jellyfin-web
        ];

        nixpkgs.config.packageOverrides = pkgs: {
          vaapiIntel = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
        };
        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            intel-vaapi-driver
            libva-vdpau-driver
            libvdpau-va-gl
            intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
          ];
        };

        services.journald.extraConfig = "SystemMaxUse=100M";
        services.jellyfin = {
          enable = true;
          openFirewall = true;
          #user = "ewt";
        };

        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };

        services.caddy = {
          enable = true;
          extraConfig = ''
            jellyfin.${cfg.tailNet} {
              reverse_proxy localhost:8096
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
