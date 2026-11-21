import QtQuick
import qs.components
import qs.services

// One line in the "Items" list of the settings: icon, name, move up/down, delete.
Rectangle {
    id: root

    required property var modelData
    required property int index

    implicitHeight: 48
    radius: 10
    color: hover.hovered ? Theme.surfaceHi : Theme.surface
    border.width: 1
    border.color: Theme.line

    HoverHandler {
        id: hover
    }

    ItemIcon {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        item: root.modelData
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: buttons.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.modelData.name
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 13
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.modelData.kind === "site" ? root.modelData.url : "app"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    Row {
        id: buttons
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Btn {
            text: "↑"
            implicitWidth: 30
            onClicked: Config.moveItem(root.index, -1)
        }
        Btn {
            text: "↓"
            implicitWidth: 30
            onClicked: Config.moveItem(root.index, 1)
        }
        Btn {
            text: "×"
            danger: true
            implicitWidth: 30
            onClicked: Config.removeItem(root.index)
        }
    }
}
