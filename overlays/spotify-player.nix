final: prev: {
  spotify-player = prev.spotify-player.overrideAttrs (oldAttrs: {
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
