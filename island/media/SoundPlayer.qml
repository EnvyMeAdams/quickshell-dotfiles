import QtQuick
import QtMultimedia

// One sound at a time. services/Sounds.qml keeps a few of these so sounds can
// overlap. Only created when Qt Multimedia is available (else pw-play is used).
Item {
    id: root

    readonly property bool busy: player.playbackState === MediaPlayer.PlayingState

    function play(url, volume) {
        player.stop();
        out.volume = Math.max(0, Math.min(1, volume));
        player.source = url;
        player.play();
    }
    function stop() { player.stop(); }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput { id: out }
        onErrorOccurred: (error, message) => console.warn("island: sound:", message)
    }
}
