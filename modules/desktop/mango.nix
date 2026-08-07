{ lib, pkgs, inputs, settings, ... }:
# Mango (mangowc) compositor. Shares the desktop stack in desktop-core.nix.
# This module only adds Mango's package, its ly session, and its config files.
#
# The package comes straight from upstream (flake input pinned to 0.15.2) rather
# than nixpkgs' mangowc, because the older packaged version lacks the `dwindle`
# layout used below.
let
  mango = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Freeze-screen screenshot helper. wayfreeze puts a static snapshot of the
  # screen up as a layer; you then select a region with slurp on top of that
  # frozen image, grim captures it, and it's saved to ~/Pictures/Screenshots
  # *and* copied to the clipboard. (grimblast was the obvious tool but its
  # nixpkgs build hard-requires HYPRLAND_INSTANCE_SIGNATURE, so it can't run
  # on mango.)
  #   screenshot         -> freeze + region select (default)
  #   screenshot screen  -> whole screen, no freeze needed
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [ wayfreeze grim slurp wl-clipboard libnotify coreutils ];
    text = ''
      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"
      file="$dir/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png"
      mode="''${1:-area}"

      if [ "$mode" = "screen" ]; then
        grim - | tee "$file" | wl-copy -t image/png
      else
        # Freeze the display so the selection happens over a static image.
        wayfreeze --hide-cursor &
        freeze_pid=$!
        # Give the freeze layer a moment to map before selecting.
        sleep 0.2
        if geom=$(slurp); then
          grim -g "$geom" - | tee "$file" | wl-copy -t image/png
          kill "$freeze_pid" 2>/dev/null || true
        else
          # User pressed Esc / made no selection: unfreeze and bail quietly.
          kill "$freeze_pid" 2>/dev/null || true
          exit 0
        fi
      fi

      notify-send "Screenshot" "Saved to $file and copied to clipboard" 2>/dev/null || true
    '';
  };

  # settings.terminalCommand/terminalEscapeHatch let a profile override the
  # Return-bind spawn command (e.g. illumix routes it through `ish`) without
  # editing this shared module. Both default to null for every profile that
  # doesn't set them, so this is a no-op everywhere except illumix.
  terminalSpawnCommand =
    if settings.terminalCommand != null then settings.terminalCommand else settings.terminal;
  extraTerminalBind = lib.optionalString (settings.terminalEscapeHatch != null)
    "\n      bind=SUPER+SHIFT,Return,spawn,${settings.terminalEscapeHatch}";
in
{
  imports = [ ./desktop-core.nix ];

  environment.systemPackages = [
    mango             # `mango` compositor + `mmsg` control tool
    screenshot        # `screenshot` wrapper, bound to Print below
    pkgs.wayfreeze    # freezes the screen while selecting a region
    pkgs.grim         # screenshot capture
    pkgs.slurp        # region selection
    pkgs.wl-clipboard # wl-copy / wl-paste
  ];

  # Register Mango's wayland session (share/wayland-sessions/mango.desktop) so
  # it shows up as a selectable session in ly.
  services.displayManager.sessionPackages = [ mango ];

  home-manager.users.${settings.account.name} = { config, ... }: {
    xdg.configFile."mango/config.conf".text = ''
      # LyonOS Mango Configuration
      # Options reference: https://github.com/DreamMaoMao/mango/wiki/

      # ---- Input ----
      numlockon=1
      # sloppyfocus = focus-follows-mouse
      sloppyfocus=1
      warpcursor=1
      cursor_size=${toString settings.cursor.size}
      repeat_rate=25
      repeat_delay=600
      xkb_rules_layout=us

      # touchpad
      tap_to_click=1
      tap_and_drag=1
      drag_lock=1
      trackpad_natural_scrolling=1
      disable_while_typing=1

      # ---- Layout / appearance ----
      gappih=5
      gappiv=5
      gappoh=5
      gappov=5
      smartgaps=0
      new_is_master=1
      default_mfact=0.55
      default_nmaster=1

      # Border acts as the focus ring; kept thin and colour-coded.
      borderpx=2
      border_radius=12
      no_radius_when_single=0
      rootcolor=0x${config.colorScheme.palette.base00}ff
      # bordercolor = inactive ring, focuscolor = active ring
      bordercolor=0x${config.colorScheme.palette.base03}ff
      focuscolor=0x${config.colorScheme.palette.base0D}ff
      urgentcolor=0x${config.colorScheme.palette.base08}ff
      maximizescreencolor=0x${config.colorScheme.palette.base0B}ff
      scratchpadcolor=0x${config.colorScheme.palette.base0C}ff
      globalcolor=0x${config.colorScheme.palette.base0E}ff

      # Blur: shows through any translucent window. foot sets alpha=0.4 in its
      # [colors-dark] block, so this blurs the background behind foot terminals.
      blur=1
      blur_optimized=1
      blur_params_num_passes=2
      blur_params_radius=5
      blur_params_noise=0.02
      blur_params_brightness=0.9
      blur_params_contrast=0.9
      blur_params_saturation=1.2

      # Drop shadows
      shadows=1
      shadow_only_floating=0
      shadows_size=5
      shadows_blur=30
      shadows_position_x=0
      shadows_position_y=5
      shadowscolor=0x00000077

      # Animations
      animations=1
      layer_animations=1
      animation_type_open=slide
      animation_type_close=slide
      animation_fade_in=1
      animation_fade_out=1

      # Overview
      hotarea_size=10
      enable_hotarea=1
      focus_on_activate=1

      # ---- Autostart ----
      # Mango has no autostart.sh convention (unlike some wlroots forks); the
      # only startup hook is exec-once in this config. Point it at our script.
      exec-once=${config.home.homeDirectory}/.config/mango/autostart.sh

      # ---- Per-tag layouts (requested) ----
      # All tags use the dwindle layout.
      tagrule=id:1,layout_name:dwindle
      tagrule=id:2,layout_name:dwindle
      tagrule=id:3,layout_name:dwindle
      tagrule=id:4,layout_name:dwindle
      tagrule=id:5,layout_name:dwindle
      tagrule=id:6,layout_name:dwindle
      tagrule=id:7,layout_name:dwindle
      tagrule=id:8,layout_name:dwindle
      tagrule=id:9,layout_name:dwindle

      # ---- Window rules ----
      windowrule=isfloating:1,no_force_center:1,isoverlay:1,width:1920,height:40,offsetx:0,offsety:-100,appid:plasmashell,title:launcher
      # ======================= Key bindings =======================
      # mod keys: super,ctrl,alt,shift,none. `bindl` = also works when locked.

      # terminal / launcher
      bind=SUPER,Return,spawn,${terminalSpawnCommand}${extraTerminalBind}
      bind=SUPER,d,spawn,fuzzel

      # close / quit
      bind=SUPER,q,killclient,
      bind=SUPER+SHIFT,e,quit
      bind=CTRL+ALT,Delete,quit

      # focus windows/columns
      bind=SUPER,Left,focusdir,left
      bind=SUPER,Right,focusdir,right
      bind=SUPER,Down,focusdir,down
      bind=SUPER,Up,focusdir,up
      bind=SUPER,h,focusdir,left
      bind=SUPER,l,focusdir,right
      bind=SUPER,j,focusdir,down
      bind=SUPER,k,focusdir,up

      # move/swap windows
      bind=SUPER+CTRL,Left,exchange_client,left
      bind=SUPER+CTRL,Right,exchange_client,right
      bind=SUPER+CTRL,Down,exchange_client,down
      bind=SUPER+CTRL,Up,exchange_client,up
      bind=SUPER+CTRL,h,exchange_client,left
      bind=SUPER+CTRL,l,exchange_client,right
      bind=SUPER+CTRL,j,exchange_client,down
      bind=SUPER+CTRL,k,exchange_client,up

      # focus monitors
      bind=SUPER+SHIFT,Left,focusmon,left
      bind=SUPER+SHIFT,Right,focusmon,right
      bind=SUPER+SHIFT,Down,focusmon,down
      bind=SUPER+SHIFT,Up,focusmon,up
      bind=SUPER+SHIFT,h,focusmon,left
      bind=SUPER+SHIFT,l,focusmon,right
      bind=SUPER+SHIFT,j,focusmon,down
      bind=SUPER+SHIFT,k,focusmon,up

      # move window to monitor
      bind=SUPER+SHIFT+CTRL,Left,tagmon,left
      bind=SUPER+SHIFT+CTRL,Right,tagmon,right
      bind=SUPER+SHIFT+CTRL,Down,tagmon,down
      bind=SUPER+SHIFT+CTRL,Up,tagmon,up
      bind=SUPER+SHIFT+CTRL,h,tagmon,left
      bind=SUPER+SHIFT+CTRL,l,tagmon,right
      bind=SUPER+SHIFT+CTRL,j,tagmon,down
      bind=SUPER+SHIFT+CTRL,k,tagmon,up

      # workspace(tag) navigation
      bind=SUPER,u,viewtoright_have_client
      bind=SUPER,i,viewtoleft_have_client
      bind=SUPER,Next,viewtoright_have_client
      bind=SUPER,Prior,viewtoleft_have_client
      # move window to adjacent workspace
      bind=SUPER+CTRL,u,tagtoright
      bind=SUPER+CTRL,i,tagtoleft
      bind=SUPER+CTRL,Next,tagtoright
      bind=SUPER+CTRL,Prior,tagtoleft

      # numbered tags
      bind=SUPER,1,view,1,0
      bind=SUPER,2,view,2,0
      bind=SUPER,3,view,3,0
      bind=SUPER,4,view,4,0
      bind=SUPER,5,view,5,0
      bind=SUPER,6,view,6,0
      bind=SUPER,7,view,7,0
      bind=SUPER,8,view,8,0
      bind=SUPER,9,view,9,0
      bind=SUPER+CTRL,1,tag,1,0
      bind=SUPER+CTRL,2,tag,2,0
      bind=SUPER+CTRL,3,tag,3,0
      bind=SUPER+CTRL,4,tag,4,0
      bind=SUPER+CTRL,5,tag,5,0
      bind=SUPER+CTRL,6,tag,6,0
      bind=SUPER+CTRL,7,tag,7,0
      bind=SUPER+CTRL,8,tag,8,0
      bind=SUPER+CTRL,9,tag,9,0

      # sizing / state
      bind=SUPER,r,switch_proportion_preset
      bind=SUPER,f,togglemaximizescreen,
      bind=SUPER+SHIFT,f,togglefullscreen,
      bind=SUPER+CTRL,f,set_proportion,1.0
      bind=SUPER,minus,setmfact,-0.05
      bind=SUPER,equal,setmfact,+0.05
      bind=SUPER,v,togglefloating,

      # lock (Super+Escape avoids colliding with focus-right on 'l';
      # lid-close below has the same lock behaviour)
      bindl=SUPER,Escape,spawn,swaylock

      # screenshots -- freeze the screen, select a region, then save to
      # ~/Pictures/Screenshots AND copy to the clipboard (see the `screenshot`
      # wrapper in this module). Ctrl+Print grabs the whole screen instead.
      bind=NONE,Print,spawn,screenshot area
      bind=CTRL,Print,spawn,screenshot screen

      # media / brightness keys
      bindl=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02+
      bindl=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02-
      bindl=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindl=NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindl=NONE,XF86MonBrightnessUp,spawn,brightnessctl set +2%
      bindl=NONE,XF86MonBrightnessDown,spawn,brightnessctl set 2%-
      bindl=NONE,XF86AudioPlay,spawn,playerctl play-pause
      bindl=NONE,XF86AudioPause,spawn,playerctl play-pause
      bindl=NONE,XF86AudioNext,spawn,playerctl next
      bindl=NONE,XF86AudioPrev,spawn,playerctl previous
      bindl=NONE,XF86AudioStop,spawn,playerctl stop

      # mango extras: reload, overview, cycle layout
      bind=SUPER+SHIFT,r,reload_config
      bind=SUPER,Tab,toggleoverview,
      bind=SUPER,n,switch_layout

      # ---- Mouse ----
      mousebind=SUPER,btn_left,moveresize,curmove
      mousebind=SUPER,btn_right,moveresize,curresize

      # ---- Scroll wheel: workspace nav ----
      axisbind=SUPER,DOWN,viewtoright_have_client
      axisbind=SUPER,UP,viewtoleft_have_client
      axisbind=SUPER+CTRL,DOWN,tagtoright
      axisbind=SUPER+CTRL,UP,tagtoleft

      # ---- Lid switch: lock on close ----
      switchbind=fold,spawn,swaylock
    '';

    # Run at launch via the exec-once directive above: waybar, xwayland
    # bridge, and the awww wallpaper.
    xdg.configFile."mango/autostart.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash

        # mango isn't recognized as "KDE" by Qt's desktop-detection, so Qt/KDE apps
        # fall back to a light theme unless this is set explicitly. Also propagate
        # it to systemd --user/dbus so app launchers and dbus-activated services see it.
        export QT_QPA_PLATFORMTHEME=kde
        systemctl --user import-environment QT_QPA_PLATFORMTHEME 2>/dev/null
        command -v dbus-update-activation-environment >/dev/null && \
          dbus-update-activation-environment --systemd QT_QPA_PLATFORMTHEME 2>/dev/null

        ${pkgs.waybar}/bin/waybar -c ~/.config/waybar/config-generic &

        ${pkgs.xwayland-satellite}/bin/xwayland-satellite &

        ${pkgs.awww}/bin/awww-daemon &
        sleep 1
        ${pkgs.awww}/bin/awww img ~/Pictures/Wallpapers/${settings.wallpaper}
      '';
    };

    # grim won't create the screenshots directory itself.
    home.file."Pictures/Screenshots/.keep".text = "";
  };
}
