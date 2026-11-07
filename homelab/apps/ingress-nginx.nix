# nginx behind HAProxy: changes to nixlab's ingress-nginx app (merged into it
# by the module system; see nixlab's docs/adding-charts.md).
{ lib, vars, ... }:

{
  # HAProxy (apps/haproxy.nix) is the external entrypoint at nginxIp and
  # forwards to nginx with the PROXY protocol, which carries the real client
  # IP; nginx itself is only a ClusterIP Service.
  applications.ingress-nginx.helm.releases.ingress-nginx.values.controller = {
    service = lib.mkForce {
      type = "ClusterIP";
      ports = { http = 80; https = 443; };
      targetPorts = { http = "http"; https = "https"; };
    };
    config."use-proxy-protocol" = "true";
    # Report HAProxy's IP in Ingress status (not nginx's ClusterIP), so
    # external-dns publishes an address LAN clients can reach.
    publishService.enabled = false;
    extraArgs."publish-status-address" = vars.ipPools.nginxExternal;
  };
}
