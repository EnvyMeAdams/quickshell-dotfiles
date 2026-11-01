import QtQuick
import qs.services
import qs.theme

// The signature look: cream face, ink outline, hard offset shadow.
// The item's size INCLUDES the shadow; children go on the face.
// Set glassSource to an item behind the card to turn the face into frosted glass.
Item {
    id: root

    property color fill: Theme.card
    property real radius: Theme.radius
    property int offset: Theme.shadow
    property bool pressed: false
    property color borderColor: Theme.line
    property int borderWidth: Theme.outline
    property Item glassSource: null
    readonly property bool glass: glassSource !== null
    default property alias content: face.data
    readonly property Item surface: face

    implicitWidth: 120
    implicitHeight: 44

    Rectangle {
        visible: root.offset > 0
        x: root.offset
        y: root.offset
        width: root.width - root.offset
        height: root.height - root.offset
        radius: root.radius
        color: Theme.shade
        opacity: root.glass ? 0.45 : 1
    }

    Rectangle {
        id: face
        x: root.pressed ? root.offset : 0
        y: root.pressed ? root.offset : 0
        width: root.width - root.offset
        height: root.height - root.offset
        radius: root.radius
        color: root.glass ? "transparent" : root.fill
        border.width: root.borderWidth
        border.color: root.borderColor

        Behavior on x { NumberAnimation { duration: 60 } }
        Behavior on y { NumberAnimation { duration: 60 } }
        Behavior on color { ColorAnimation { duration: 140 } }

        // loaded by path so a missing QtQuick.Effects only turns off the blur
        Loader {
            id: glassLoader
            anchors.fill: parent
            anchors.margins: root.borderWidth
            z: -2
            active: root.glass
            source: Qt.resolvedUrl("GlassLayer.qml")
        }
        Binding { target: glassLoader.item; property: "source"; value: root.glassSource; when: glassLoader.status === Loader.Ready }
        Binding { target: glassLoader.item; property: "radius"; value: Math.max(0, root.radius - root.borderWidth); when: glassLoader.status === Loader.Ready }
        Rectangle {
            anchors.fill: parent
            anchors.margins: root.borderWidth
            z: -1
            visible: root.glass
            radius: Math.max(0, root.radius - root.borderWidth)
            color: root.fill
            opacity: Config.s.glassTint
        }
    }
}
