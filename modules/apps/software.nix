{ pkgs, settings, ... }: {
  home-manager.users.${settings.account.name}.home.packages = with pkgs; [
    # Terminal(s)
    foot

    # Music/Creative
    obsidian
    tonearm    # GTK client for TIDAL

    # Internet tools
    firefox vesktop
  ];
}
