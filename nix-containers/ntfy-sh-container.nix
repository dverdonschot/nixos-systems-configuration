{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.ntfy-sh-container;
in {
  options.services.ntfy-sh-container = {
    enable = mkEnableOption "Enable ntfy-sh container service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "ntfy-sh";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.41";
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
      config = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
          wget
          iputils
          git
          bind
          openssl
        ];

        nixpkgs.config.packageOverrides = pkgs: {
          vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
        };
        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            vaapiIntel
            vaapiVdpau
            libvdpau-va-gl
            intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
          ];
        };

        services.journald.extraConfig = "SystemMaxUse=100M";        
        time.timeZone = "Europe/Amsterdam";
        services.ntfy-sh = {
          enable = true;
          settings = {
            listen-http = ":8080";
            base-url = "https://ntfy-sh.${cfg.tailNet}";
          }
        };

        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };
        
        services.caddy = {
          enable = true;
          extraConfig = ''
            ntfy-sh.${cfg.tailNet} {
              reverse_proxy localhost:8080
            }
          '';
        };

        # open https port
        networking.firewall.allowedTCPPorts = [ 443 8080];

        system.stateVersion = "25.05";

      };
    };
  };
}
