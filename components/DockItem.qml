import QtQuick
import qs.services

// One icon in the dock.
// The cell is wider than the icon (icon + spacing) so the mouse never "falls through"
// the gaps and the hover zoom doesn't flicker.
//
// The icon places itself by its position in the list (pos). When the order changes,
// pos changes and the icon slides to the new place.
Item {
    id: root

    required property var modelData          // the item's uid (see Config.qml)

    property real iconSize: 48
    property real gap: 8
    property int hoverIndex: -1

    readonly property var item: Config.itemByUid(root.modelData)
    readonly property int pos: Config.indexOfUid(root.modelData)

    readonly property bool hovered: area.containsMouse
    readonly property bool running: root.item.kind === "app" && Hypr.isRunning(root.item.wmClass)

    // Zoom: the hovered icon grows most, its direct neighbors a little.
    readonly property int distance: root.hoverIndex < 0 ? 99 : Math.abs(root.pos - root.hoverIndex)
    readonly property real zoom: root.distance === 0 ? 1.3 : (root.distance === 1 ? 1.1 : 1.0)

    // false while the icon is being created -> it "pops in" once.
    property bool ready: false
    Component.onCompleted: root.ready = true

    width: iconSize + gap
    height: iconSize
    x: root.pos * (root.iconSize + root.gap)

    // Slide to the new place when the order (or spacing) changes.
    Behavior on x {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    Item {
        id: body
        width: root.iconSize
        height: root.iconSize
        anchors.horizontalCenter: parent.horizontalCenter
        transformOrigin: Item.Bottom
        scale: root.ready ? root.zoom : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutBack
                easing.overshoot: 1.8
            }
        }

        // Press feedback
        opacity: area.pressed ? 0.75 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: 80 }
        }

        ItemIcon {
            anchors.fill: parent
            item: root.item
        }
    }

    // "Running" dot
    Rectangle {
        visible: root.running
        width: 4
        height: 4
        radius: 2
        color: Theme.accent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 1
    }

    // Name label above the icon
    Rectangle {
        id: tip
        anchors.horizontalCenter: parent.horizontalCenter
        y: -height - root.iconSize * 0.42
        width: label.implicitWidth + 20
        height: label.implicitHeight + 10
        radius: 8
        color: Theme.surface
        border.width: 1
        border.color: Theme.line
        opacity: root.hovered ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 140 }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.item.name ? root.item.name : ""
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                Launcher.launch(root.item);       // always a new instance
            else if (mouse.button === Qt.RightButton)
                UiState.settingsOpen = true;      // quick way into settings
            else
                Launcher.activate(root.item);     // focus or start
        }
    }
}
