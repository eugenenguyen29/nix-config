{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.virtualisation.docker;

  # Settings understood by both the rootful and the rootless daemon.
  commonDaemonSettings = {
    # Docker Engine 29 makes the containerd image store the default. Opting in
    # now buys multi-platform images and a store shared with containerd, and
    # avoids migrating a populated overlay2 graph driver later on.
    features.containerd-snapshotter = true;

    # Containers can no longer gain privileges through setuid binaries.
    no-new-privileges = true;

    # The stock json-file driver grows without bound; `local` rotates.
    log-driver = "local";
    log-opts = {
      max-size = "10m";
      max-file = "3";
    };
  };
in
{
  options.services.virtualisation.docker = {
    enable = lib.mkEnableOption "Docker support";

    rootless = lib.mkEnableOption ''
      the rootless daemon instead of the system-wide one. Containers then run as
      the invoking user and DOCKER_HOST points at $XDG_RUNTIME_DIR/docker.sock,
      but they cannot bind ports below 1024
    '';

    autoPrune.dates = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      example = "daily";
      description = "systemd calendar expression for the `docker system prune` timer.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      # The rootful and the rootless daemon are separate units that would both
      # claim /var/lib/docker-ish state; run exactly one of them.
      enable = !cfg.rootless;
      enableOnBoot = true;

      # pkgs.docker still aliases 28.x, which nixpkgs marks unmaintained since
      # November 2025. Drop this pin once the alias moves to 29 or newer.
      package = pkgs.docker_29;

      daemon.settings = commonDaemonSettings // {
        # Keep containers running across `systemctl restart docker` and
        # nixos-rebuild switch. Incompatible with docker swarm.
        live-restore = true;

        # Drop the userland docker-proxy process per published port and let the
        # kernel do the NAT instead.
        userland-proxy = false;

        # Pin bridge subnets out of the way of the 10.10.20.0/24 VLAN and of the
        # 192.168.0.0/16 range docker would otherwise hand out.
        default-address-pools = [
          {
            base = "172.20.0.0/14";
            size = 24;
          }
        ];
      };

      rootless = lib.mkIf cfg.rootless {
        enable = true;
        setSocketVariable = true;
        package = pkgs.docker_29;
        # live-restore and userland-proxy are rootful-only knobs; RootlessKit
        # owns port forwarding in this mode.
        daemon.settings = commonDaemonSettings;
      };

      autoPrune = {
        enable = true;
        inherit (cfg.autoPrune) dates;
        # Filters are key=value pairs -- `until-24h` silently matched nothing.
        flags = [
          "--filter=until=24h"
          "--filter=label!=important"
        ];
      };
    };

    # pkgs.docker already ships the compose and buildx CLI plugins, so
    # `docker compose` and `docker buildx` work without extra packages.
    environment.systemPackages = with pkgs; [
      dive
      lazydocker
    ];
  };
}
