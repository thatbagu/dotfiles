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

    services.github-runners.cv = {
      enable = true;
      url = "https://github.com/thatbagu/cv";
      tokenFile = config.sops.secrets.github_token.path;
      extraLabels = [ "homelab" "meowth" ];
      user = "egor";
      group = "users";
      extraPackages = with pkgs; [
        docker
        kubectl
        (python3.withPackages (ps: with ps; [ pillow cairosvg pyyaml markdown ]))
      ];
      serviceOverrides.Environment = [
        "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1"
        "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib"
      ];
    };
  };
}
