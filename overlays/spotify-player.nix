# overlays/spotify-player.nix
final: prev: {
  spotify-player = prev.spotify-player.overrideAttrs (oldAttrs: {
    src = prev.fetchFromGitHub {
      owner = "aome510";
      repo = "spotify-player";
      rev = "bd38dd05a3c52107f76665dc88002e5a0815d095";
      hash = "sha256-DCIZHAfI3x9I6j2f44cDcXbMpZbNXJ62S+W19IY6Qus=";
    };

    # Force rebuild of cargo dependencies by overriding the entire cargoDeps
    cargoDeps = prev.rustPlatform.importCargoLock {
      lockFile =
        prev.fetchFromGitHub {
          owner = "aome510";
          repo = "spotify-player";
          rev = "bd38dd05a3c52107f76665dc88002e5a0815d095";
          hash = "sha256-DCIZHAfI3x9I6j2f44cDcXbMpZbNXJ62S+W19IY6Qus=";
        }
        + "/Cargo.lock";
    };

    # Remove cargoHash entirely to avoid validation
    cargoHash = null;

    # Enable PulseAudio backend for PipeWire compatibility and add build inputs
    cargoBuildFlags = [
      "--features"
      "pulseaudio-backend"
    ];
    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
      prev.libpulseaudio
      prev.pkg-config
    ];
  });
}
