# Extras for the homelab nodes, on top of nixlab's (extraNixosModules in
# flake.nix): the shell setup, this flake's overlays, and the cv GitHub runner
# on meowth. Takes this flake's inputs: the `inputs` nixlab passes to modules
# are its own.
inputs:
{ config, lib, pkgs, username, hostname, ... }:

{
  imports = [
    inputs.stylix.nixosModules.stylix
    inputs.home-manager.nixosModules.home-manager
  ];

  config = lib.mkMerge [
    {
      # Shell setup: fish, nixvim, zellij, k9s, …
      programs.fish.enable = true;
      users.users.${username}.shell = pkgs.fish;
      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;
        backupFileExtension = "-backup";
        extraSpecialArgs = {
          inherit inputs;
          claude-code = inputs.claude-code.packages.x86_64-linux.default;
        };
        users.${username}.imports = [
          (./. + "/${hostname}/user.nix")
          inputs.nixvim.homeModules.nixvim
        ];
      };
    }

    {
      # This flake's package overlays too (e.g. the newer github-runner);
      # nixlab only applies its own.
      nixpkgs.overlays = builtins.attrValues (import ../../overlays/default.nix);

      # The locales the nodes were installed with: changing them restarts
      # nearly every service. Drop this line at a planned reboot.
      i18n.supportedLocales = lib.mkForce [ "en_US.UTF-8/UTF-8" "ja_JP.UTF-8/UTF-8" ];
    }

    (lib.mkIf (hostname == "meowth") {
      # The runner's registration token.
      sops.secrets.github_token.owner = username;

      # CI runner for github.com/thatbagu/cv, hardened:
      # - dedicated cv-runner user (no sudo, no docker group)
      # - image builds use cv-runner's own rootless Docker, so a job can't become
      #   root on the host (the rootful daemon is gone)
      # - kubectl sees a least-privilege kubeconfig (cv-deployer ServiceAccount:
      #   rollout restart/status of cv and cv-tui only), bind-mounted over the
      #   admin path the workflows use, so they need no changes
      users.groups.cv-runner.gid = 979;
      users.users.cv-runner = {
        isSystemUser = true;
        uid = 979;
        group = "cv-runner";
        home = "/var/lib/cv-runner";
        createHome = true;
        linger = true; # keep the rootless Docker user service running
        subUidRanges = [{ startUid = 300000; count = 65536; }];
        subGidRanges = [{ startGid = 300000; count = 65536; }];
      };
  
      virtualisation.docker.rootless.enable = true;
      # Only cv-runner gets a rootless daemon, not every user session.
      systemd.user.services.docker.unitConfig.ConditionUser = lib.mkForce "cv-runner";
  
      # Pre-create the persistent runner home that the wrapper uses as runner root.
      # The NixOS state dir (cv/) is wiped by unconfigure; cv-runner/ survives.
      systemd.tmpfiles.rules = [
        "d /var/lib/github-runner/cv-runner 0750 cv-runner cv-runner -"
        "Z /var/lib/github-runner/cv-runner - cv-runner cv-runner -"
      ];
  
      # Build the runner's kubeconfig from the cv-deployer token (created by
      # Argo CD in the cv namespace).
      systemd.services.cv-runner-kubeconfig = {
        description = "Least-privilege kubeconfig for the cv GitHub runner";
        after = [ "k3s.service" ];
        wants = [ "k3s.service" ];
        before = [ "github-runner-cv.service" ];
        requiredBy = [ "github-runner-cv.service" ];
        path = [ pkgs.kubectl pkgs.coreutils ];
        environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = 30;
        };
        script = ''
          get() { kubectl -n cv get secret cv-deployer-token -o "jsonpath={.data.$1}"; }
          until [ -n "$(get token 2>/dev/null)" ]; do
            echo "Waiting for cv/cv-deployer-token..."
            sleep 10
          done
          token=$(get token | base64 -d)
          ca=$(get 'ca\.crt')
          f=/var/lib/github-runner/cv-kubeconfig
          umask 077
          cat > "$f.tmp" <<EOF
          apiVersion: v1
          kind: Config
          clusters:
          - name: k3s
            cluster:
              server: https://127.0.0.1:6443
              certificate-authority-data: $ca
          users:
          - name: cv-deployer
            user:
              token: $token
          contexts:
          - name: cv
            context:
              cluster: k3s
              user: cv-deployer
              namespace: cv
          current-context: cv
          EOF
          chown cv-runner:cv-runner "$f.tmp"
          mv "$f.tmp" "$f"
        '';
      };
  
      services.github-runners.cv = {
        enable = true;
        url = "https://github.com/thatbagu/cv";
        tokenFile = config.sops.secrets.github_token.path;
        extraLabels = [ "homelab" "meowth" ];
        replace = true;
        user = "cv-runner";
        group = "cv-runner";
        extraPackages = with pkgs; [
          docker
          kubectl
          go
          (python3.withPackages (ps: with ps; [ pillow cairosvg pyyaml markdown ]))
        ];
        serviceOverrides = {
          Environment = [
            "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1"
            "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib"
            "DOCKER_HOST=unix:///run/user/979/docker.sock"
          ];
          ReadWritePaths = [ "/var/lib/github-runner/cv-runner" ];
          # The rootless Docker socket lives in /run/user/979 (hidden by "yes").
          ProtectHome = "read-only";
          BindReadOnlyPaths = [ "/var/lib/github-runner/cv-kubeconfig:/etc/rancher/k3s/k3s.yaml" ];
        };
      };
      systemd.services.github-runner-cv = {
        after = [ "user@979.service" ];
        requires = [ "user@979.service" ];
      };
    })
  ];
}
