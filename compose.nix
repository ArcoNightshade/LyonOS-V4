{ lib, pkgs, inputs, settings, ... }: {
  networking.hostName = settings.hostname;
  system.stateVersion = "26.05"; # Don't change this
  time.timeZone = settings.timeZone;

  environment.sessionVariables.NIX_AUTO_RUN = "1";
  environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";

  programs.dconf.enable = true;

  /* Nix settings */
  nix.package = pkgs.lix;
  nix.settings.sandbox = true;
  nix.extraOptions = "experimental-features = nix-command flakes";
nix.settings.warn-dirty = false;
  nix.settings.trusted-users = [ "@wheel" ];
  nix.settings.allowed-users = [ "${settings.account.name}" ];

  /* Settings for optimisation of /nix/store */
  nix.settings.auto-optimise-store = true;
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "weekly" ];

  fonts.packages = (with pkgs.nerd-fonts; [
    fira-code        # current default
    symbols-only     # all NF icons as a standalone font
    jetbrains-mono
    hack
    iosevka
    iosevka-term
    ubuntu-mono
    ubuntu
    meslo-lg         # used by powerlevel10k / many prompts
    caskaydia-cove   # Cascadia Code with NF patches
    victor-mono
    space-mono
    mononoki
    geist-mono
    monaspace
    commit-mono
  ]) ++ (with pkgs; [
    font-awesome        # fa- icons used by waybar and many apps
    noto-fonts          # broad Unicode coverage
    noto-fonts-cjk-sans # CJK characters
    noto-fonts-color-emoji # emoji
  ]);

  /* Setting up home-manager */
  home-manager.backupFileExtension = "bak";
  home-manager.sharedModules = [
    inputs.nix-colors.homeManagerModules.default
    inputs.nix-index-database.homeModules.nix-index
  ];
  home-manager.users.${settings.account.name} = {
    programs.home-manager.enable = true;
    home.stateVersion = "26.05";
    colorScheme = settings.colorScheme;
  };

  /* Setting up the user (Change your password, mine wont work for you!) */
  users.users.${settings.account.name} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    hashedPassword = "$6$DaUWNF5nAbYNHkEF$sWF6rjw2Pw3E8gKfeqA/HvqUIoGoR431cqUsU0cMEo.I4YcbjtOzSW3Dj2Lk6NhDCcOiA9aJJW9LtvqKtmeDy1"; # Give it a guess, if you want.
  };

  /* Privilege escalation: doas instead of sudo */
  security.sudo.enable = true;
  /*
  security.doas = {
    enable = true;
    symlinkToSudo = true;
  };	
  # Upstream opendoas calls pam_authenticate once and aborts on the first
  #  wrong password. Patch it to retry up to 3 times, like sudo does.
  security.doas.package = pkgs.doas.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./modules/apps/doas-3-tries.patch ];
  });
  security.doas.extraRules = [{
    users = [ "${settings.account.name}" ];
    keepEnv = true;
    persist = true;   # cache auth per-session like sudo timestamp
  }]; 
  */

  /* Enabling graphical stuff for steam */
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = settings.flakePath; # sets NH_OS_FLAKE variable for you
  };

  /* Compressed memory */
  services.zram-generator.enable = true;
  services.zram-generator.settings.zram0.zram-size = "ram / 2"; # Might wanna change this to "ram" if you are having issues

  /* Power services */
  services = {
    power-profiles-daemon.enable = true;
    thermald.enable = false;
    upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 10;
      percentageAction = 5;
      criticalPowerAction = "Hibernate";
    };
  };

  powerManagement.cpuFreqGovernor = "powersave"; # Change this depending on your needs
  services.tlp.enable = false;
  virtualisation.waydroid.enable = true;

  /* Network */
  networking.firewall.enable = true;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "wpa_supplicant";

  /* iwd and NetworkManager desync after suspend/hibernate, leaving wifi in a
     "no secrets provided" state — restart both on resume to re-sync them */
  systemd.services.iwd-resume = {
    after = [ "suspend.target" "hibernate.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart iwd.service NetworkManager.service";
    };
  };
  # services.openssh.enable = true;
  # services.printing.enable = true;

  /* UEFI */
  boot.loader.systemd-boot.enable = false;
  boot.loader.limine = {
    enable = true;
    efiSupport = true;
    style = {
      wallpapers = [
        ./modules/desktop/wallpapers/redbull-max.png # Go ahead and change this to a different picture
      ];
    interface.resolution = "1920x1080";
    interface.branding = "Welcome to LyonOS!";
    };
  };
  boot.loader.efi.efiSysMountPoint = "/boot";
  # boot.loader.grub.efiSupport = true;

  /* Uncomment your drive type */
  boot.loader.grub.device =
  # "/dev/vda";     /* Virtual drive     */
  # "/dev/sda";     /* Physical drive    */
  "/dev/nvme0n1"; /* Solid state drive */
}
