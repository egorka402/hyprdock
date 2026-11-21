import QtQuick
import qs.services

// Labeled on/off switch.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property bool checked: false
    signal toggled(bool value)

    implicitHeight: hint === "" ? 30 : 46

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            text: root.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 13
        }
        Text {
            visible: root.hint !== ""
            text: root.hint
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 10
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 22
        radius: 11
        color: root.checked ? Theme.accent : Theme.line

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.surface : Theme.text

            Behavior on x {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
