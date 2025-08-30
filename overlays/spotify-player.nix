final: prev: {
  spotify-player = (prev.spotify-player.override {
    # withStreaming = true;
    # withDaemon = true;
    # withAudioBackend = "rodio";
    # withMediaControl = true;
    # withImage = true;
    # withNotify = true;
    # withSixel = true;
    # withFuzzy = true;
  }).overrideAttrs (oldAttrs: {
    version = "unstable-main";

    src = prev.fetchFromGitHub {
      owner = "aome510";
      repo = "spotify-player";
      rev = "bd38dd05a3c52107f76665dc88002e5a0815d095";
      hash = "sha256-DCIZHAfI3x9I6j2f44cDcXbMpZbNXJ62S+W19IY6Qus=";
    };

    cargoHash = "sha256-fNDztl0Vxq2fUzc6uLNu5iggNRnRB2VxzWm+AlSaoU0=";
  });
}
