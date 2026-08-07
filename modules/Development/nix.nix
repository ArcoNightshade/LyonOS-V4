{
  inputs,
  pkgs,
  settings,
  ...
}:
let
  # Bring in the unstable channel
  unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.hostPlatform.system; };
in
{
  # This line says what packages your user should have
  # installed, they aren't shared with root or other users
  home-manager.users.${settings.account.name} = {
    home.packages = with pkgs; [
      nixd
      nil
    ];
    programs.nix-index-database.comma.enable = true;
  };
  # Check https://search.nixos.org/packages to see which packages are available
}
