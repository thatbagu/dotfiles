{ pkgs, inputs, ... }:
let
  nixhelm = inputs.nixhelm.charts { inherit pkgs; };
  kubelib = inputs.nix-kube-generators.lib { inherit pkgs; };
in {

  external-dns = kubelib.buildHelmChart {
    name = "external-dns";
    chart = nixhelm.external-dns.external-dns;
    namespace = "networking";
    values = { provider = "cloudflare"; };
  };

  cert-manager = kubelib.buildHelmChart {
    name = "cert-manager";
    chart = nixhelm.jetstack.cert-manager;
    namespace = "cert-manager";
    values = { installCRDs = true; };
  };
}

