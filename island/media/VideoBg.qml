import QtQuick
import QtMultimedia

// Looping, muted video. Loaded by URL so a missing QtMultimedia only
// disables video backgrounds instead of breaking the whole shell.
Item {
    id: root

    property url source: ""
    property bool playing: true

    MediaPlayer {
        id: player
        source: root.source
        loops: MediaPlayer.Infinite
        videoOutput: out
        audioOutput: AudioOutput { muted: true }
        onSourceChanged: if (root.playing) play()
        Component.onCompleted: if (root.playing && root.source != "") play()
    }

    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    onPlayingChanged: playing ? player.play() : player.pause()
}
