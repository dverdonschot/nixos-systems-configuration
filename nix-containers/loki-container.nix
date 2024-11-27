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
      localAddress = "192.168.100.24";
      bindMounts = {
        "/loki" = {
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
        networking.firewall.allowedTCPPorts = [ 443 9100 ];

        system.stateVersion = "23.05";

      };
    };
  };
}
