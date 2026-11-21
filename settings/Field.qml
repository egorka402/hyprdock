import QtQuick
import qs.services

// Single-line text input with a placeholder.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    signal accepted()

    function clear() {
        input.text = "";
    }

    implicitHeight: 34
    radius: 8
    color: Theme.surface
    border.width: 1
    border.color: input.activeFocus ? Theme.accent : Theme.line

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.surface
        font.family: Theme.font
        font.pixelSize: 12
        selectByMouse: true
        clip: true
        onAccepted: root.accepted()
    }

    Text {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text.length === 0
        text: root.placeholder
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
        elide: Text.ElideRight
    }
}
