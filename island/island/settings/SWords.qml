import QtQuick
import qs.services
import qs.components

// A list setting typed as comma-separated words ("Mom, Alex").
SRow {
    id: root

    property string key: ""
    property string placeholder: ""
    property int fieldWidth: 320

    PField {
        width: root.fieldWidth
        anchors.verticalCenter: parent.verticalCenter
        placeholder: root.placeholder
        text: (Config.s[root.key] ?? []).join(", ")
        onEdited: {
            const v = text.split(",").map(w => w.trim()).filter(Boolean);
            if (JSON.stringify(v) !== JSON.stringify(Config.s[root.key] ?? [])) Config.s[root.key] = v;
        }
    }
}
