{
  pkgs,
  lib,
  ...
}:
{
  boot.blacklistedKernelModules = [
    "cdc_ncm"
    "cdc_mbim"
  ];

  hardware.bluetooth.enable = lib.mkForce true;
  services.blueman.enable = lib.mkForce false;

  systemd.services."suspend-fix-t2" = {
    enable = true;
    unitConfig = {
      Description = "Disabled end Re-Enable Apple BCE Module (and Wi-Fi)";
      Before = "sleep.target";
      StopWhenUnneeded = "yes";
    };
    serviceConfig = {
      User = "root";
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = [
        "/run/current-system/sw/bin/modprobe -r brcmfmac_wcc"
        "/run/current-system/sw/bin/modprobe -r brcmfmac"
        "/run/current-system/sw/bin/rmmod -f apple-bce"
      ];
      ExecStop = [
        "/run/current-system/sw/bin/modprobe apple-bce"
        "/run/current-system/sw/bin/modprobe brcmfmac"
        "/run/current-system/sw/bin/modprobe brcmfmac_wcc"
      ];
    };
    wantedBy = [ "sleep.target" ];
  };

  hardware.firmware = [
    (pkgs.stdenvNoCC.mkDerivation (final: {
      name = "brcm-firmware";
      src = ./firmware/brcm;
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/lib/firmware/brcm
        cp ${final.src}/* "$out/lib/firmware/brcm"
      '';
    }))
  ];

}
