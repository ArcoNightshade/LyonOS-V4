# Shared hardware quirks for the Dell Latitude 5420 fleet. workstation carries
# an inlined copy of the PCIe/NVMe params (see profile/workstation/configuration.nix);
# this module exists so a second 5420 (illumix) gets the same fixes without
# touching that profile.
{ ... }:
{
  boot.kernelParams = [
    "nvme_core.default_ps_max_latency_us=0" # Micron 2300 drops off PCIe under APST
    "pcie_aspm=off"
    "amdgpu.runpm=0" # Polaris12 dGPU red-screen on runtime PM
  ];

  boot.kernelModules = [ "kvm-intel" "tun" "vhost_net" ];

  virtualisation.libvirtd.enable = false;

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
}
