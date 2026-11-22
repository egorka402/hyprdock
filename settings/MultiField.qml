import QtQuick
import qs.services

// Multi-line text input with a placeholder (used for pasting several links).
Rectangle {
    id: root

    property alias text: edit.text
    property string placeholder: ""

    function clear() {
        edit.text = "";
    }

    implicitHeight: 100
    radius: 8
    color: Theme.surface
    border.width: 1
    border.color: edit.activeFocus ? Theme.accent : Theme.line

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        contentWidth: width
        contentHeight: Math.max(edit.paintedHeight, height)
        boundsBehavior: Flickable.StopAtBounds

        function ensureVisible(r) {
            if (contentY >= r.y)
                contentY = r.y;
            else if (contentY + height <= r.y + r.height)
                contentY = r.y + r.height - height;
        }

        TextEdit {
            id: edit
            width: flick.width
            height: flick.height
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.surface
            font.family: Theme.font
            font.pixelSize: 12
            wrapMode: TextEdit.WrapAnywhere
            selectByMouse: true
            onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
        }
    }

    Text {
        anchors.fill: flick
        visible: edit.text.length === 0
        text: root.placeholder
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
}
