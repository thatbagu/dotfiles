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

        # The runner binary (Runner.Listener.real) computes its root as
        # dirname(dirname(Assembly.Location)). Assembly.Location resolves
        # through symlinks to wherever the DLLs physically live. Placing
        # the DLLs in the read-only nix store and symlinking config files
        # from $out/.runner → /var/lib/github-runner/cv/.runner causes a
        # catch-22: after unconfigure wipes the state dir those symlinks
        # dangle, File.Exists() returns True (lstat sees symlink), but
        # ReadAllText fails → SIGABRT. Stubbing files fixes the crash but
        # makes IsConfigured() return True → configure blocked.
        #
        # Fix: a wrapper copies all DLLs + the apphost to a writable home
        # (/var/lib/github-runner/cv-runner/) on every start. When that
        # copy is the binary that executes, Assembly.Location points to the
        # writable home — so the runner's root is that writable directory,
        # not the nix store. After unconfigure wipes cv/ (not cv-runner/),
        # the runner root has no dangling symlinks; absent config files are
        # silently skipped (required=false). IsConfigured() returns False,
        # and configure proceeds cleanly.
        #
        # No nix-store symlinks for config files are created here — the
        # wrapper manages everything at runtime in cv-runner/.
        mv $out/bin/Runner.Listener $out/bin/Runner.Listener.real
        cat > $out/bin/Runner.Listener << 'WRAPPER'
#!/bin/sh

CVRUN=/var/lib/github-runner/cv-runner
NXBIN="$(cd "$(dirname "$0")" && pwd -P)"
NXROOT="$(dirname "$NXBIN")"

# Copy runner DLLs + apphost to the writable home so the runner's
# Assembly.Location points there (not the read-only nix store).
# cmp -s skips unchanged files to keep restarts fast.
setup_runner_home() {
  mkdir -p "$CVRUN/bin" 2>/dev/null || true
  for f in "$NXBIN"/*; do
    [ -f "$f" ] || continue
    fname="$(basename "$f")"
    [ "$fname" = "Runner.Listener" ] && continue
    dest="$CVRUN/bin/$fname"
    cmp -s "$f" "$dest" 2>/dev/null || cp "$f" "$dest" 2>/dev/null || true
  done
  chmod +x "$CVRUN/bin/Runner.Listener.real" 2>/dev/null || true
  ln -sfn "$NXROOT/externals" "$CVRUN/externals" 2>/dev/null || true
  ln -sfn /var/log/github-runner/cv "$CVRUN/_diag" 2>/dev/null || true
  printf '%s' "$PATH" > "$CVRUN/.path" 2>/dev/null || true
}

case "${1-}" in
configure)
  setup_runner_home
  # Remove config files so IsConfigured() returns False (absent files are
  # loaded with required=false and don't crash LoadDefaultUserAgents).
  # Stubs must NOT be used: {} in .credentials causes "Member 'd' was not
  # found" because configure reads credentials data during registration.
  rm -f "$CVRUN/.runner" "$CVRUN/.credentials" "$CVRUN/.credentials_rsaparams" 2>/dev/null || true
  exec "$CVRUN/bin/Runner.Listener.real" "$@"
  ;;
*)
  setup_runner_home
  exec "$CVRUN/bin/Runner.Listener.real" "$@"
  ;;
esac
WRAPPER
        chmod +x $out/bin/Runner.Listener
      '';

      meta.mainProgram = "Runner.Listener";
    }
  ) { };
}
