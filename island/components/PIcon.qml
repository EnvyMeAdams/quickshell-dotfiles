import QtQuick
import qs.theme

// Material Symbols Rounded ligatures: PIcon { name: "volume_up" }
Text {
    property string name: ""
    property real size: 18

    text: name
    font.family: Theme.iconFont
    font.pixelSize: size
    color: Theme.ink
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
