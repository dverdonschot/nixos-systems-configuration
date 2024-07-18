### homepage-dashboard

  containers.homepage = {
    autoStart = true;
    enableTun = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.12";
    bindMounts = {
      "/films" = {
        hostPath = "/mnt/films";
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

      services.homepage-dashboard = {
        enable = true;
        listenPort = 8082;
        openFirewall = true;
        settings = {
          layout = {
            Media = {
              style = "row";
              columns = 4;
            };
          };
        };
        bookmarks = [
          {
            Developer = [
              {
                Github = [
                  {
                    abbr = "GH";
                    href = "https://github.com/";
                  }
                ];
              }
            ];
          }
          {
            Entertainment = [
              {
                YouTube = [
                  {
                    abbr = "YT";
                    href = "https://youtube.com/";
                  }
                ];
              }
            ];
          }
        ];
        services = [
          {
            "My First Group" = [
              {
                "My First Service" = {
                  description = "Homepage is awesome";
                  href = "http://localhost/";
                };
              }
            ];
          }
          {
            "My Second Group" = [
              {
                "My Second Service" = {
                  description = "Homepage is the best";
                  href = "http://localhost/";
                };
              }
            ];
          }
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

          homepage.tail5bbc4.ts.net {
            reverse_proxy localhost:8082
          }

        '';
      };


      # open https port
      networking.firewall.allowedTCPPorts = [ 443 ];

      system.stateVersion = "23.05";

    };
  };