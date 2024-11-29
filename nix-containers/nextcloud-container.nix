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
    };  };
  
  config = mkIf cfg.enable {
    # Option definitions.
    # Define what other settings, services and resources should be active.
    # Usually these depend on whether a user of this module chose to "enable" it
    # using the "option" above. 
    # Options for modules imported in "imports" can be set here.

    containers.nextcloud-container = {
      autoStart = true;
      enableTun = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.16";
      bindMounts = {
        "/nextcloud" = {
          hostPath = "/mnt/nextcloud";
        };
        "/nextcloud-security" = {
          hostPath = "/mnt/nextcloud-security";
        };
        "/nextcloud-database" = {
          hostPath = "/mnt/nextcloud-database";
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
          nextcloud28
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

        services.nextcloud = {
          enable = true;
          hostName = "nextcloud.tail5bbc4.ts.net";
          # Need to manually increment with every major upgrade.
          # Let NixOS install and configure the database automatically.
          package = pkgs.nextcloud29;
          database.createLocally = true;
          # Let NixOS install and configure Redis caching automatically.
          configureRedis = true;
          # Increase the maximum file upload size.
          maxUploadSize = "16G";
          https = true;
          autoUpdateApps.enable = true;
          extraAppsEnable = true;
          extraApps = with config.services.nextcloud.package.packages.apps; {
            # List of apps we want to install and are already packaged in
            # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
            inherit calendar contacts notes onlyoffice tasks cookbook qownnotesapi;
            # Custom app example.
          };
          settings = {
            overwriteProtocol = "https";
            default_phone_region = "NL";
          };
          config = {
            dbtype = "pgsql";
            adminuser = "admin";
            adminpassFile = "/nextcloud-security/adminpass";
          };
          # Suggested by Nextcloud's health check.
          phpOptions."opcache.interned_strings_buffer" = "16";
        };
        # Nightly database backups.
        #services.postgresqlBackup = {
        #  enable = true;
        #  startAt = "*-*-* 01:15:00";
        #};

        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };
        
        services.caddy = {
          enable = true;
          extraConfig = ''

            nextcloud.${cfg.tailNet} {
              reverse_proxy localhost:80
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
