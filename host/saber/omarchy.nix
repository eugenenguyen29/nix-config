{
  pkgs,
  lib,
  ...
}:
{
  # * Check implementation here:  https://github.com/henrysipp/omarchy-nix
  omarchy = {
    full_name = "Moritz Zimmerman";
    email_address = "dinhnhattai.nguyen@hotmail.com";
    theme = "everforest";
    desktop_wallpaper = ./../../assets/wallpapers/1387138.png;
    hyprlock_wallpaper = ./../../assets/wallpapers/a_rainbow_colored_logo_with_an_apple.png;
    exclude_packages = with pkgs; [
      vscode
      spotify
      typora
      dropbox
    ];
    scale = 1;
    lid = {
      enable = true;
      exclusive_monitors = [ "BNQ BenQ GW2480" ];
    };
    quick_app_bindings = [
      "SUPER, slash, exec, $passwordManager --ozone-platform=wayland --enable-features=UseOzonePlatform"
      "CTRL SHIFT, space, exec, $passwordManager --quick-access --ozone-platform=wayland --enable-features=UseOzonePlatform"

      "SUPER, B, exec, $browser --ozone-platform=wayland --enable-features=UseOzonePlatform"

      "SUPER, D, exec, $terminal -e lazydocker"

      "SUPER, T, exec, $terminal"
      "SUPER, F, exec, $fileManager"
      "SUPER, N, exec, $terminal -e nvim"
      "SUPER, M, exec, $terminal -e btop"
      "SUPER, S, exec, $messenger"
    ];
    kill_app_binding = [
      "SUPER, Q, killactive,"
    ];
  };
}
