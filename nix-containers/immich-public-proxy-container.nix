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
    # Local patch: wrap the two raw `fetch()` call sites in `immich.ts` so a
    # tailscale/Immich network blip doesn't propagate as an unhandledRejection
    # that kills the process. See nix-containers/patches/ipp-3.0.1-fetch-try-catch.patch.
    patches = [ ./patches/ipp-3.0.1-fetch-try-catch.patch ];
    # The npm project lives in the `app/` subdirectory of the repo.
    sourceRoot = "source/app";

    npmDepsHash = "sha256-a7qiiIvkDqxj1ZUBONLlZ49LSM8UpGIis/NXt5wEDjw=";
    # NOTE: the local patch above changes the source tree, which means
    # `npmDepsHash` (computed from `package-lock.json` content over the
    # patched source) MUST be updated on first rebuild. Run
    # `nix prefetch-npm-deps --hash-style=sha256 /path/to/patched/app/package-lock.json`
    # from a fresh extract (or let `nixos-rebuild` print the expected hash on
    # mismatch and replace this line with the printed value).
    # Last verified hash corresponds to upstream v3.0.1 + this patch.

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
  # Tailscale Serve configuration for this container. Built here (rather than
  # via services.tailscale.serve.configFile) so the path is a plain file
  # derivation we can reference directly from our own systemd unit. Format
  # documented at https://tailscale.com/kb/1589/tailscale-services-configuration-file
  ippServeConfigFile = pkgs.writeText "tailscale-serve-config.json" (builtins.toJSON {
    version = "0.0.1";
    services."svc:${cfg.containerName}" = {
      endpoints = { "tcp:443" = "http://localhost:3000"; };
    };
  });
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
          # Tailscale Serve handles TLS termination for the container's
          # tailnet identity on port 443. tailscaled reads the cert from
          # its own state, so no permitCertUid is needed. We disable the
          # upstream `serve` submodule (see below) and own the config +
          # systemd unit ourselves, because the upstream unit runs
          # `tailscale serve set-config` immediately after tailscaled
          # starts, before tailscaled has reached `Running` state. That
          # fails with `unexpected state: NoState` on first boot.
          serve.enable = false;
        };

        # Replace the upstream tailscale-serve.service with our own that
        # polls for state == Running before applying the config.
        systemd.services.tailscale-serve.enable = false;
        systemd.services.ipp-tailscale-serve = {
          description = "Tailscale Serve Configuration (with state wait)";
          after = [ "tailscaled.service" "tailscaled-autoconnect.service" ];
          wants = [ "tailscaled.service" ];
          wantedBy = [ "multi-user.target" ];
          restartTriggers = [ ippServeConfigFile ];
          serviceConfig = let
            tsBin = lib.getExe config.services.tailscale.package;
            jqBin = "${pkgs.jq}/bin/jq";
            script = ''
              state=NoState
              for i in $(seq 1 60); do
                state=$(${tsBin} status --json --peers=false 2>/dev/null \
                  | ${jqBin} -r .BackendState)
                [ "$state" = Running ] && break
                sleep 1
              done
              if [ "$state" != Running ]; then
                echo "ipp-tailscale-serve: tailscaled did not reach Running in 60s (state=$state)" >&2
                exit 1
              fi
              exec ${tsBin} serve set-config --all ${ippServeConfigFile}
            '';
          in {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "/bin/sh -c ${pkgs.lib.escapeShellArg script}";
          };
          path = [ pkgs.coreutils pkgs.jq config.services.tailscale.package ];
        };



        system.stateVersion = "25.05";

      };
    };
  };
}
