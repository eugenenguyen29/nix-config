# SPDX-License-Identifier: MIT
# (C) 2022 The Asahi Linux Contributors
# https://github.com/lemmyg/t2-apple-audio-dsp/
# Version: master-v1.0.1

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.t2AppleAudioDSP;
in
{
  options.t2AppleAudioDSP = {
    enable = lib.mkEnableOption "T2 Mac speaker/mic DSP";
    model = lib.mkOption {
      default = null;
      description = "The model directory for your T2 Mac, e.g. 15_4 for a MacBookPro15,4.";
      type = lib.types.enum [
        "8_1"
        "8_2"
        "9_1"
        "15_1"
        "15_2"
        "15_4"
        "16_1"
        "16_2"
        "16_3"
        "16_4"
      ];
    };
  };

  config = lib.mkIf cfg.enable (
    let

      src = pkgs.fetchFromGitHub {
        owner = "lemmyg";
        repo = "t2-apple-audio-dsp";
        rev = "7ad15c790175a52a9f5fed2c2c1e4c8cafaf1adc"; # master, 2026-09-05
        hash = "sha256-UtMfPo8eCcJ0EBmVcLUiTqhC6tykVdZSJWbrOsSBBLE=";
      };

      # Upstream installs the FIRs and DSP graphs to /usr/share/t2linux-audio/<model>
      # and hardcodes that prefix inside the graphs; keep the layout but repoint it
      # at the store copy.
      prefix = "/usr/share/t2linux-audio";

      audioData = pkgs.runCommand "t2linux-audio-${cfg.model}" { } ''
        install -Dm444 -t $out/${cfg.model} ${src}/configs/${cfg.model}/*
        chmod +w $out/${cfg.model}/*.json
        sed -i "s|${prefix}|$out|g" $out/${cfg.model}/*.json
        chmod -w $out/${cfg.model}/*.json
      '';

      wireplumberConfig = pkgs.runCommand "t2-dsp-wireplumber-config" { } ''
        conf=$out/share/wireplumber/wireplumber.conf.d/51-t2-dsp.conf
        install -Dm644 ${src}/configs/wireplumber.conf $conf
        sed -i "s|${prefix}|${audioData}|g" $conf
        # The UCM SplitPCM parent (alsa_output.hw_t2-*) stays visible as a sink that
        # bypasses the DSP; hide it from clients the same way the raw speakers are.
        cat > $out/share/wireplumber/wireplumber.conf.d/52-t2-dsp-hide-split.conf <<'EOF'
        node.software-dsp.rules = [
          {
            matches = [ { node.name = "~alsa_output.hw_t2-.*" } ]
            actions = { create-filter = { hide-parent = true } }
          }
        ]
        EOF
      '';

      # The DSP rules match on the ALSA card id, which the udev rule shortens from
      # the (over-long) DMI product name to t2-<model>.
      udevRules = pkgs.runCommand "t2-audio-rename-rules" { } ''
        rules=$out/lib/udev/rules.d/99-t2-audio-rename.rules
        install -Dm644 ${src}/configs/99-t2-audio-rename.rules $rules
        sed -i "s|@MODEL_DIR@|${cfg.model}|g" $rules
      '';

    in
    {

      services.udev.packages = [ udevRules ];

      services.pipewire.wireplumber = {
        configPackages = [ wireplumberConfig ];
        extraLadspaPackages = with pkgs; [ ladspaPlugins ];
        extraLv2Packages = with pkgs; [
          bankstown-lv2
          swh_lv2
          lsp-plugins
          # triforce-lv2 override shouldn't be needed for 26.05 and later
          (triforce-lv2.overrideAttrs {
            meta.platforms = lib.platforms.linux;
          })
        ];
      };
    }
  );
}
