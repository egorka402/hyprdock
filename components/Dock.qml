import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The dock itself: one transparent layer-shell window along the bottom of a screen.
// Only the dock (or, when hidden, a thin strip at the bottom center) receives mouse input;
// everything else clicks through to the windows below.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    anchors {
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hyprdock"
    WlrLayershell.layer: WlrLayer.Top

    // ---- size ------------------------------------------------------------
    // Size 0%   -> small but readable icons.
    // Size 100% -> dock height is about one tenth of the screen height.
    readonly property real padV: 10
    readonly property real bottomGap: 10
    readonly property real minIcon: 28
    readonly property real maxIcon: Math.max(minIcon + 8, modelData.height * 0.10 - 2 * padV)
    readonly property int count: Math.max(1, Config.items.length)
    readonly property real gap: 2 + (Config.spacing / 100) * 26
    readonly property real wantedIcon: minIcon + (maxIcon - minIcon) * (Config.size / 100)
    readonly property real padH: 12 + (Config.radius / 100) * 0.35 * (wantedIcon + 2 * padV) / 2
    // never let the dock grow wider than 92% of the screen
    readonly property real fitIcon: (modelData.width * 0.92 - 2 * padH) / count - gap
    readonly property real iconSize: Math.max(20, Math.min(wantedIcon, fitIcon))

    // The window is always the same height (room for zoom and name labels).
    implicitHeight: Math.round(modelData.height * 0.10 + 0.4 * maxIcon + 90)

    // ---- hiding ----------------------------------------------------------
    property bool revealed: false
    readonly property bool autoHide: Config.hide === "auto"
    readonly property bool windowOpen: Hypr.windowOpenOn(modelData.name)
    readonly property bool shown: !autoHide || !windowOpen || revealed || UiState.settingsOpen

    Timer {
        id: hideTimer
        interval: 450
        onTriggered: win.revealed = false
    }

    // Only the dock / hover strip takes mouse input.
    mask: Region {
        item: maskRect
    }

    Item {
        id: stage
        anchors.fill: parent

        // Hover over anything inside the input region (dock, icons, strip).
        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop();
                    win.revealed = true;
                } else {
                    hideTimer.restart();
                }
            }
        }

        // Invisible rectangle that defines where input is accepted.
        Item {
            id: maskRect
            width: win.shown ? dock.width + 40 : Math.max(dock.width, 360)
            height: win.shown ? dock.height + win.bottomGap + 0.35 * win.iconSize + 8 : 6
            x: (stage.width - width) / 2
            y: stage.height - height
        }

        Rectangle {
            id: dock

            property int hoverIndex: -1

            width: strip.width + 2 * win.padH
            height: win.iconSize + 2 * win.padV
            radius: (Config.radius / 100) * height / 2
            color: Qt.rgba(Theme.panelBase.r, Theme.panelBase.g, Theme.panelBase.b, Config.bgOpacity / 100)
            border.width: 2
            border.color: Config.border === "light" ? "#ffffff" : "#000000"

            x: (stage.width - width) / 2
            y: win.shown ? stage.height - height - win.bottomGap : stage.height + 6

            Behavior on y {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on radius {
                NumberAnimation { duration: 120 }
            }

            // Icons place themselves inside this strip by their position in the list,
            // so when the order changes they slide to their new spots (see DockItem.qml).
            Item {
                id: strip
                anchors.centerIn: parent
                width: Config.items.length > 0 ? Config.items.length * (win.iconSize + win.gap) : win.iconSize
                height: win.iconSize

                Repeater {
                    // One stable entry per item (its uid), so icons are kept, not recreated, on reorder.
                    model: ScriptModel {
                        values: Config.uids
                    }

                    DockItem {
                        iconSize: win.iconSize
                        gap: win.gap
                        hoverIndex: dock.hoverIndex

                        onHoveredChanged: {
                            if (hovered)
                                dock.hoverIndex = pos;
                            else if (dock.hoverIndex === pos)
                                dock.hoverIndex = -1;
                        }
                    }
                }

                // Empty dock: show a "+" that opens the settings.
                Item {
                    visible: Config.items.length === 0
                    width: visible ? win.iconSize : 0
                    height: win.iconSize

                    Rectangle {
                        anchors.fill: parent
                        radius: width * 0.26
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: parent.width * 0.6
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: UiState.settingsOpen = true
                    }
                }
            }
        }
    }
}
