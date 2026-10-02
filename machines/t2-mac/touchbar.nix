# Touch Bar: stock layout. F1-F12 on the primary layer, the standard media keys
# (brightness, mic mute, search, keyboard backlight, playback, volume) on the
# second, reached with Fn.
#
# Both layer lists are deliberately omitted. tiny-dfr merges /etc/tiny-dfr/config.toml
# over its own default per key, so leaving a key unset keeps the shipped list rather
# than blanking it. Every global it accepts already defaults to what we want, so
# enabling is the whole configuration.
{
  ...
}:
{
  hardware.apple.touchBar.enable = true;

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
