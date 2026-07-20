final: prev: {
  fish = prev.fish.overrideAttrs (old: {
    # fish 4.8+ removed share/fish/tools/create_manpage_completions.py
    # but nixpkgs packages still invoke it to generate completions from man pages.
    # Add a stub so those derivations build (they produce no completions, which is fine).
    postInstall = (old.postInstall or "") + ''
      mkdir -p $out/share/fish/tools
      printf '#!/usr/bin/env python3\nimport sys\nsys.exit(0)\n' \
        > $out/share/fish/tools/create_manpage_completions.py
      chmod +x $out/share/fish/tools/create_manpage_completions.py
    '';
  });
}
