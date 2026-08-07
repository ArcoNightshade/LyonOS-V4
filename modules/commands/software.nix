{ lib, pkgs, inputs, settings, ... }:
let
  unstable = import inputs.nixpkgs-unstable { inherit (pkgs) system; config.allowUnfree = true; };
in {
  home-manager.users.${settings.account.name}.home.packages = with pkgs; [

    # Dev tools
    # Both gcc and clang wrappers ship meta.priority = 10, so they tie on the
    # shared bin/cc, bin/c++ and bin/cpp symlinks and home-manager's buildEnv
    # refuses to merge them. hiPrio lets gcc win those; clang (from
    # ./Development/rs.nix, the mold driver referenced by name as "clang")
    # keeps its own clang/clang++ binaries, so both compilers stay usable.
    git lazygit neovim (lib.hiPrio gcc) texlab unstable.claude-code

    # Creative/Music
    cmus

    # Utils
    fastfetch onefetch hyfetch brightnessctl flatpak zip unzip senpai ranger gnumake

    # Desktop extras (mako, wallpaper daemon, cursor theme)
    mako awww oreo-cursors-plus

    # Github
    gh gh-contribs
  ];
}
