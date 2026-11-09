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
  # Cloudflare caches pages for an hour (s-maxage) and browsers for 5
  # minutes, except htmx requests (HX-Request: true), which are never cached.
  # The CSP replaces the site's own, adding 'unsafe-eval' (Vue/React runtime
  # template compilation on page refresh).
  routeRules =
    let
      headers = cacheControl: [{
        type = "ResponseHeaderModifier";
        responseHeaderModifier.set = [
          { name = "Cache-Control"; value = cacheControl; }
          { name = "Vary"; value = "HX-Request"; }
          { name = "Content-Security-Policy"; value = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self' https://mastodon.social; frame-ancestors 'none';"; }
        ];
      }];
    in
    [
      {
        matches = [{ headers = [{ name = "HX-Request"; value = "true"; }]; }];
        filters = headers "no-store";
      }
      { filters = headers "public, max-age=300, s-maxage=3600"; }
    ];
  extraResources = [ namespaceResource ];
}
