# Touch Bar. Primary layer: Ghostty, F2-F10, battery. The media layer (Fn) is the
# stock one: its list is deliberately omitted, since tiny-dfr merges
# /etc/tiny-dfr/config.toml over its own default per key, so an unset key keeps the
# shipped list rather than blanking it.
{
  pkgs,
  ...
}:
{
  hardware.apple.touchBar = {
    enable = true;
    settings.PrimaryLayerKeys = [
      # Buttons can only emit keys; SUPER+T is omarchy's "$terminal" bind (ghostty).
      { Icon = "ghostty"; Action = [ "LeftMeta" "T" ]; }
      # SUPER+/ is the "$passwordManager" bind.
      { Icon = "1password"; Action = [ "LeftMeta" "Slash" ]; }
    ]
    ++ map (n: { Text = "F${toString n}"; Action = "F${toString n}"; }) (pkgs.lib.range 3 10)
    ++ [
      { Battery = "both"; Action = "Battery"; Stretch = 2; }
    ];
  };

  # Icons resolve from /etc/tiny-dfr first. PNGs are drawn unscaled, best at 48x48,
  # which neither app ships, so downscale a larger one.
  environment.etc = builtins.mapAttrs (name: src: {
    source = pkgs.runCommand (baseNameOf name) { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick ${src} -resize 48x48 $out
    '';
  }) {
    "tiny-dfr/ghostty.png" = "${pkgs.ghostty}/share/icons/hicolor/128x128/apps/com.mitchellh.ghostty.png";
    "tiny-dfr/1password.png" = "${pkgs._1password-gui}/share/icons/hicolor/64x64/apps/1password.png";
  };

  # An app launcher on the second layer was tried and reverted: tiny-dfr supports
  # exactly two layers ([FunctionLayer; 2] in its source), so a launcher costs the
  # media keys -- and keyboard backlight (IllumUp/IllumDown) and mic mute have no
  # other binding on this machine. Its buttons can also only emit key codes, never
  # run commands, so the launcher needed Hyprland to turn each chord into a command.
  # Kept here because it is otherwise unrecoverable; to restore, move these into
  # hardware.apple.touchBar.settings and append the bindings to
  # omarchy.quick_app_bindings (listOf merges by concatenation).
  #
  #   MediaLayerKeys = [
  #     { Text = "Term";  Action = [ "LeftMeta" "LeftAlt" "F1" ]; }   # $terminal
  #     { Text = "Files"; Action = [ "LeftMeta" "LeftAlt" "F2" ]; }   # $fileManager
  #     { Text = "Web";   Action = [ "LeftMeta" "LeftAlt" "F3" ]; }   # $browser
  #     { Text = "Edit";  Action = [ "LeftMeta" "LeftAlt" "F4" ]; }   # $terminal -e nvim
  #     { Text = "Btop";  Action = [ "LeftMeta" "LeftAlt" "F5" ]; }   # $terminal -e btop
  #     { Text = "Dock";  Action = [ "LeftMeta" "LeftAlt" "F6" ]; }   # $terminal -e lazydocker
  #     { Text = "Chat";  Action = [ "LeftMeta" "LeftAlt" "F7" ]; }   # $messenger
  #     { Text = "1Pw";   Action = [ "LeftMeta" "LeftAlt" "F8" ]; }   # $passwordManager
  #     { Text = "Menu";  Action = [ "LeftMeta" "LeftAlt" "F9" ]; }   # walker
  #     { Icon = "volume_down"; Action = "VolumeDown"; }
  #     { Icon = "volume_up";   Action = "VolumeUp"; }
  #     { Icon = "volume_off";  Action = "Mute"; }
  #   ];
  #
  # Matching binds: "SUPER ALT, F<n>, exec, <command>"  (SUPER+ALT+Fn is unused here,
  # and avoids CTRL+ALT+Fn, which logind claims for VT switching).
}
