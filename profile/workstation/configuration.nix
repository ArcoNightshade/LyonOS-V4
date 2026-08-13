{ pkgs, settings, ... }:
{
  imports = [
    ../../modules/desktop/mango.nix # mango compositor (shares desktop-core.nix)
    ../../modules/apps/software.nix # Installing all of the graphical software
    ../../modules/apps/steam.nix # Installing steam
    ../../modules/apps/supertuxkart.nix # Installing SuperTuxKart
    ../../modules/apps/protonvpn.nix # Proton VPN GTK client (via NetworkManager)
    ../../modules/experimental/cutting-edge.nix # Cutting edge stuff here (Nushell, uutils, and zoxide)
    ../../modules/apps/nushell.nix # Configuring nushell
    ../../modules/apps/zed.nix # Installing and configuring zed editor
    ../../modules/apps/btop.nix # btop with Catppuccin theme
    ../../modules/apps/mako.nix # mako notifications with Catppuccin theme
    ../../modules/apps/swaylock.nix # swaylock with Catppuccin theme
    ../../modules/apps/waybar.nix # Defining the waybar configuration
    ../../modules/apps/fuzzel.nix # Defining the fuzzel configuration
    ../../modules/apps/foot.nix # Defining the foot configuration
    ../../modules/apps/fastfetch.nix # Defining the fastfetch configuration
    ../../modules/commands/software.nix # Installing all of the non-graphical software
    ../../modules/commands/shell.nix # Aliases for bash; currently deprecated due to usage of nushell
    ../../modules/Development/nix.nix # Nixd and nil
    ../../modules/Development/rs.nix # Rustup
    ../../modules/Development/tauri.nix # Tauri + Node/TS/Svelte toolchain
  ];

  nixpkgs.config.allowUnfree = true;

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest; # Magic xanmod (Found better performance with it)
  # boot.kernelPackages = pkgs.linuxPackages_cachyos;

  services.scx.enable = true; # Better scheduler
  services.scx.scheduler = "scx_lavd"; # Latency-aware virtual deadline scheduler

  hardware.cpu.${settings.cpu}.updateMicrocode = true;

  # Below is a ton of kernel parameters and module stuff, modify at your own risk (Litle to none lol).
  boot.kernelParams = [
    "splash"
    "quiet"
    "rd.systemd.show_status=false"
    "udev.log_level=0"
    "rd.udev.log_level=0"
    "udev.log_priority=0"
    "fastboot"
    "mitigations=off"
    "noibrs"
    "noibpb"
    "nopti"
    "nospectre_v1"
    "nospectre_v2"
    "l1tf=off"
    "nospec_store_bypass_disable"
    "no_stf_barrier"
    "mds=off"
    "tsx=on"
    "tsx_async_abort=off"
    "nowatchdog"
    "panic=1"
    "boot.panic_on_fail"
    "transparent_hugepage=always"
    "init_on_alloc=0"
    "init_on_free=0"
    "idle=nomwait"
    "acpi_osi=Linux"
    "preempt=full"
    "uinput"
    # NVMe (Micron 2300) drops off the PCIe bus under link power management,
    # freezing the system — disable APST deep power states and PCIe ASPM.
    "nvme_core.default_ps_max_latency_us=0"
    "pcie_aspm=off"
    "amdgpu.runpm=0"
  ];

  boot.blacklistedKernelModules = [
    "nouveau" # Conflicts with Nvidia driver
    "nvidia" # It's bad

    # Obscure network protocols.
    "af_802154" # IEEE 802.15.4
    "appletalk" # Appletalk
    "atm" # ATM
    "ax25" # Amatuer X.25
    "can" # Controller Area Network
    "dccp" # Datagram Congestion Control Protocol
    "decnet" # DECnet
    "econet" # Econet
    "ipx" # Internetwork Packet Exchange
    "n-hdlc" # High-level Data Link Control
    "netrom" # NetRom
    "p8022" # IEEE 802.3
    "p8023" # Novell raw IEEE 802.3
    "psnap" # SubnetworkAccess Protocol
    "rds" # Reliable Datagram Sockets
    "rose" # ROSE
    "sctp" # Stream Control Transmission Protocol
    "tipc" # Transparent Inter-Process Communication
    "x25" # X.25
    # Old or rare or insufficiently audited filesystems.
    "adfs" # Active Directory Federation Services
    "affs" # Amiga Fast File System
    "befs" # "Be File System"
    "bfs" # BFS, used by SCO UnixWare OS for the /stand slice
    "cifs" # Common Internet File System
    "cramfs" # compressed ROM/RAM file system
    "efs" # Extent File System
    "erofs" # Enhanced Read-Only File System
    "exofs" # EXtended Object File System
    "f2fs" # Flash-Friendly File System
    "freevxfs" # Veritas filesystem driver
    "gfs2" # Global File System 2
    "hfs" # Hierarchical File System (Macintosh)
    "hfsplus" # Same as above, but with extended attributes.
    "hpfs" # High Performance File System (used by OS/2)
    "jffs2" # Journalling Flash File System (v2)
    "jfs" # Journaled File System - only useful for VMWare sessions
    "ksmbd" # SMB3 Kernel Server
    "minix" # minix fs - used by the minix OS
    "nfs" # Network File System
    "nfsv3" # Network File System (v3)
    "nfsv4" # Network File System (v4)
    "nilfs2" # New Implementation of a Log-structured File System
    "omfs" # Optimized MPEG Filesystem
    "qnx4" # Extent-based file system used by the QNX4 OS.
    "qnx6" # Extent-based file system used by the QNX6 OS.
    "sysv" # implements all of Xenix FS, SystemV/386 FS and Coherent FS.
    "udf" # https://docs.kernel.org/5.15/filesystems/udf.html
    "vivid" # Virtual Video Test Driver (unnecessary)

    # Disable Thunderbolt and FireWire to prevent DMA attacks
    "firewire-core"
  ];
}
