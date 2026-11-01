import QtQuick
import qs.services
import qs.theme

// Full-screen photo or video, with a soft pastel fill underneath.
Item {
    id: root

    property string path: ""
    property string kind: "photo"
    property string screenName: ""
    property bool playing: true

    readonly property bool videoHere: kind === "video" && path !== ""

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.pastels.blue }
            GradientStop { position: 0.55; color: Theme.pastels.peach }
            GradientStop { position: 1.0; color: Theme.base }
        }
    }

    Image {
        anchors.fill: parent
        visible: root.kind === "photo" && root.path !== ""
        source: visible ? "file://" + root.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    Loader {
        id: video
        anchors.fill: parent
        active: root.videoHere
        source: Qt.resolvedUrl("VideoBg.qml")
    }
    Binding { target: video.item; property: "source"; value: "file://" + root.path; when: video.status === Loader.Ready }
    Binding { target: video.item; property: "playing"; value: root.playing; when: video.status === Loader.Ready }
}
