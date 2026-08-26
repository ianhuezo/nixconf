# RGB lighting: theme-coloured while awake, dark while suspended.
#
# The fans, the board's own LEDs and the GPU sit behind separate controllers, so
# no single switch covers them. The BIOS "LED lighting in sleep state" option
# only reaches the board itself, so the rest has to happen in software. OpenRGB
# talks to all three.
#
# The iCUE LINK hub only exposes Direct - there is no firmware effect for
# OpenRGB to hand control back to - so once OpenRGB owns the hub, something has
# to hold a colour on it the whole time the machine is awake, or the fans just
# sit dark. That is what the ExecStartPost below is for.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.hardware.openrgb;
  palette = (import ../../themes/active.nix).palette;

  # The cool end of the base16 accents. Deliberately not base08/base09 (red and
  # orange), which fight the rest of the scheme.
  stops = [
    palette.base0B # cyan-blue
    palette.base0C # cyan
    palette.base0D # blue
    palette.base0E # purple
  ];

  # -- colour helpers ---------------------------------------------------------
  # Nix has no hex parser, so the ramp is computed here at build time and the
  # units below only ever see literal "RRGGBB" strings.

  hexDigits = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
    "A" = 10;
    "B" = 11;
    "C" = 12;
    "D" = 13;
    "E" = 14;
    "F" = 15;
  };

  hexToInt = s: lib.foldl' (acc: c: acc * 16 + hexDigits.${c}) 0 (lib.stringToCharacters s);

  intToHex =
    n:
    let
      d = "0123456789ABCDEF";
    in
    "${lib.substring (n / 16) 1 d}${lib.substring (lib.mod n 16) 1 d}";

  toRGB = c: let h = lib.removePrefix "#" c; in map (o: hexToInt (lib.substring o 2 h)) [ 0 2 4 ];
  toHex = rgb: lib.concatMapStrings intToHex rgb;

  # Linear ramp through the stops, `count` samples, endpoints inclusive.
  # Positions are scaled by 1000 so the whole thing stays integer arithmetic.
  gradient =
    count:
    let
      rgbs = map toRGB stops;
      segs = (builtins.length rgbs) - 1;
      sample =
        i:
        let
          pos = if count <= 1 then 0 else (i * segs * 1000) / (count - 1);
          seg = if pos >= segs * 1000 then segs - 1 else pos / 1000;
          t = pos - (seg * 1000);
          a = builtins.elemAt rgbs seg;
          b = builtins.elemAt rgbs (seg + 1);
          chan =
            k:
            let
              av = builtins.elemAt a k;
              bv = builtins.elemAt b k;
            in
            av + (((bv - av) * t) / 1000);
        in
        toHex (map chan [ 0 1 2 ]);
    in
    map sample (lib.range 0 (count - 1));

  # -- devices ----------------------------------------------------------------
  # Per-device rather than one global --mode, because the modes are not
  # interchangeable: the hub is Direct-only and the GPU has no Direct mode at
  # all, so a single --mode would fail on half the hardware. The DualSense is
  # deliberately absent - it is a controller, not case lighting.
  lit = [
    {
      device = "Corsair iCUE Link System Hub";
      mode = "direct";
      colors = gradient 24; # three fans, eight LEDs each
    }
    {
      device = "B650 AORUS ELITE AX";
      mode = "direct";
      # Only four LEDs, so a 24-step ramp would land entirely inside the first
      # stop. Hand it the stops themselves instead.
      colors = map (c: toHex (toRGB c)) stops;
    }
    {
      device = "ZOTAC GAMING GeForce RTX 4090 Trinity OC";
      mode = "static";
      colors = [ (toHex (toRGB palette.base0B)) ];
    }
  ];

  openrgb = "${pkgs.openrgb}/bin/openrgb";
  client = "--client 127.0.0.1:${toString cfg.server.port}";

  # USB product id of the iCUE LINK hub. The resume path has to wait for this to
  # be back on the bus before openrgb is allowed to probe.
  hubUsbId = "0c3f";

  # OpenRGB fills any remaining LEDs with the last colour given, so a single
  # entry blanks a whole device and the same builder covers both states.
  mkApply =
    name: entries:
    pkgs.writeShellScript name ''
      # Wait for every device we intend to drive, not just for the server to
      # answer - a device missing from the list here means openrgb probed too
      # early and its colours would be silently skipped.
      for _ in $(seq 60); do
        list=$(${openrgb} ${client} --list-devices 2>/dev/null) || list=""
        missing=0
      ${lib.concatMapStringsSep "\n" (d: ''
        printf '%s' "$list" | grep -qF ${lib.escapeShellArg d.device} || missing=1
      '') entries}
        [ "$missing" = 0 ] && break
        sleep 1
      done

      ${lib.concatMapStringsSep "\n" (d: ''
        ${openrgb} ${client} --device ${lib.escapeShellArg d.device} \
          --mode ${d.mode} --color ${lib.concatStringsSep "," d.colors} >/dev/null 2>&1 || true
      '') entries}
    '';

  applyTheme = mkApply "rgb-apply-theme" lit;
  blank = mkApply "rgb-blank" (map (d: d // { colors = [ "000000" ]; }) lit);

  # openrgb only probes at startup, so restarting it before the hub is back on
  # the bus leaves the fans dark until something restarts it again.
  resume = pkgs.writeShellScript "rgb-resume" ''
    for _ in $(seq 30); do
      grep -qs ${hubUsbId} /sys/bus/usb/devices/*/idProduct && break
      sleep 1
    done
    ${pkgs.systemd}/bin/systemctl --no-block restart openrgb.service
  '';
in
{
  services.hardware.openrgb = {
    enable = true;
    # Pulls in i2c-piix4. Note this board exposes no SMBus adapter through it,
    # so DDR5 DIMM lighting is not reachable and stays lit through a suspend.
    motherboard = "amd";
  };

  # Nothing drives a Direct-only device on its own, so without this the fans
  # come up dark at boot and stay that way.
  systemd.services.openrgb.serviceConfig.ExecStartPost = applyTheme.outPath;

  systemd.services.rgb-blank-while-asleep = {
    description = "Blank RGB lighting for the duration of a suspend";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    after = [ "openrgb.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = blank.outPath;
      # ExecStop runs on resume. The controllers have re-enumerated by then, so
      # the server has to re-detect them; its ExecStartPost repaints the theme.
      ExecStop = resume.outPath;
      TimeoutStartSec = "90s";
      TimeoutStopSec = "60s";
    };
  };
}
