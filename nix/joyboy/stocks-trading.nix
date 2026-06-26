# Stock Trading Bot Services
# Two daily runs on weekdays, env-scoped:
#   - staging: 09:50 ET ± 25min (window 09:50–10:15)
#   - live:    10:30 ET ± 25min (window 10:30–10:55)
# Non-overlapping jitter windows (15-min gap) plus `After=` on the live unit
# so it queues behind staging even if staging runs long.
#
# Both use `nix develop` for the correct Python environment.
{ config, pkgs, ... }:

let
  liveMaster = "configs/portfolio_master.yaml";
  stagingMaster = "configs/portfolio_master_staging.yaml";

  mkTradingService = { env, master, extraAfter ? [ ] }: {
    description = "Alpaca Stock Trading Bot - Portfolio Orchestrator (${env})";

    # Don't start on boot - timer drives it.
    wantedBy = [ ];

    after = [ "network-online.target" ] ++ extraAfter;
    requires = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "ianh";
      Group = "users";
      WorkingDirectory = "/home/ianh/Repositories/stocks";

      ExecStart = "${pkgs.nix}/bin/nix develop --command python main.py --env ${env} --portfolio-master ${master}";

      StandardOutput = "journal";
      StandardError = "journal";

      TimeoutStartSec = "2hr";
      Nice = 5;
    };
  };

  mkTradingTimer = { description, onCalendar }: {
    inherit description;
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = onCalendar;
      RandomizedDelaySec = "25min";
      Persistent = true;
    };
  };
in
{
  systemd.services.stocks-trading-staging = mkTradingService {
    env = "staging";
    master = stagingMaster;
  };
  systemd.services.stocks-trading-live = mkTradingService {
    env = "live";
    master = liveMaster;
    extraAfter = [ "stocks-trading-staging.service" ];
  };

  systemd.timers.stocks-trading-staging = mkTradingTimer {
    description = "Daily Stock Trading Bot Timer - Staging (Weekdays, 09:50 ± 25min ET)";
    onCalendar = "Mon..Fri *-*-* 09:50:00";
  };

  systemd.timers.stocks-trading-live = mkTradingTimer {
    description = "Daily Stock Trading Bot Timer - Live (Weekdays, 10:30 ± 25min ET)";
    onCalendar = "Mon..Fri *-*-* 10:30:00";
  };
}
