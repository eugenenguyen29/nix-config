{
  pkgs,
  ...
}:
{
  powerManagement.powertop.enable = true; # enable powertop auto tuning on startup.

  # Long-pressing your power button (5 seconds or longer)
  # to do a hard reset is handled by your machine’s BIOS/EFI and thus still possible.
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleLidSwitch = "lock";
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "lock";
  };

  services.tlp = {
    enable = false;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 75;

      #Optional helps save long term battery health
      START_CHARGE_THRESH_BAT0 = 60; # 40 and below it starts to charge
      STOP_CHARGE_THRESH_BAT0 = 98; # 80 and above it stops charging

    };
  };
}
