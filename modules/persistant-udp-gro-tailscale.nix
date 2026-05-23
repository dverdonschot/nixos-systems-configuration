systemd.services.tailscale-ethtool = {
  description = "Optimize UDP forwarding for Tailscale subnet routing";
  wantedBy = [ "multi-user.target" ];
  after = [ "network-online.target" ];
  wants = [ "network-online.target" ];

  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.ethtool}/bin/ethtool -K br0 rx-udp-gro-forwarding on rx-gro-list off";
  };
};
