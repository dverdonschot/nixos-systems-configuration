# modules/tailscale-lan-router.nix
{ config, lib, ... }:

with lib;

let
  cfg = config.services.tailscaleLanRouter;
in
{
  options.services.tailscaleLanRouter = {
    enable = mkEnableOption "LAN to Tailscale routing";

    lanSubnet = mkOption {
      type = types.str;
      default = "192.168.50.0/24";
    };

    tailnetSubnet = mkOption {
      type = types.str;
      default = "100.64.0.0/10";
    };

    tailscaleInterface = mkOption {
      type = types.str;
      default = "tailscale0";
    };

    masquerade = mkOption {
      type = types.bool;
      default = true;
      description = "NAT LAN clients behind this host when they access the tailnet.";
    };
  };

  config = mkIf cfg.enable {

    networking.firewall.extraCommands = ''
      iptables -A FORWARD -s ${cfg.lanSubnet} -d ${cfg.tailnetSubnet} -o ${cfg.tailscaleInterface} -j ACCEPT
      iptables -A FORWARD -d ${cfg.lanSubnet} -s ${cfg.tailnetSubnet} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

      ${optionalString cfg.masquerade ''
        iptables -t nat -A POSTROUTING -s ${cfg.lanSubnet} -d ${cfg.tailnetSubnet} -o ${cfg.tailscaleInterface} -j MASQUERADE
      ''}
    '';

    networking.firewall.extraStopCommands = ''
      iptables -D FORWARD -s ${cfg.lanSubnet} -d ${cfg.tailnetSubnet} -o ${cfg.tailscaleInterface} -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -d ${cfg.lanSubnet} -s ${cfg.tailnetSubnet} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true

      ${optionalString cfg.masquerade ''
        iptables -t nat -D POSTROUTING -s ${cfg.lanSubnet} -d ${cfg.tailnetSubnet} -o ${cfg.tailscaleInterface} -j MASQUERADE 2>/dev/null || true
      ''}
    '';
  };
}
