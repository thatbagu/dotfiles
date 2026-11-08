# The CV site at https://mlship.dev (public, behind Cloudflare's proxy; DDNS
# keeps the record, see vars.nix). Its GitHub workflow (cv-runner.nix) deploys
# it by restarting the Deployment, which pulls :latest again.
{ nixlab, ... }:

let
  namespace = "cv";

  # Pod Security: no privileged / hostPath / hostNetwork pods in cv. Matters
  # because the CI runner (cv-runner.nix) may patch Deployments here.
  namespaceResource = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {
      name = namespace;
      labels = {
        "pod-security.kubernetes.io/enforce" = "baseline";
        "pod-security.kubernetes.io/enforce-version" = "latest";
        "pod-security.kubernetes.io/warn" = "restricted";
        "pod-security.kubernetes.io/audit" = "restricted";
      };
    };
  };
in
nixlab.webApp {
  name = "cv";
  inherit namespace;
  host = "mlship.dev";
  image = "docker.io/thatbagu/website:latest";
  port = 80;
  replicas = 2;
  resources = {
    requests = { cpu = "50m"; memory = "64Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };
  ingressAnnotations = {
    "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
    "nginx.ingress.kubernetes.io/proxy-body-size" = "10m";
    # Let Cloudflare cache pages for 1 hour (s-maxage) and browsers for 5 min.
    # Cloudflare respects s-maxage when the domain is set to Proxied (orange cloud).
    # Override the upstream CSP to add 'unsafe-eval' — needed for Vue/React runtime
    # template compilation on page refresh.
    "nginx.ingress.kubernetes.io/configuration-snippet" = ''
      set $cc "public, max-age=300, s-maxage=3600";
      if ($http_hx_request = "true") { set $cc "no-store"; }
      add_header Cache-Control $cc always;
      add_header Vary "HX-Request" always;
      proxy_hide_header Content-Security-Policy;
      add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self' https://mastodon.social; frame-ancestors 'none';" always;
    '';
  };
  extraResources = [ namespaceResource ];
}
