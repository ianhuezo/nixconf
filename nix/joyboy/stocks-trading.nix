# Stock Trading Bot Services
# Two daily runs on weekdays, env-scoped:
#   - staging: 09:50 ET ± 25min (window 09:50–10:15)
#   - live:    10:30 ET ± 25min (window 10:30–10:55)
# Non-overlapping jitter windows (15-min gap) plus `After=` on the live unit
# so it queues behind staging even if staging runs long.
#
# End-of-day mr_sleeve runs (TQQQ down-streak MOC sleeve, main.py --mr-sleeve):
#   - staging: 15:33 ET ± 2min
#   - live:    15:36 ET ± 2min (queues behind staging)
# Timing is tight on purpose: the sleeve's clock gate refuses to run more than
# 30 min before the 16:00 close, and Alpaca wants MOC orders in by ~15:45, so
# there is no room for the morning runs' 25-min jitter. Persistent=false — a
# missed close run is worthless later (the sleeve would just no-op or abort).
#
# All use `nix develop` for the correct Python environment.
{ config, pkgs, ... }:

let
  liveMaster = "configs/portfolio_master.yaml";
  stagingMaster = "configs/portfolio_master_staging.yaml";
  sleeveConfig = "configs/mr_sleeve.yaml";

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

  mkSleeveService = { env, extraAfter ? [ ] }: {
    description = "Alpaca mr_sleeve - EOD TQQQ mean-reversion MOC run (${env})";

    wantedBy = [ ];
    after = [ "network-online.target" ] ++ extraAfter;
    requires = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "ianh";
      Group = "users";
      WorkingDirectory = "/home/ianh/Repositories/stocks";

      ExecStart = "${pkgs.nix}/bin/nix develop --command python main.py --env ${env} --mr-sleeve ${sleeveConfig}";

      StandardOutput = "journal";
      StandardError = "journal";

      # Must finish well before the 15:45 MOC cutoff; the run itself takes seconds.
      TimeoutStartSec = "8min";
      Nice = 5;
    };
  };

  mkSleeveTimer = { description, onCalendar }: {
    inherit description;
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = onCalendar;
      RandomizedDelaySec = "2min";
      Persistent = false;
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

  systemd.services.stocks-mr-sleeve-staging = mkSleeveService {
    env = "staging";
  };
  systemd.services.stocks-mr-sleeve-live = mkSleeveService {
    env = "live";
    extraAfter = [ "stocks-mr-sleeve-staging.service" ];
  };

  systemd.timers.stocks-mr-sleeve-staging = mkSleeveTimer {
    description = "EOD mr_sleeve Timer - Staging (Weekdays, 15:33 ± 2min ET)";
    onCalendar = "Mon..Fri *-*-* 15:33:00";
  };
  systemd.timers.stocks-mr-sleeve-live = mkSleeveTimer {
    description = "EOD mr_sleeve Timer - Live (Weekdays, 15:36 ± 2min ET)";
    onCalendar = "Mon..Fri *-*-* 15:36:00";
  };
}
