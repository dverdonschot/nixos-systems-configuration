{ config, pkgs, lib, ... }:

{
  # Odroid becomes LAN DNS + Tailscale gateway helper
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--accept-routes"
      # Adjust these to your final VLANs:
      "--advertise-routes=192.168.50.0/24"
    ];
  };

  virtualisation.oci-containers.containers.technitium-dns = {
    image = "technitium/dns-server:latest";
    autoStart = true;
    extraOptions = [
      "--network=host"
      "--cap-add=NET_ADMIN"
    ];
    volumes = [
      "/mnt/data/technitium-dns:/etc/dns"
    ];
    environment = {
      DNS_SERVER_DOMAIN = "odroid.home.arpa";
      DNS_SERVER_WEB_SERVICE_HTTP_PORT = "5380";
      DNS_SERVER_RECURSION = "UseSpecifiedNetworkACL";
      DNS_SERVER_RECURSION_NETWORK_ACL =
        "127.0.0.1,192.168.50.0/24,100.64.0.0/10";
      DNS_SERVER_FORWARDERS = "1.1.1.1,9.9.9.9";
    };

    # Create this manually, not in git:
    # DNS_SERVER_ADMIN_PASSWORD=your-long-password
    environmentFiles = [
      "/mnt/data/technitium-dns/technitium.env"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 53 5380 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  environment.systemPackages = with pkgs; [
    dig
    tcpdump
  ];
}
