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
      '';

      meta.mainProgram = "Runner.Listener";
    }
  ) { };
}
