# PLACEHOLDER -- this is not a real hardware-configuration.nix.
#
# On the target (second Dell Latitude 5420), run:
#   nixos-generate-config --show-hardware-config > profile/illumix/hardware.nix
# then re-add the `../../modules/hardware/latitude-5420.nix` import below (or
# just leave it -- it's also imported from configuration.nix, so the fix
# survives even if this file gets fully regenerated and this import is lost).
#
# Do not modify the generated fileSystems/boot.initrd sections by hand;
# regenerate them instead. This stub only exists so the flake evaluates
# before the target has been imaged.
{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../modules/hardware/latitude-5420.nix
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Replace with the real filesystem layout from nixos-generate-config.
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000"; # TODO
    fsType = "btrfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0000-0000"; # TODO
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
