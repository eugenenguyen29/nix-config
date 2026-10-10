{
  lib,
  ...
}:
{
  powerManagement.powertop.enable = lib.mkDefault true; # enable powertop auto tuning on startup.

  # Long-pressing your power button (5 seconds or longer)
  # to do a hard reset is handled by your machine’s BIOS/EFI and thus still possible.
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleLidSwitch = "lock";
    HandleLidSwitchExternalPower = "lock";
    # Docked = an external monitor is connected; omarchy.lid turns the panel off
    # instead, so locking here would only put hyprlock on the monitors in use.
    HandleLidSwitchDocked = "ignore";
  };
}
