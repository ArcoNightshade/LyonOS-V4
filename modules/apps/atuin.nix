{ ... }:
{
  # Magical shell history — Nushell has no dedicated integration option in
  # nixpkgs, so `atuin init nu` is pre-rendered to ~/.atuin.nu and sourced
  # from config.nu (see nushell.nix), same as zoxide.
  programs.atuin.enable = true;
}
