{ config, pkgs, lib, ... }:

{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--accept-routes"
      "--advertise-routes=192.168.50.0/24"
      # "--advertise-exit-node"
    ];
  };

  services.unbound = {
    enable = true;

    settings = {
      server = {
        interface = [
          "127.0.0.1"
          "192.168.50.152"
          "100.124.243.21"
        ];
        access-control = [
          "127.0.0.0/8 allow"
          "::1 allow"
          "192.168.50.0/24 allow"
          "100.64.0.0/10 allow"
        ];

        # Optional but nice for homelab DNS
        private-domain = [
          "home.arpa."
          "ts.net."
        ];

        domain-insecure = [
          "home.arpa."
        ];
        local-data = [
          ''"odroid.home.arpa.  3600 IN A 192.168.50.152"''
          ''"dns.home.arpa.     3600 IN A 192.168.50.152"''
        ];
        local-zone = [
          ''"home.arpa." static''
        ];
      };

      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        }

        # Replace this with your actual MagicDNS domain.
        # Example: tail5bbc4.ts.net.
        {
          name = "tail5bbc4.ts.net.";
          forward-addr = [ "100.100.100.100" ];
        }

        # Reverse lookup for Tailscale 100.64.0.0/10 addresses
        {
          name = "100.in-addr.arpa.";
          forward-addr = [ "100.100.100.100" ];
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  environment.systemPackages = with pkgs; [
    dig
    tcpdump
  ];
}
