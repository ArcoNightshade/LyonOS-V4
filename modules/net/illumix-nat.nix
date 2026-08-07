# Host-side networking for the illumix guest: a persistent tap interface,
# NAT out to the real uplink, and a dnsmasq instance handing the guest a
# fixed lease. Paired with modules/virt/illumix.nix -- always import both.
#
# workstation (and this profile, which shares its desktop stack) already owns
# wifi via NetworkManager + iwd (see compose.nix / flake.nix settings), so
# this doesn't touch that: `systemd.network.enable` runs systemd-networkd
# *only* for the tap device, which is marked unmanaged in NetworkManager so
# the two don't fight over it.
{ lib, config, ... }:
let
  cfg = config.illumix;
in
{
  config = lib.mkIf cfg.enable {
    systemd.network.enable = true;

    systemd.network.netdevs."30-${cfg.tapInterface}" = {
      netdevConfig = {
        Kind = "tap";
        Name = cfg.tapInterface;
      };
      tapConfig = {
        User = "illumix";
        Group = "illumix";
      };
    };

    systemd.network.networks."30-${cfg.tapInterface}" = {
      matchConfig.Name = cfg.tapInterface;
      address = [ "10.100.0.1/24" ];
      networkConfig.RequiredForOnline = false;
    };

    networking.networkmanager.unmanaged = [ "interface-name:${cfg.tapInterface}" ];

    # externalInterface deliberately left unset: this masquerades regardless
    # of which physical NIC ends up carrying the default route.
    networking.nat = {
      enable = true;
      internalInterfaces = [ cfg.tapInterface ];
      internalIPs = [ "10.100.0.0/24" ];
    };

    services.dnsmasq = {
      enable = true;
      settings = {
        interface = cfg.tapInterface;
        bind-interfaces = true;
        dhcp-range = [ "10.100.0.10,10.100.0.200,12h" ];
        dhcp-option = [ "3,10.100.0.1" "6,10.100.0.1" ];
        dhcp-host = [ "${cfg.macAddress},10.100.0.2,illumix-guest" ];
      };
    };

    networking.hosts."10.100.0.2" = [ "illumix-guest" ];

    networking.firewall.trustedInterfaces = [ cfg.tapInterface ];
    networking.firewall.interfaces.${cfg.tapInterface} = {
      allowedTCPPorts = [ 2049 111 ];
      allowedUDPPorts = [ 2049 111 ];
    };

    services.nfs.server = {
      enable = true;
      exports = ''
        ${cfg.shareDir} 10.100.0.0/24(rw,sync,no_subtree_check,no_root_squash)
      '';
    };
  };
}
