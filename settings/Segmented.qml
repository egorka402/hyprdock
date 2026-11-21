import QtQuick
import qs.services

// Row of options, one selected. model: [{ label: "...", value: "..." }, ...]
Item {
    id: root

    property var model: []
    property string current: ""
    signal picked(string value)

    implicitHeight: 34

    Row {
        anchors.fill: parent
        spacing: 6

        Repeater {
            model: root.model

            Rectangle {
                id: chip
                required property var modelData

                readonly property bool active: root.current === modelData.value

                width: (root.width - (root.model.length - 1) * 6) / root.model.length
                height: root.height
                radius: 8
                color: active ? Theme.surfaceHi : "transparent"
                border.width: 1
                border.color: active ? Theme.accent : (mouse.containsMouse ? Theme.dim : Theme.line)

                Behavior on border.color {
                    ColorAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    color: chip.active ? Theme.accent : Theme.text
                    font.family: Theme.font
                    font.pixelSize: 11
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(chip.modelData.value)
                }
            }
        }
    }
}
