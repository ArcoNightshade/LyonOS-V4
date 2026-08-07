{
  description = "LyonOS Official Nix flake";
  inputs = {
    nix-colors.url = "github:misterio77/nix-colors";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Mango compositor -- nixpkgs' mangowc (0.12.8) predates the `dwindle`
    # layout, so pull the package straight from upstream (pinned release).
    mango = {
      url = "github:DreamMaoMao/mango/0.15.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ ... }:
    let
      settings = rec {
        timeZone    = "America/New_York";  # Set your timezone
        hostname    = "RTS";               # Set your hostname
        account.name = "lyon";             # Set your username
        flakePath   = "/home/${account.name}/.lyonos"; # Path to this flake
        colorScheme = inputs.nix-colors.colorSchemes.catppuccin-mocha; # Color scheme
        font = {
          name     = "FiraCode Nerd Font";       # UI / editor font
          monoName = "FiraCode Nerd Font Mono";  # Terminal font
          size     = 11;                         # Terminal font size
          uiSize   = 14;                         # UI font size (fuzzel, etc.)
        };
        cursor = {
          theme = "oreo_purple_cursors";
          size  = 24;
        };
        wallpaper = "elec1.png"; # Default wallpaper filename from Pictures/Wallpapers/
        terminal  = "foot";        # Default terminal emulator
        terminalCommand = null;    # Override for mango's Return-bind spawn command (falls back to `terminal`)
        terminalEscapeHatch = null; # Optional secondary bind (SUPER+SHIFT+Return) for a native-shell escape hatch
        browser   = "firefox";     # Default browser
        cpu       = "intel";       # CPU vendor: "intel" or "amd"
      };
      system = "x86_64-linux"; # System architecture
      sharedModules = [
        inputs.home-manager.nixosModules.home-manager
      ];
    in
    {
      nixosConfigurations.workstation = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs settings; };
        modules = sharedModules ++ [
          { nixpkgs.hostPlatform = system; }
          ./profile/workstation/hardware.nix
          ./profile/workstation/configuration.nix
          ./compose.nix
        ];
      };
      nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs settings; };
        modules = sharedModules ++ [
          { nixpkgs.hostPlatform = system; }
          ./profile/iso/hardware.nix
          ./profile/iso/configuration.nix
          ./compose.nix
        ];
      };
      nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs settings; };
        modules = sharedModules ++ [
          { nixpkgs.hostPlatform = system; }
          ./profile/desktop/hardware.nix
          ./profile/desktop/configuration.nix
          ./compose.nix
        ];
      };
      # Illumix: same MangoWC/NixOS desktop, but every terminal is an SSH
      # session into a headless illumos guest. Reuses `settings` with just
      # the hostname and mango terminal bind overridden -- workstation's own
      # `settings` (and build) is untouched.
      nixosConfigurations.illumix = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          settings = settings // {
            hostname = "illumix";
            terminalCommand = "foot -e ish"; # SUPER+Return -> illumos guest
            terminalEscapeHatch = "foot";     # SUPER+SHIFT+Return -> native NixOS shell
          };
        };
        modules = sharedModules ++ [
          { nixpkgs.hostPlatform = system; }
          ./profile/illumix/hardware.nix
          ./profile/illumix/configuration.nix
          ./compose.nix
        ];
      };
    };
}
