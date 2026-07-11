{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.immich-public-proxy-container;
  ipp301 = pkgs.buildNpmPackage rec {
    pname = "immich-public-proxy";
    version = "3.0.1";

    src = pkgs.fetchFromGitHub {
      owner = "alangrainger";
      repo = "immich-public-proxy";
      rev = "v${version}";
      hash = "sha256-y7y21AEMGHtynsguKp8HmTqZni5dIc7qjt2PQnsxN90=";
    };
    # The npm project lives in the `app/` subdirectory of the repo.
    sourceRoot = "source/app";

    npmDepsHash = "sha256-a7qiiIvkDqxj1ZUBONLlZ49LSM8UpGIis/NXt5wEDjw=";

    # The upstream `bin` stub from package.json has a `#!/usr/bin/env node`
    # shebang, which won't resolve at runtime. Replace it with a binary wrapper
    # that invokes nodejs from a known path, and set `mainProgram` to the
    # bin entry name so `lib.getExe` in the upstream NixOS service resolves.
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postInstall = ''
      wrapProgram $out/bin/immich-public-proxy \
        --prefix PATH : ${lib.makeBinPath [ pkgs.nodejs ]}
    '';

    meta.mainProgram = "immich-public-proxy";
  };
in {
  options.services.immich-public-proxy-container = {
    enable = mkEnableOption "Enable immich-public-proxy service";
    tailNet = mkOption {
      type = types.str;
      default = "tail1abc2.ts.net";
    };
    containerName = mkOption {
      type = types.str;
      default = "immich-public-proxy";
    };
    ipAddress = mkOption {
      type = types.str;
      default = "192.168.100.42";
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
          vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
          wget
          iputils
          git
          bind
          jq
          zip
          openssl
        ];

        services.journald.extraConfig = "SystemMaxUse=100M";
        virtualisation.docker = {
          enable = true;
          autoPrune.enable = true;
          rootless = {
            enable = true;
            setSocketVariable = true;
          };
        };

        services.immich-public-proxy = {
          enable = true;
          package = ipp301;
          port = 3000;
          immichUrl = "https://immich.${cfg.tailNet}";
          openFirewall = false;
        };
        services.tailscale = {
          enable = true;
          # permit caddy to get certs from tailscale
          permitCertUid = "caddy";
        };



        services.caddy = {
          enable = true;
          extraConfig = ''

            immich-public-proxy.${cfg.tailNet} {
              reverse_proxy localhost:3000
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
