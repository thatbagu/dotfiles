{ config, pkgs, ... }: {
  imports = [ ../../../modules/system/configuration.nix ];

  config = {
    diskConfig = {
      device = "/dev/sda";
      espSize = "500M";
    };

    modules = {
      sys-packages.enable = true;
      k3s = {
        enable = true;
        master = true;
      };
      k8s.enable = true;
      sops.enable = true;
    };

    virtualisation.docker = {
      enable = true;
      logDriver = "json-file";
    };

    users.users.egor.extraGroups = [ "docker" ];

    # Pre-create the persistent runner home that the wrapper uses as runner root.
    # The NixOS state dir (cv/) is wiped by unconfigure; cv-runner/ survives.
    systemd.tmpfiles.rules = [
      "d /var/lib/github-runner/cv-runner 0750 egor users -"
    ];

    services.github-runners.cv = {
      enable = true;
      url = "https://github.com/thatbagu/cv";
      tokenFile = config.sops.secrets.github_token.path;
      extraLabels = [ "homelab" "meowth" ];
      replace = true;
      user = "egor";
      group = "users";
      extraPackages = with pkgs; [
        docker
        kubectl
        go
        (python3.withPackages (ps: with ps; [ pillow cairosvg pyyaml markdown ]))
      ];
      serviceOverrides.Environment = [
        "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1"
        "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib"
      ];
    };
  };
}
