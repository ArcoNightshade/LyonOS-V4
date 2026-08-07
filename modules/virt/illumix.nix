# Illumix: a headless illumos guest appliance, booted under QEMU/KVM with a
# serial-only console (no viogpu, no graphical guest path -- see
# modules/virt/illumix-terminal.nix for the SSH-backed terminal that talks to
# it). Networking (tap + NAT + dnsmasq) lives in modules/net/illumix-nat.nix,
# imported alongside this module.
#
# Guest one-time setup, done once inside the installed illumos guest:
#   1. svcadm enable ssh
#   2. useradd -m <guestUser>; passwd <guestUser>
#   3. from the host, run `illumix-enroll` once to install a passwordless key
#      (then `ish` / `foot -e ish` logs in without a password)
#
# Bumping a pinned ISO: change the url below, run
#   nix store prefetch-file <url>
# and paste the resulting sha256 back in.
{ lib, pkgs, config, ... }:
let
  cfg = config.illumix;

  isoSources = {
    omnios = pkgs.fetchurl {
      url = "https://downloads.omnios.org/media/stable/omnios-r151058.iso";
      hash = "sha256-E+p8SVDO3bqWlZmJP8o6qu6YwH95UlKRQxEdGMxKJdM=";
    };
    openindiana-text = pkgs.fetchurl {
      url = "https://dlc.openindiana.org/isos/hipster/20260430/OI-hipster-text-20260430.iso";
      hash = "sha256-XyZh71flEMNijA1hUcfW/cNn6/oHPiW3dNmKKJlO8EM=";
    };
    openindiana-gui = pkgs.fetchurl {
      url = "https://dlc.openindiana.org/isos/hipster/20260430/OI-hipster-gui-20260430.iso";
      hash = "sha256-TAXPcOmFoT7Eayvj74R22au0SEhZeTRnanUdLJCuX9Y=";
    };
  };
  iso = isoSources.${cfg.distro};

  illumixVmRun = pkgs.writeShellApplication {
    name = "illumix-vm-run";
    runtimeInputs = [ pkgs.qemu_kvm pkgs.coreutils ];
    text = ''
      state_dir="${cfg.stateDir}"
      run_dir="/run/illumix"
      name="${cfg.name}"
      disk="$state_dir/$name.qcow2"
      vars="$state_dir/''${name}_VARS.fd"
      marker="$state_dir/$name.installing"

      mkdir -p "$state_dir" "$run_dir"

      if [ ! -f "$disk" ]; then
        qemu-img create -f qcow2 "$disk" "${cfg.diskSize}"
        touch "$marker"
      fi

      if [ ! -f "$vars" ]; then
        cp "${pkgs.OVMF.variables}" "$vars"
        chmod u+w "$vars"
      fi

      args=(
        "-machine" "q35,accel=kvm"
        "-cpu" "host"
        "-smp" "${toString cfg.cores}"
        "-m" "${toString cfg.memory}"
        "-drive" "if=pflash,unit=0,format=raw,readonly=on,file=${pkgs.OVMF.firmware}"
        "-drive" "if=pflash,unit=1,format=raw,file=$vars"
        "-drive" "file=$disk,if=virtio,format=qcow2,cache=none,aio=native,discard=unmap"
        "-netdev" "tap,id=n0,ifname=${cfg.tapInterface},script=no,downscript=no"
        "-device" "virtio-net-pci,netdev=n0,mac=${cfg.macAddress}"
        "-rtc" "base=utc,driftfix=slew"
        "-global" "kvm-pit.lost_tick_policy=discard"
        "-monitor" "unix:$run_dir/$name.monitor.sock,server,nowait"
        ${lib.concatMapStringsSep "\n        " lib.escapeShellArg cfg.extraQemuArgs}
      )

      if [ -f "$marker" ]; then
        args+=( "-cdrom" "${iso}" "-boot" "order=dc,menu=on" )
      else
        args+=( "-boot" "order=c" )
      fi

      args+=(
        "-chardev" "socket,id=ser0,path=$run_dir/$name.console.sock,server=on,wait=off"
        "-serial" "chardev:ser0"
        "-nographic"
      )

      exec qemu-system-x86_64 "''${args[@]}"
    '';
  };

  illumixConsole = pkgs.writeShellApplication {
    name = "illumix-console";
    runtimeInputs = [ pkgs.socat ];
    text = ''
      echo "Connecting to ${cfg.name}'s serial console. Escape with Ctrl-]."
      exec socat -,raw,echo=0,escape=0x1d "UNIX-CONNECT:/run/illumix/${cfg.name}.console.sock"
    '';
  };

  illumixMonitor = pkgs.writeShellApplication {
    name = "illumix-monitor";
    runtimeInputs = [ pkgs.socat ];
    text = ''
      exec socat -,raw,echo=0 "UNIX-CONNECT:/run/illumix/${cfg.name}.monitor.sock"
    '';
  };

  illumixInstalled = pkgs.writeShellApplication {
    name = "illumix-installed";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      rm -f "${cfg.stateDir}/${cfg.name}.installing"
      systemctl restart illumix-vm.service
      echo "Install marker cleared -- illumix-vm will boot from disk from now on."
    '';
  };

  illumixReset = pkgs.writeShellApplication {
    name = "illumix-reset";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      echo "This permanently erases the ${cfg.name} guest disk and forces a reinstall."
      read -r -p "Type 'reset' to confirm: " answer
      if [ "$answer" != "reset" ]; then
        echo "Aborted."
        exit 1
      fi
      systemctl stop illumix-vm.service
      rm -f \
        "${cfg.stateDir}/${cfg.name}.qcow2" \
        "${cfg.stateDir}/${cfg.name}_VARS.fd" \
        "${cfg.stateDir}/${cfg.name}.installing"
      systemctl start illumix-vm.service
      echo "Guest disk wiped -- illumix-vm will reinstall from ISO on next boot."
    '';
  };
in
{
  options.illumix = {
    enable = lib.mkEnableOption "the illumix headless illumos guest appliance";

    distro = lib.mkOption {
      type = lib.types.enum [ "omnios" "openindiana-text" "openindiana-gui" ];
      default = "omnios";
      description = "Which illumos distribution ISO to install the guest from.";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "illumix";
      description = "Guest name; used for the disk image, sockets and systemd unit naming.";
    };

    memory = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4096;
      description = "Guest RAM, in MiB.";
    };

    cores = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = "Guest vCPU count.";
    };

    diskSize = lib.mkOption {
      type = lib.types.str;
      default = "40G";
      description = "Guest disk size, as passed to `qemu-img create`.";
    };

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/illumix";
      description = "Directory holding the guest disk image, UEFI vars and install marker.";
    };

    shareDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.illumix.stateDir}/share";
      description = "Directory NFS-exported to the guest (illumos has no virtiofs/9p client).";
    };

    tapInterface = lib.mkOption {
      type = lib.types.str;
      default = "illumix0";
      description = "Host-side tap interface the guest's virtio-net device attaches to.";
    };

    macAddress = lib.mkOption {
      type = lib.types.str;
      default = "52:54:00:ab:cd:01";
      description = "MAC address of the guest's virtio-net device.";
    };

    extraQemuArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments appended to the qemu-system-x86_64 invocation.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.virtualisation.libvirtd.enable;
        message = "illumix requires virtualisation.libvirtd.enable = false (both grab /dev/kvm).";
      }
    ];

    users.groups.illumix = { };
    users.users.illumix = {
      isSystemUser = true;
      group = "illumix";
      extraGroups = [ "kvm" ];
      home = cfg.stateDir;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 illumix illumix - -"
      "d ${cfg.shareDir} 2775 illumix illumix - -"
      "d /run/illumix 0750 illumix illumix - -"
    ];

    systemd.services.illumix-vm = {
      description = "Illumix headless illumos guest (${cfg.name})";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-networkd.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${illumixVmRun}/bin/illumix-vm-run";
        Restart = "on-failure";
        RestartSec = 5;
        User = "illumix";
        Group = "illumix";
        SupplementaryGroups = [ "kvm" ];
        RuntimeDirectory = "illumix";
        RuntimeDirectoryMode = "0750";
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.stateDir "/run/illumix" ];
        DeviceAllow = [ "/dev/kvm rw" "/dev/net/tun rw" ];
        DevicePolicy = "closed";
      };
    };

    environment.systemPackages = [
      illumixConsole
      illumixMonitor
      illumixInstalled
      illumixReset
    ];
  };
}
