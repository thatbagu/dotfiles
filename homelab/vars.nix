# The homelab's nixlab settings (see nixlab's docs/configuration.md). The nodes
# and the Kubernetes render are built from this with nixlab.lib.mkNixlab in
# flake.nix; the homelab's own apps (cv, cv-tui) are in apps/, the nodes'
# hardware and extras in hosts/.
{
  username = "egor";
  timezone = "Asia/Almaty";
  clusterSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQRS6OzC9Ip5lUhIyFvG03KgyupxJE55gmY3Dis0u18 cluster";

  nodes = {
    meowth = { hostname = "meowth"; master = true; disk = "/dev/sda"; espSize = "500M"; tags = [ "homelab" "master" "meowth" ]; };
    psyduck = { hostname = "psyduck"; master = false; disk = "/dev/sda"; espSize = "500M"; tags = [ "homelab" "worker" "psyduck" ]; };
    bulbasaur = { hostname = "bulbasaur"; master = false; disk = "/dev/sda"; espSize = "500M"; tags = [ "homelab" "worker" "bulbasaur" ]; };
  };

  domain = "egor.house";
  cloudflare = {
    enable = true;
    # The CV site, behind Cloudflare's proxy.
    ddns.records = [ { name = "mlship.dev"; proxied = true; } ];
  };

  nextcloud.enable = true;
  signalProxy.enable = true;
  telegramProxy.enable = true;
  sso.enable = false;

  # HAProxy in front of nginx: shares :443 with the Telegram proxy, serves
  # mlship.dev, and forwards SSH on :22 to the CV's terminal UI.
  edge = {
    domains = [ "mlship.dev" ];
    tcp."22" = "cv-tui.cv.svc.cluster.local:2222";
  };

  k3s = {
    # meowth's SSD stalls for seconds on cache flushes; longer leader
    # election keeps them from restarting the control plane.
    leaderElection = { leaseDuration = "60s"; renewDeadline = "40s"; };
    # Workers rejoin after a reinstall (their node password is the k3s token).
    stableNodePasswords = true;
  };

  # Argo CD syncs the rendered manifests from this repo's k8s-rendered branch.
  gitRepository = "https://github.com/thatbagu/dotfiles.git";
  renderedBranch = "k8s-rendered";

  # Off for now: turn on once the migration has settled (and with backups).
  autoUpgrade.enable = false;

  backups.enable = false;
  monitoring.enable = false;

  metallbPool = "192.168.1.192/26";
  piholeIp = "192.168.1.250";
  wireguardIp = "192.168.1.194";
  nginxIp = "192.168.1.193";
  upstreamDns = "192.168.1.1";
  lan.subnet = "192.168.1.0/24";

  vpn = {
    subnet = "10.0.100.0/24";
    # Kept as before: family (Anya) reaches only home services through the
    # VPN proxy; friends and guests get a few LAN hosts.
    groups = {
      family.allowedNetworks = [ ];
      friends.allowedNetworks = [ "192.168.1.100/28" ];
      guests.allowedNetworks = [ "192.168.1.110/30" ];
    };
  };

  wireguardUsers = {
    "egor-main" = {
      ip = "10.0.100.2";
      nextcloudUser = "egor";
      group = "admin";
      publicKeySecret = "egor_main_wg_public_key";
      allowedIPs = "0.0.0.0/0";
      description = "Egor's main machine - full admin access";
      enabled = true;
    };
    "anya-phone" = {
      ip = "10.0.100.11";
      nextcloudUser = "anya";
      group = "family";
      publicKeySecret = "anya_phone_wg_public_key";
      allowedIPs = "10.0.100.0/24, 192.168.1.250/32";
      description = "Anya's phone - home services, Nextcloud auto-login";
      enabled = true;
    };
    "anya-laptop" = {
      ip = "10.0.100.12";
      nextcloudUser = "anya";
      group = "family";
      publicKeySecret = "anya_laptop_wg_public_key";
      allowedIPs = "10.0.100.0/24, 192.168.1.250/32";
      description = "Anya's laptop - home services, Nextcloud auto-login";
      enabled = true;
    };
    "friend-test" = {
      ip = "10.0.100.20";
      group = "friends";
      publicKeySecret = "dsh_wg_public_key";
      allowedIPs = "192.168.1.100/28";
      description = "friend access to limited services";
      enabled = true;
    };
  };
}
