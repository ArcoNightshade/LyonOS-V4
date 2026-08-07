{ settings, ... }:
{
  home-manager.users.${settings.account.name} = {
    programs.btop = {
      enable = true;
      settings = {
        color_theme = "catppuccin-mocha";
        theme_background = false;
        vim_keys = true;
      };
    };

    xdg.configFile."btop/themes/catppuccin-mocha.theme".text = ''
      theme[main_bg]="#${settings.colorScheme.palette.base00}"
      theme[main_fg]="#${settings.colorScheme.palette.base05}"
      theme[title]="#${settings.colorScheme.palette.base05}"
      theme[hi_fg]="#${settings.colorScheme.palette.base0D}"
      theme[selected_bg]="#${settings.colorScheme.palette.base02}"
      theme[selected_fg]="#${settings.colorScheme.palette.base05}"
      theme[inactive_fg]="#${settings.colorScheme.palette.base03}"
      theme[proc_misc]="#${settings.colorScheme.palette.base05}"
      theme[cpu_box]="#${settings.colorScheme.palette.base0D}"
      theme[mem_box]="#${settings.colorScheme.palette.base0C}"
      theme[net_box]="#${settings.colorScheme.palette.base0B}"
      theme[proc_box]="#${settings.colorScheme.palette.base09}"
      theme[div_line]="#${settings.colorScheme.palette.base03}"
      theme[temp_start]="#${settings.colorScheme.palette.base0B}"
      theme[temp_mid]="#${settings.colorScheme.palette.base0A}"
      theme[temp_end]="#${settings.colorScheme.palette.base08}"
      theme[cpu_start]="#${settings.colorScheme.palette.base0D}"
      theme[cpu_mid]="#${settings.colorScheme.palette.base0E}"
      theme[cpu_end]="#${settings.colorScheme.palette.base08}"
      theme[free_start]="#${settings.colorScheme.palette.base0B}"
      theme[free_mid]="#${settings.colorScheme.palette.base0B}"
      theme[free_end]="#${settings.colorScheme.palette.base0B}"
      theme[cached_start]="#${settings.colorScheme.palette.base0C}"
      theme[cached_mid]="#${settings.colorScheme.palette.base0C}"
      theme[cached_end]="#${settings.colorScheme.palette.base0C}"
      theme[available_start]="#${settings.colorScheme.palette.base0E}"
      theme[available_mid]="#${settings.colorScheme.palette.base0E}"
      theme[available_end]="#${settings.colorScheme.palette.base0E}"
      theme[used_start]="#${settings.colorScheme.palette.base08}"
      theme[used_mid]="#${settings.colorScheme.palette.base08}"
      theme[used_end]="#${settings.colorScheme.palette.base08}"
      theme[download_start]="#${settings.colorScheme.palette.base0D}"
      theme[download_mid]="#${settings.colorScheme.palette.base0D}"
      theme[download_end]="#${settings.colorScheme.palette.base0D}"
      theme[upload_start]="#${settings.colorScheme.palette.base0E}"
      theme[upload_mid]="#${settings.colorScheme.palette.base0E}"
      theme[upload_end]="#${settings.colorScheme.palette.base0E}"
      theme[process_start]="#${settings.colorScheme.palette.base0D}"
      theme[process_mid]="#${settings.colorScheme.palette.base0E}"
      theme[process_end]="#${settings.colorScheme.palette.base08}"
    '';
  };
}
