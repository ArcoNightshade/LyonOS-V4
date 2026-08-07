{ settings, ... }:
{
  home-manager.users.${settings.account.name} = {
    services.mako = {
      enable = true;
      settings = {
        font = "${settings.font.name} ${toString settings.font.size}";
        background-color = "#${settings.colorScheme.palette.base01}ee";
        text-color = "#${settings.colorScheme.palette.base05}ff";
        border-color = "#${settings.colorScheme.palette.base0E}ff";
        border-size = 2;
        border-radius = 8;
        padding = 12;
        margin = 10;
        default-timeout = 5000;

        "urgency=low" = {
          border-color = "#${settings.colorScheme.palette.base0D}ff";
        };
        "urgency=high" = {
          border-color = "#${settings.colorScheme.palette.base08}ff";
          default-timeout = 0;
        };
      };
    };
  };
}
