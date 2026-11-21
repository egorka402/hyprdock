import QtQuick
import qs.services

// Labeled 0..100 slider.
Item {
    id: root

    property string label: ""
    property int value: 0
    signal moved(int value)

    implicitHeight: 54

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        text: root.label
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 13
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.value + "%"
        color: Theme.accent
        font.family: Theme.font
        font.pixelSize: 13
    }

    // track
    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        y: 34
        height: 4
        radius: 2
        color: Theme.line

        Rectangle {
            width: handle.x + handle.width / 2 - 0
            height: parent.height
            radius: 2
            color: Theme.accent
        }
    }

    // handle
    Rectangle {
        id: handle
        width: 16
        height: 16
        radius: 8
        y: track.y + track.height / 2 - height / 2
        x: track.x + (root.value / 100) * track.width - width / 2
        color: area.pressed ? Theme.text : Theme.accent
        border.width: 3
        border.color: Theme.surface

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    MouseArea {
        id: area
        anchors.left: parent.left
        anchors.right: parent.right
        y: 22
        height: 28
        cursorShape: Qt.PointingHandCursor

        function update(mouseX) {
            const t = Math.max(0, Math.min(1, (mouseX - track.x) / track.width));
            const v = Math.round(t * 100);
            if (v !== root.value)
                root.moved(v);
        }

        onPressed: mouse => update(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                update(mouse.x);
        }
    }
}
