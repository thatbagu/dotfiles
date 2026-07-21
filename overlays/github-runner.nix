final: prev: {
  github-runner = prev.lib.makeOverridable (
    { nodeRuntimes ? [ ] }:
    prev.stdenv.mkDerivation rec {
      pname = "github-runner";
      version = "2.335.1";

      src = prev.fetchurl {
        url = "https://github.com/actions/runner/releases/download/v${version}/actions-runner-linux-x64-${version}.tar.gz";
        hash = "sha256-TvLyUoXwrkR38f4eNG23bS8+vwOCTi3dGXOigZv2yM8=";
      };

      sourceRoot = ".";

      nativeBuildInputs = [ prev.autoPatchelfHook ];
      buildInputs = [ prev.stdenv.cc.cc.lib prev.zlib ];
      # musl libc is only for alpine node externals (unused on glibc);
      # lttng-ust is optional dotnet tracing support
      autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" "liblttng-ust.so.0" ];

      dontBuild = true;
      dontStrip = true; # strip corrupts R2R native code sections in .dll files

      installPhase = ''
        mkdir -p $out/bin $out/externals
        cp -r bin/. $out/bin/
        cp config.sh env.sh run.sh safe_sleep.sh $out/bin/
        cp -r externals/. $out/externals/

        # Runner computes root as parent of bin/ and needs to write various files there,
        # but the nix store is read-only. Symlink everything to writable locations.
        ln -s /var/log/github-runner/cv $out/_diag
        ln -s /var/lib/github-runner/cv/.runner $out/.runner
        ln -s /var/lib/github-runner/cv/.credentials $out/.credentials
        ln -s /var/lib/github-runner/cv/.credentials_rsaparams $out/.credentials_rsaparams
        # .path is read by the runner to set PATH for step execution.
        # The wrapper below writes the service PATH there before starting the real binary.
        ln -s /run/github-runner/cv/.path $out/.path

        # Wrap the runner binary so it captures the service PATH into .path on startup.
        # Without this, steps get a default OS PATH that lacks nix-provided tools.
        mv $out/bin/Runner.Listener $out/bin/Runner.Listener.real
        cat > $out/bin/Runner.Listener << 'WRAPPER'
        #!/bin/sh
        printf '%s' "$PATH" > /run/github-runner/cv/.path
        exec "$(dirname "$0")/Runner.Listener.real" "$@"
        WRAPPER
        chmod +x $out/bin/Runner.Listener
      '';

      meta.mainProgram = "Runner.Listener";
    }
  ) { };
}
