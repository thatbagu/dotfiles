{ pkgs, inputs }:

let
  nixhelm = inputs.nixhelm.charts { inherit pkgs; };
  kubelib = inputs.nix-kube-generators.lib { inherit pkgs; };

  # Helper function to merge deep attribute sets
  recursiveMerge = attrList:
    let
      f = attrPath:
        let
          getValues = attr: attrPath:
            if attrPath == [ ] then
              attr
            else
              getValues (builtins.getAttr (builtins.head attrPath) attr)
              (builtins.tail attrPath);

          values = builtins.filter (x: x != null) (map (attr:
            if builtins.hasAttr (builtins.head attrPath) attr then
              getValues attr attrPath
            else
              null) attrList);

          recurse = r:
            if builtins.isAttrs r then
              recursiveMerge' (map (key: recurse (builtins.getAttr key r))
                (builtins.attrNames r))
            else
              r;

        in if values == [ ] then
          { }
        else if builtins.length values == 1 then
          builtins.head values
        else if builtins.isAttrs (builtins.head values) then
          recurse values
        else
          builtins.head values;

    in f [ ];

  # Advanced version of recursiveMerge that handles attribute sets with overlapping keys
  recursiveMerge' = attrList:
    builtins.foldl' (acc: attr:
      builtins.mapAttrs (name: value:
        if builtins.hasAttr name acc && builtins.isAttrs value
        && builtins.isAttrs acc.${name} then
          recursiveMerge' [ acc.${name} value ]
        else
          value) attr // acc) { } attrList;

  # Function to overlay values on top of defaults
  overlayValues = defaults: overlay: recursiveMerge' [ defaults overlay ];

  # Function to create a consistent label set
  mkLabels = { name, component, part ? null }:
    {
      "app.kubernetes.io/name" = name;
      "app.kubernetes.io/component" = component;
    }
    // (if part != null then { "app.kubernetes.io/part-of" = part; } else { });

  # Function to generate standard annotations
  mkAnnotations = { managed-by ? "nix-k8s", owner ? null, annotations ? { } }:
    {
      "app.kubernetes.io/managed-by" = managed-by;
    } // (if owner != null then {
      "app.kubernetes.io/created-by" = owner;
    } else
      { }) // annotations;
in {
  # Common chart creation functions

  # Function to create a Helm chart with defaults
  mkChart = { name, namespace, chart, values ? { }, defaultValues ? { } }: {
    path = kubelib.buildHelmChart {
      inherit name chart namespace;
      values = if defaultValues != { } then
        overlayValues defaultValues values
      else
        values;
    };
    inherit namespace;
    isSecret = false;
  };

  # Function to create a raw Kubernetes manifest with standard metadata
  mkRawManifest = { name, namespace, resources }: {
    path = kubelib.toYAMLStreamFile resources;
    inherit namespace;
    isSecret = false;
  };

  # Function to create a secret reference
  mkSecretRef =
    { name, namespace, secretName, secretKey ? "password", sopsSecretName }: {
      inherit namespace name secretName secretKey sopsSecretName;
      isSecret = true;
    };

  # Function to generate consistent resources
  mkResources = { cpu ? null, memory ? null, storage ? null }:
    builtins.removeAttrs { inherit cpu memory storage; } (builtins.filter
      (k: builtins.getAttr k { inherit cpu memory storage; } == null) [
        "cpu"
        "memory"
        "storage"
      ]);

  # Function to generate consistent resource requirements
  mkResourceRequirements = { requests ? { }, limits ? { } }:
    builtins.removeAttrs {
      requests = mkResources requests;
      limits = mkResources limits;
    } (builtins.filter
      (k: builtins.getAttr k { inherit requests limits; } == { }) [
        "requests"
        "limits"
      ]);

  # Helper to generate standard metadata
  mkMetadata = { name, namespace, labels ? { }, annotations ? { } }: {
    inherit name namespace;
    labels = labels;
    annotations = annotations;
  };

  # Expose helper functions and libraries
  inherit nixhelm kubelib overlayValues mkLabels mkAnnotations recursiveMerge
    recursiveMerge';
}
