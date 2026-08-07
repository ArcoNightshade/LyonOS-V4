{ pkgs, settings, ... }:
# Shared desktop stack for the mango compositor module: display manager,
# portals, audio, bluetooth, GTK theming and wallpapers. mango.nix imports
# this and adds only its own session registration + config files.
let
  # Recolor adw-gtk3 + libadwaita apps (nautilus, tonearm, ...) from the
  # nix-colors palette, the same way mako/foot/fuzzel are themed. Follows any
  # change to settings.colorScheme automatically. libadwaita (GTK4) apps honour
  # these @define-color overrides; adw-gtk3 (GTK3) picks them up too.
  p = settings.colorScheme.palette;
  gtkColorCss = ''
    /* Generated from nix-colors: ${settings.colorScheme.slug} */
    @define-color accent_color #${p.base0E};
    @define-color accent_bg_color #${p.base0E};
    @define-color accent_fg_color #${p.base00};

    @define-color destructive_color #${p.base08};
    @define-color destructive_bg_color #${p.base08};
    @define-color destructive_fg_color #${p.base00};

    @define-color success_color #${p.base0B};
    @define-color success_bg_color #${p.base0B};
    @define-color success_fg_color #${p.base00};

    @define-color warning_color #${p.base0A};
    @define-color warning_bg_color #${p.base0A};
    @define-color warning_fg_color #${p.base00};

    @define-color error_color #${p.base08};
    @define-color error_bg_color #${p.base08};
    @define-color error_fg_color #${p.base00};

    @define-color window_bg_color #${p.base00};
    @define-color window_fg_color #${p.base05};

    @define-color view_bg_color #${p.base01};
    @define-color view_fg_color #${p.base05};

    @define-color headerbar_bg_color #${p.base01};
    @define-color headerbar_fg_color #${p.base05};
    @define-color headerbar_border_color #${p.base05};
    @define-color headerbar_backdrop_color @window_bg_color;
    @define-color headerbar_shade_color rgba(0, 0, 0, 0.36);

    @define-color card_bg_color #${p.base01};
    @define-color card_fg_color #${p.base05};
    @define-color card_shade_color rgba(0, 0, 0, 0.36);

    @define-color dialog_bg_color #${p.base01};
    @define-color dialog_fg_color #${p.base05};

    @define-color popover_bg_color #${p.base01};
    @define-color popover_fg_color #${p.base05};

    @define-color sidebar_bg_color #${p.base01};
    @define-color sidebar_fg_color #${p.base05};
    @define-color sidebar_backdrop_color #${p.base00};
    @define-color sidebar_border_color rgba(0, 0, 0, 0.36);
    @define-color sidebar_shade_color rgba(0, 0, 0, 0.36);

    @define-color secondary_sidebar_bg_color #${p.base01};
    @define-color secondary_sidebar_fg_color #${p.base05};

    @define-color scrollbar_outline_color rgba(0, 0, 0, 0.5);
  '';
in
{
  environment.systemPackages = with pkgs; [
    mako
    awww
    mpvpaper
    yt-dlp
    playerctl
    imagemagick
    waybar
    fuzzel
    foot
    xwayland-satellite
    package-version-server
    nautilus
    adw-gtk3
  ];

  # Enable desktop environment
  services.xserver.enable = true;
  services.xserver.excludePackages = [ pkgs.xterm ];
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "doom";
      cache = "/tmp/ly-session";
    };
  };
  programs.xwayland.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Boot screen, take out to see systemd logs
  boot.plymouth.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  home-manager.users.${settings.account.name} = {
    # Cursor theme, applied at the session level so every compositor picks it
    # up. mango (and other dwl/wlroots forks) only take the theme from
    # XCURSOR_THEME -- which this sets, along with XCURSOR_SIZE, the GTK
    # cursor theme, and the ~/.icons default index.
    home.pointerCursor = {
      name = settings.cursor.theme;
      package = pkgs.oreo-cursors-plus;
      size = settings.cursor.size;
      gtk.enable = true;
    };

    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "mauve";
        };
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
      # Dynamic recolor from settings.colorScheme (see gtkColorCss above)
      gtk3.extraCss = gtkColorCss;
      gtk4.extraCss = gtkColorCss;
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        "x-directory/normal" = [ "org.gnome.Nautilus.desktop" ];
      };
    };

    home.file."Pictures/Wallpapers".source = ./wallpapers;
  };
}
