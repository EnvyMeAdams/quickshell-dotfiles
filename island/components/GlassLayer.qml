import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.services

// Frosted glass: a blurred copy of whatever `source` shows behind this item.
// Used by Card when `glassSource` is set (lock screen, screensaver clock).
ClippingRectangle {
    id: g

    property Item source: null
    color: "transparent"

    property rect area: Qt.rect(0, 0, 0, 0)
    function update() {
        if (!source || !visible) return;
        const p = g.mapToItem(source, 0, 0);
        area = Qt.rect(p.x, p.y, g.width, g.height);
    }
    onWidthChanged: update()
    onHeightChanged: update()
    Component.onCompleted: Qt.callLater(update)
    // keeps the glass lined up while things animate
    Timer { interval: 200; running: g.visible; repeat: true; onTriggered: g.update() }

    ShaderEffectSource {
        id: tex
        anchors.fill: parent
        sourceItem: g.source
        sourceRect: g.area
        live: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: tex
        blurEnabled: true
        blur: Config.s.glassBlur
        blurMax: 64
        saturation: 0.2
    }
}
