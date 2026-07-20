final: prev: {
  github-runner = prev.stdenv.mkDerivation rec {
    pname = "github-runner";
    version = "2.335.1";

    src = prev.fetchurl {
      url = "https://github.com/actions/runner/releases/download/v${version}/actions-runner-linux-x64-${version}.tar.gz";
      hash = "sha256-TvLyUoXwrkR38f4eNG23bS8+vwOCTi3dGXOigZv2yM8=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [ prev.autoPatchelfHook ];
    buildInputs = [ prev.stdenv.cc.cc.lib ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin $out/externals
      cp -r bin/. $out/bin/
      cp config.sh env.sh run.sh safe_sleep.sh $out/bin/
      cp -r externals/. $out/externals/
    '';

    meta.mainProgram = "Runner.Listener";
  };
}
