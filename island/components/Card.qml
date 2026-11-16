import QtQuick
import qs.services
import qs.theme

// One card, three looks (Theme.look):
//   smoke / clear: see-through glass, a hairline edge, a soft sheen and a
//                  light line along the top, like light catching the rim.
//   classic:       cream face, ink outline, hard offset shadow.
// The item's size INCLUDES the shadow (0 on glass); children go on the face.
// frost: true puts the blurred wallpaper behind the face (outer glass only:
//        the pill, popups); frostScreen / frostOrigin say where it is.
// glassSource: an item behind the card to blur instead (lock screen).
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
    // glass looks only
    property bool lit: true
    property bool frost: false
    property string frostScreen: ""
    property point frostOrigin: Qt.point(0, 0)
    readonly property bool frosting: frost && Theme.glass && Config.s.frost && !glass
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
        // glass presses in by shrinking a touch instead of dropping onto a shadow
        scale: Theme.glass && root.pressed && root.offset === 0 ? 0.97 : 1

        Behavior on x { NumberAnimation { duration: 60 } }
        Behavior on y { NumberAnimation { duration: 60 } }
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
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
            // glass looks: plain cards take the look's own glass tint
            color: Theme.glass && root.fill.a < 0.2 ? Theme.panel : root.fill
            opacity: Theme.glass ? 1 : Config.s.glassTint
        }

        // frosted wallpaper under the tinted face (the face colour sits on top)
        Loader {
            id: frostLoader
            anchors.fill: parent
            z: -3
            active: root.frosting
            source: Qt.resolvedUrl("Frost.qml")
        }
        Binding { target: frostLoader.item; property: "radius"; value: root.radius; when: frostLoader.status === Loader.Ready }
        Binding { target: frostLoader.item; property: "screenName"; value: root.frostScreen; when: frostLoader.status === Loader.Ready }
        Binding { target: frostLoader.item; property: "origin"; value: root.frostOrigin; when: frostLoader.status === Loader.Ready }

        // sheen: a faint light falling from the top edge
        Rectangle {
            anchors.fill: parent
            anchors.margins: root.borderWidth
            visible: Theme.glass && root.lit
            radius: Math.max(0, root.radius - root.borderWidth)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Theme.look === "clear" ? 0.10 : 0.05) }
                GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
        // rim light: a bright line along the top that fades out at the corners
        Rectangle {
            visible: Theme.glass && root.lit && root.height > 20
            x: root.radius * 0.6
            y: root.borderWidth
            width: Math.max(0, face.width - root.radius * 1.2)
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.rim }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
