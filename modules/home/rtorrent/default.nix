{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.rtorrent;
in {
  options.modules.rtorrent = { enable = mkEnableOption "rtorrent"; };

  config = mkIf cfg.enable {
    # Install rtorrent
    home.packages = [ pkgs.rtorrent ];

    # Create basic rtorrent configuration
    xdg.configFile."rtorrent/rtorrent.rc".text = ''
      # Basic rtorrent configuration
      directory.default.set = ~/Downloads/torrents
      session.path.set = ~/.local/share/rtorrent/session

      # Watch directory for new torrents
      schedule2 = watch_directory,5,5,load.start=~/Downloads/torrents/*.torrent

      # Port range to use for listening
      network.port_range.set = 49164-49164

      # Enable DHT support for trackerless torrents or when all trackers are down
      dht.mode.set = auto
      dht.port.set = 6881
      protocol.pex.set = yes

      # Check hash for finished torrents
      pieces.hash.on_completion.set = yes

      # Encryption options
      protocol.encryption.set = allow_incoming,try_outgoing,enable_retry

      # Enable scgi interface for web frontends
      network.scgi.open_local = ~/.local/share/rtorrent/rpc.socket
    '';

    # Create necessary directories
    home.activation.rtorrentDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/Downloads/torrents"
      mkdir -p "$HOME/.local/share/rtorrent/session"
    '';
  };
}
