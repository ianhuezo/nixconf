# Keeps the crunk repo's devShell alive across the nightly garbage collection.
#
# Same problem and fix as stocks-devshell.nix: `nix develop` registers no GC root,
# so nix-gc (03:15) deleted the shell and the next `nix develop` fetched it again.
# Recording it in a profile makes it a root; refreshing the profile nightly keeps
# the pin tracking crunk's flake.lock and lets superseded generations be collected.
{ pkgs, ... }:

let
  repo = "/home/ianh/nvme2/Repositories/crunk";
  profile = "/home/ianh/.local/state/nix/profiles/crunk-dev";
in
{
  systemd.services.crunk-devshell-pin = {
    description = "Pin the crunk devShell as a nix GC root";

    before = [ "nix-gc.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # The repo lives on the nvme2 drive, not the root filesystem.
    unitConfig.RequiresMountsFor = repo;

    path = [
      pkgs.nix
      pkgs.git
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "ianh";
      Group = "users";
      WorkingDirectory = repo;
      # uv, Python, and two libraries: seconds warm, minutes cold.
      TimeoutStartSec = "30min";
      Nice = 10;
    };

    script = ''
      nix develop --profile ${profile} --command true
      nix-env --profile ${profile} --delete-generations +3
    '';
  };

  systemd.timers.crunk-devshell-pin = {
    description = "Refresh the crunk devShell GC root ahead of nix-gc";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
    };
  };
}
