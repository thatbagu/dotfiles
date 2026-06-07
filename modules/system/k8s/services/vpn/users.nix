{ config, lib, ... }:
{
  # WireGuard user definitions
  wireguardUsers = {
    # === ADMIN USERS (Full Access) ===
    "egor-main" = {
      ip = "10.0.100.2";
      nextcloudUser = "admin";
      group = "admin";
      publicKeySecret = "egor_main_wg_public_key";
      allowedIPs = "0.0.0.0/0";
      description = "Egor's main machine - full admin access";
      enabled = true;
    };
    # # === FAMILY USERS (Broad Homelab Access) ===
    # "dad-phone" = {
    #   ip = "10.0.100.11";
    #   group = "family";
    #   publicKeySecret = "dad_phone_wg_public_key"; # SOPS secret name
    #   allowedIPs = "192.168.1.0/24";
    #   description = "Dad's phone - family access to homelab";
    #   enabled = true;
    # };
    # # === FRIEND USERS (Limited Access) ===
    "friend-test" = {
      ip = "10.0.100.20";
      group = "friends";
      publicKeySecret = "dsh_wg_public_key"; # SOPS secret name
      allowedIPs = "192.168.1.100/28";
      description = "friend access to limited services";
      enabled = true;
    };
    # # === GUEST USERS (Temporary Access) ===
    # "guest-1" = {
    #   ip = "10.0.100.30";
    #   group = "guests";
    #   publicKeySecret = "guest_1_wg_public_key"; # SOPS secret name
    #   allowedIPs = "192.168.1.110/30"; # Very limited range
    #   description = "Temporary guest access";
    #   enabled = false; # Enable when needed
    # };
  };
  # Group definitions with access policies
  wireguardGroups = {
    admin = {
      description = "Full administrative access to everything";
      allowedNetworks = [ "0.0.0.0/0" ];
      blockedNetworks = [ ];
      allowedPorts = [ ]; # No restrictions
      dns = "192.168.1.1"; # Can use any DNS
    };
    family = {
      description = "Family members with broad homelab access";
      allowedNetworks = [ "192.168.1.0/24" ];
      blockedNetworks = [
        "192.168.1.250/32" # Pi-hole admin
        "192.168.1.192/26" # MetalLB critical services
        "10.42.0.0/16" # K3s pod network
        "10.43.0.0/16" # K3s service network
      ];
      allowedPorts = [
        "22"
        "80"
        "443"
        "3000-3010"
        "8080-8090"
      ];
      dns = "192.168.1.1"; # Router DNS
    };
    friends = {
      description = "Friends with limited access to specific services";
      allowedNetworks = [ "192.168.1.100/28" ]; # 192.168.1.100-115
      blockedNetworks = [
        "192.168.1.250/32" # Pi-hole
        "192.168.1.192/26" # MetalLB
        "192.168.1.1/32" # Router admin
        "10.42.0.0/16" # K3s networks
        "10.43.0.0/16"
        "10.0.100.0/24" # Other WireGuard users
        "192.168.1.0/28" # Core infrastructure
      ];
      allowedPorts = [
        "80"
        "443"
        "3000-3005"
      ]; # Web services + limited apps
      dns = "192.168.1.1"; # Router DNS only
    };
    guests = {
      description = "Temporary guest access to very limited services";
      allowedNetworks = [ "192.168.1.110/30" ]; # 192.168.1.108-111 only
      blockedNetworks = [
        "192.168.1.0/27" # Everything except guest range
        "10.42.0.0/16" # K3s networks
        "10.43.0.0/16"
        "10.0.100.0/24" # Other WireGuard users
      ];
      allowedPorts = [
        "80"
        "443"
      ]; # Web only
      dns = "1.1.1.1"; # External DNS only
    };
  };
}
