{ pkgs, inputs, ... }:
let
  nixhelm = inputs.nixhelm.charts { inherit pkgs; };
  kubelib = inputs.nix-kube-generators.lib { inherit pkgs; };

  mkChart = { name, namespace, chart, values ? { } }: {
    path = kubelib.buildHelmChart { inherit name chart namespace values; };
    inherit namespace;
  };
in {
  # external-dns = mkChart {
  #   name = "external-dns";
  #   chart = nixhelm.external-dns.external-dns;
  #   namespace = "networking";
  #   values = { provider = "cloudflare"; };
  # };

  cert-manager = mkChart {
    name = "cert-manager";
    chart = nixhelm.jetstack.cert-manager;
    namespace = "cert-manager";
    values = { installCRDs = true; };
  };
}
