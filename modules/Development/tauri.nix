{ lib, pkgs, settings, ... }:
let
  # Native libraries Tauri v2 links against on Linux (webview + GTK stack).
  # These are NOT installed into the profile — librsvg and gdk-pixbuf both ship a
  # gdk-pixbuf loaders.cache which collides in home-manager's buildEnv. Instead we
  # only reference them through the pkg-config / linker search paths below, which
  # still pins them into the closure so they won't be garbage-collected.
  tauriDeps = with pkgs; [
    webkitgtk_4_1        # the actual webview Tauri renders into
    gtk3
    libsoup_3
    glib
    cairo
    pango
    gdk-pixbuf
    atk
    harfbuzz
    openssl
    zlib                 # transitive pkg-config dep of gdk-3.0
    dbus                 # libdbus-sys (via tray-icon/appindicator) needs dbus-1.pc
    librsvg              # SVG rendering for GTK icons
    libappindicator-gtk3 # system tray support
  ];
in
{
  # NOTE: this relies on the Rust toolchain from ./rs.nix being present, so keep
  # both imported together. Node/TS/Svelte tooling lives here; Rust does not.
  home-manager.users.${settings.account.name} = {
    home.packages = (with pkgs; [
      # JS/TS runtime + package manager (npm ships with nodejs; pnpm for choice)
      nodejs_22
      pnpm

      # Language servers / formatters for a Svelte + TS frontend
      typescript
      typescript-language-server
      svelte-language-server
      vscode-langservers-extracted   # html / css / json / eslint LSPs
      tailwindcss-language-server
      prettier

      # Tauri CLI + build glue (clang comes from rs.nix as the C/C++ driver)
      cargo-tauri
      pkg-config

      # Installed (not just search-path'd) so pkg-config reliably resolves
      # webkit2gtk-4.1 in any shell, login or not. Unlike librsvg/gdk-pixbuf
      # it ships no gdk-pixbuf loaders.cache, so it won't collide in buildEnv.
      webkitgtk_4_1
    ]);

    # Let `cargo build` / `tauri build` discover the native libs above.
    home.sessionVariables = {
      # Some packages (e.g. zlib) ship their .pc in share/pkgconfig, not
      # lib/pkgconfig — scan both so transitive Requires resolve.
      PKG_CONFIG_PATH = lib.concatStringsSep ":" [
        (lib.makeSearchPathOutput "dev" "lib/pkgconfig" tauriDeps)
        (lib.makeSearchPathOutput "dev" "share/pkgconfig" tauriDeps)
      ];
      # webkitgtk & friends are dlopen'd at runtime, so put them on the loader path.
      LD_LIBRARY_PATH =
        lib.makeLibraryPath tauriDeps;
      # Nvidia-less / compositing quirks: disabling DMABUF avoids a blank webview
      # under some Wayland compositors during `tauri dev`.
      WEBKIT_DISABLE_DMABUF_RENDERER = "1";
    };
  };
}
