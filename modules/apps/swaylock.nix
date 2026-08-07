{ pkgs, settings, ... }:
{
  security.pam.services.swaylock = {};

  home-manager.users.${settings.account.name} = {
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        screenshots = true;
        clock = true;
        indicator = true;
        effect-blur = "20x3";
        effect-vignette = "0.5:0.5";
        show-failed-attempts = true;
        indicator-radius = 100;
        indicator-thickness = 7;

        color         = "${settings.colorScheme.palette.base00}";
        inside-color  = "${settings.colorScheme.palette.base00}aa";
        ring-color    = "${settings.colorScheme.palette.base0E}ff";
        key-hl-color  = "${settings.colorScheme.palette.base0E}ff";
        bs-hl-color   = "${settings.colorScheme.palette.base08}ff";
        text-color    = "${settings.colorScheme.palette.base05}ff";
        separator-color = "00000000";
        line-color    = "00000000";

        inside-ver-color = "${settings.colorScheme.palette.base0D}aa";
        ring-ver-color   = "${settings.colorScheme.palette.base0D}ff";
        text-ver-color   = "${settings.colorScheme.palette.base05}ff";
        line-ver-color   = "00000000";

        inside-wrong-color = "${settings.colorScheme.palette.base08}aa";
        ring-wrong-color   = "${settings.colorScheme.palette.base08}ff";
        text-wrong-color   = "${settings.colorScheme.palette.base05}ff";
        line-wrong-color   = "00000000";

        inside-clear-color = "${settings.colorScheme.palette.base0B}aa";
        ring-clear-color   = "${settings.colorScheme.palette.base0B}ff";
        text-clear-color   = "${settings.colorScheme.palette.base05}ff";
        line-clear-color   = "00000000";

        inside-caps-lock-color = "${settings.colorScheme.palette.base0A}aa";
        ring-caps-lock-color   = "${settings.colorScheme.palette.base0A}ff";
        text-caps-lock-color   = "${settings.colorScheme.palette.base05}ff";
        line-caps-lock-color   = "00000000";
      };
    };
  };
}
