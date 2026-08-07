# illumos-backed terminals: `ish` (the default terminal command, see the
# MangoWC bind in profile/illumix/configuration.nix) waits for the guest's
# sshd to come up, then drops you into it. `illumix-enroll` installs a
# passwordless key one time so `ish` never prompts.
{ lib, pkgs, config, ... }:
let
  cfg = config.illumix.terminal;

  ish = pkgs.writeShellApplication {
    name = "ish";
    runtimeInputs = [ pkgs.openssh pkgs.netcat ];
    text = ''
      host="${cfg.guestHost}"
      until nc -z "$host" 22 2>/dev/null; do
        printf '\r  waiting for illumos guest...'
        sleep 1
      done
      printf '\n'
      ${if cfg.tmux then
        ''exec ssh -t "$host" "tmux new -A -s main"''
      else
        ''exec ssh "$host"''
      }
    '';
  };

  illumixEnroll = pkgs.writeShellApplication {
    name = "illumix-enroll";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      key="$HOME/.ssh/id_ed25519"
      if [ ! -f "$key" ]; then
        ssh-keygen -t ed25519 -f "$key" -N ""
      fi
      ssh-copy-id "${cfg.guestUser}@${cfg.guestHost}"
      echo "Enrolled -- 'ish' should now log in without a password."
    '';
  };
in
{
  options.illumix.terminal = {
    guestHost = lib.mkOption {
      type = lib.types.str;
      default = "illumix-guest";
      description = "SSH host alias for the illumos guest (see programs.ssh.extraConfig below).";
    };

    guestUser = lib.mkOption {
      type = lib.types.str;
      default = "lyon";
      description = "Username to SSH into on the guest.";
    };

    tmux = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Attach to a persistent tmux session on the guest instead of a bare shell.";
    };
  };

  config = {
    programs.ssh.extraConfig = ''
      Host ${cfg.guestHost}
        HostName 10.100.0.2
        User ${cfg.guestUser}
        StrictHostKeyChecking accept-new
        ServerAliveInterval 15
    '';

    environment.systemPackages = [ ish illumixEnroll ];
  };
}
