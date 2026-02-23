# Stock Trading Bot Service
# Runs the portfolio orchestrator once daily between 9:50 AM and 10:15 AM
# on weekdays only, with a randomized start time within that window.
#
# The service uses `nix develop` to get the correct Python environment.
{ config, pkgs, ... }:

{
  # Systemd service for the trading bot
  systemd.services.stocks-trading = {
    description = "Alpaca Stock Trading Bot - Portfolio Orchestrator";

    # Don't start automatically on boot - use timer instead
    wantedBy = [ ];

    # Ensure network is available
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "ianh";
      Group = "users";
      WorkingDirectory = "/home/ianh/Repositories/stocks";

      # Run the portfolio master via nix develop
      ExecStart = "${pkgs.nix}/bin/nix develop --command python main.py --portfolio-master configs/portfolio_master.yaml";

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";

      # Timeout after 2 hours
      TimeoutStartSec = "2hr";

      # Nice level - slightly lower priority than interactive processes
      Nice = 5;
    };
  };

  # Timer to trigger the service daily on weekdays
  systemd.timers.stocks-trading = {
    description = "Daily Stock Trading Bot Timer (Weekdays)";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      # Run at 9:50 AM Eastern on weekdays only (Mon-Fri)
      # System timezone is already America/New_York
      OnCalendar = "Mon..Fri *-*-* 09:50:00";

      # Randomize the start by up to 25 minutes (so between 9:50 AM and 10:15 AM)
      RandomizedDelaySec = "25min";

      # Persist timer state across reboots
      Persistent = true;
    };
  };
}
