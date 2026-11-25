{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.mpv;

in {
  options.modules.mpv = { enable = mkEnableOption "mpv"; };
  config = mkIf cfg.enable {
    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [
        # VLC-like clickable UI with seekbar thumbnails
        uosc
        thumbfast
        # Sentence mining into Anki (Ctrl+N new card, Ctrl+M add audio/picture to last card, A menu)
        mpvacious
        # Subtitle lines to a texthooker page for Yomitan lookups
        (pkgs.callPackage ./mpv-websocket.nix { })
      ];
      config = {
        # mpv_websocket connects to the server through this socket
        input-ipc-server = "/tmp/mpv-socket";

        # uosc replaces the stock OSC
        osc = "no";
        osd-bar = "no";
        border = "no";

        hwdec = "auto-safe";
        save-position-on-quit = true;
        slang = "ja,jpn,jp";
        alang = "ja,jpn,jp";
        sub-auto = "fuzzy";
      };
      scriptOpts.subs2srs = {
        deck_name = "Mining::Anime";
        model_name = "Lapis";
        sentence_field = "Sentence";
        secondary_field = "";
        audio_field = "SentenceAudio";
        image_field = "Picture";
        vocab_field = "Expression";
        vocab_audio_field = "ExpressionAudio";
        miscinfo_field = "MiscInfo";
        miscinfo_format = "%n EP%d (%t)";
        note_tag = "%n";
        snapshot_format = "webp";
        menu_font_name = "Noto Sans CJK JP";
      };
    };
  };
}
