{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./touchbar.nix
  ];

  boot.blacklistedKernelModules = [
    "cdc_ncm"
    "cdc_mbim"
  ];

  hardware.bluetooth.enable = lib.mkForce true;
  services.blueman.enable = lib.mkForce false;

  # The Thunderbolt domain comes up at security level "user", which is the only
  # level the software connection manager supports (Apple machines use it
  # rather than Intel's ICM firmware). At that level a device attached after
  # boot must be authorized before any PCIe tunnel is created, and without
  # boltd running nothing ever authorizes it.
  services.hardware.bolt.enable = true;

  # Wi-Fi only. The BCE/audio half of this unit was removed: t2bce implements
  # real suspend/resume handlers and restores the BCE, VHCI and audio stack
  # itself, and the t2linux wiki explicitly says not to unload it -- force
  # unloading tears down live BridgeOS queues and can leave the internal
  # devices dead after resume. The old apple-bce unload service this was
  # copied from predates that driver; the wiki tells migrators to delete it.
  # https://wiki.t2linux.org/guides/postinstall/
  #
  # brcmfmac still needs the unload: on this machine's BCM4377b [14e4:4488]
  # brcmf_pcie_pm_enter_D3 times out with Wi-Fi bound and pci_pm_suspend()
  # returns -5, which aborts the whole suspend.
  systemd.services."suspend-fix-t2" = {
    enable = true;
    unitConfig = {
      Description = "Unload and restore Wi-Fi (brcmfmac) around suspend";
      Before = "sleep.target";
      StopWhenUnneeded = "yes";
    };
    serviceConfig = {
      User = "root";
      Type = "oneshot";
      RemainAfterExit = "yes";
      # Leading "-" makes each unload non-fatal: Type=oneshot aborts on the
      # first failing ExecStart, and ExecStop only runs if the unit started
      # successfully, so one failure here would skip the restore below and
      # leave Wi-Fi down until reboot.
      ExecStart = [
        "-/run/current-system/sw/bin/modprobe -r brcmfmac_wcc"
        "-/run/current-system/sw/bin/modprobe -r brcmfmac"
      ];
      ExecStop = [
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
