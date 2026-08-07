# Keeps the stocks repo's devShell alive across the nightly garbage collection.
#
# nix.gc runs `nix-collect-garbage --delete-older-than 3d` at 03:15 every day.
# That flag only bounds how long *profile generations* survive; store paths with no
# GC root are deleted regardless of age. `nix develop` registers no root, so the
# CUDA/torch python env was collected every night and rebuilt from source on next
# use — including by the stocks-trading-* units, which shell out to `nix develop`
# minutes before they place orders.
#
# Recording the devShell in a profile makes it a GC root. Refreshing that profile
# on a timer keeps the pin tracking flake.lock instead of pinning a stale closure
# forever, and drops the superseded generations so they can be collected.
{ pkgs, ... }:

let
  repo = "/home/ianh/Repositories/stocks";
  profile = "/home/ianh/.local/state/nix/profiles/stocks-dev";
in
{
  systemd.services.stocks-devshell-pin = {
    description = "Pin the stocks devShell as a nix GC root";

    # Only matters if both land in the same transaction; the timers are 15 min
    # apart, so this is a guard against them ever coinciding.
    before = [ "nix-gc.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    path = [
      pkgs.nix
      pkgs.git
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "ianh";
      Group = "users";
      WorkingDirectory = repo;
      # A cold rebuild of the torch/CUDA env is slow; the steady state is seconds.
      TimeoutStartSec = "2hr";
      Nice = 10;
    };

    script = ''
      nix develop --profile ${profile} --command true
      nix-env --profile ${profile} --delete-generations +3
    '';
  };

  systemd.timers.stocks-devshell-pin = {
    description = "Refresh the stocks devShell GC root ahead of nix-gc";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
    };
  };
}
