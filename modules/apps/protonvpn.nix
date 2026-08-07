{ pkgs, settings, ... }: {
  # Official Proton VPN GTK client. It drives connections through
  # NetworkManager (WireGuard/OpenVPN), which is already enabled in
  # compose.nix, and needs the user in the `networkmanager` group
  # (workstation user already is).
  home-manager.users.${settings.account.name}.home.packages = with pkgs; [
    proton-vpn # renamed from protonvpn-gui
  ];
}
