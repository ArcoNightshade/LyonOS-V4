{ pkgs, settings, ... }:
let
  # codelldb debug adapter (Mason's prebuilt binary can't run on NixOS)
  codelldb = pkgs.vscode-extensions.vadimcn.vscode-lldb;
in
{
  home-manager.users.${settings.account.name} = {
    home.packages = [
      # rustup manages toolchains imperatively:
      #   rustup default stable        (or nightly)
      #   rustup component add rust-analyzer clippy rust-src rustfmt llvm-tools
      pkgs.rustup
      codelldb
    ] ++ (with pkgs; [
      mold   # drop-in linker, much faster than ld/lld for big Rust builds
      clang  # driver used to invoke mold (-fuse-ld=mold)
      qemu   # boot-test bare-metal targets (e.g. PureshadeOS under qemu-system-x86_64)
    ]);
    # Let Neovim (rustaceanvim) find the codelldb adapter declaratively
    home.sessionVariables.CODELLDB_PATH =
      "${codelldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";

    # Use clang + mold as the linker for native Linux Rust builds. Applies to
    # every cargo invocation (Tauri included) via the user-global cargo config.
    home.file.".cargo/config.toml".text = ''
      [target.x86_64-unknown-linux-gnu]
      linker = "clang"
      rustflags = ["-C", "link-arg=-fuse-ld=mold"]
    '';
  };
}
