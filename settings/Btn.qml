import QtQuick
import qs.services

// Small text button. primary = filled accent color.
Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    property bool danger: false
    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 32
    radius: 8
    color: primary ? (area.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent) : (area.containsMouse ? Theme.surfaceHi : "transparent")
    border.width: primary ? 0 : 1
    border.color: danger ? Theme.danger : Theme.line

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.surface : (root.danger ? Theme.danger : Theme.text)
        font.family: Theme.font
        font.pixelSize: 12
        font.bold: root.primary
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
