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
in {
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

  # Function to create a raw Kubernetes manifest
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

  # Expose helper functions and libraries
  inherit nixhelm kubelib overlayValues recursiveMerge recursiveMerge';
}
