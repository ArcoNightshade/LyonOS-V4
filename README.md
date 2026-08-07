#### LyonOS V4 - Now with experimental "Illumix" integration

Changes include
  **NixOS version bump**
  - nixpkgs 25.11 → 26.05, home-manager release-25.11 → release-26.05
  
  **Centralized settings (big addition)**
  - settings is now a rec block with many new fields:
    - hostname — system hostname
    - flakePath — path to the flake
    - colorScheme — powered by the new nix-colors input (defaults to
  catppuccin-mocha) 
    - font block — FiraCode Nerd Font, sizes for terminal and UI
    - cursor block — theme (oreo_purple_cursors) and size
    - wallpaper, terminal, browser, cpu — all configurable in one place
    
    - new Illumix module, allows for usage of an Illumos distro for your shell via KVM

  **New input**
  - nix-colors added for declarative colorscheme management
  
  **New app modules**
  - modules/apps/btop.nix
  - modules/apps/mako.nix
  - modules/apps/swaylock.nix

  **Flake cleanup**
  - Chaotic Nyx modules deduplicated into a sharedModules list instead of being
  repeated in each config

LyonOS is my personal Linux distribution based on NixOS. This repository contains all the flake that I use on my laptop, desktop, and VMs.

---
### Setup
```
git clone https://github.com/ArcoNightshade/LyonOS-V3 ~/.lyonos && rm -rf ~/.lyonos/.git
```

```
cp /etc/nixos/hardware-configuration.nix ~/.lyonos/profile/workstation/hardware.nix
```


Set your username.
```
nano ~/.lyonos/flake.nix
```


Specify your drive type (scroll to the bottom)
```
nano ~/.lyonos/compose.nix
```


Set your password, use this to get the hash
```
mkpasswd -m sha-512 <password>
```


Place the output in `hashedPassword = "";`
```
nano ~/.lyonos/compose.nix
``````

Rebuild & reboot to be safe, or just switch.
```
sudo nixos-rebuild boot --flake ~/.lyonos#workstation
```
---

### Commands
```
sudo nixos-rebuild switch --flake ~/.lyonos#workstation
```
nixos-rebuild has a few options:
* switch  : switches to the new configuration immediately
* boot    : builds the next generation but does not switch until reboot
* dry-run : only evaluates the code to see if it works
* test    : switches to the new generation but does not save it to the boot menu

```
sudo nixos-rebuild switch --flake ~/.lyonos#workstation --rollback
```
Rolls back to the previous generation.

```
sudo nix-collect-garbage
```
Deletes all previous generations so you don't run out of space.

```
sudo nix flake update --flake ~/.lyonos#workstation
```
Update system.

```
nix-shell -p cowsay
```
Installs software to the shell (not the system) and is discarded when the shell (terminal) is closed.

#### Important links:

[How to setup NVIDIA](https://nixos.wiki/wiki/Nvidia) <br>
Copy paste to compose.nix and add `config` to `{ settings, ... }:` => `{ settings, config, ... }:`
```
  hardware.nvidia.open = false;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;
  boot.blacklistedKernelModules = [ "nouveau" ];
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.kernelParams = [
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia-drm.fbdev=1"
    "nvidia"
  ];
```


[NixOS packages](https://search.nixos.org/packages)

[NixOS options](https://search.nixos.org/options)

[Home manager options](https://home-manager-options.extranix.com/)
