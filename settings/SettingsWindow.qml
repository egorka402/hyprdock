import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

// The Hyprdock launcher: a small floating window where everything is configured.
FloatingWindow {
    id: win

    title: "Hyprdock"
    color: Theme.surface
    minimumSize: Qt.size(460, 620)
    implicitWidth: 480
    implicitHeight: 780

    visible: UiState.settingsOpen
    onVisibleChanged: {
        if (!visible)
            UiState.settingsOpen = false;
    }

    property bool adding: false

    // The dock stays visible while settings are open and can cover the bottom of this window.
    // Keep the bottom of the content above it (same size formula as in Dock.qml).
    readonly property real screenH: Quickshell.screens.length > 0 ? Quickshell.screens[0].height : 1080
    readonly property real dockIcon: 28 + (Math.max(36, screenH * 0.10 - 20) - 28) * (Config.size / 100)
    readonly property real dockReserve: Math.round(dockIcon * 1.3 + 44)

    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        // ================= main page =================
        Flickable {
            id: page
            anchors.fill: parent
            anchors.margins: 20
            anchors.bottomMargin: 20 + win.dockReserve
            visible: !win.adding
            clip: true
            contentWidth: width
            contentHeight: content.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: content
                width: page.width
                spacing: 14

                // ---- header ----
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "hyprdock"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Text {
                        text: "v0.1"
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignBottom
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Btn {
                        text: "close"
                        onClicked: UiState.settingsOpen = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.line
                }

                // ---- look ----
                Text {
                    text: "LOOK"
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }

                HSlider {
                    Layout.fillWidth: true
                    label: "corner roundness"
                    value: Config.radius
                    onMoved: v => Config.setValue("radius", v)
                }

                HSlider {
                    Layout.fillWidth: true
                    label: "size"
                    value: Config.size
                    onMoved: v => Config.setValue("size", v)
                }

                HSlider {
                    Layout.fillWidth: true
                    label: "icon spacing"
                    value: Config.spacing
                    onMoved: v => Config.setValue("spacing", v)
                }

                HSlider {
                    Layout.fillWidth: true
                    label: "background opacity"
                    value: Config.bgOpacity
                    onMoved: v => Config.setValue("bgOpacity", v)
                }

                Text {
                    text: "border"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                Segmented {
                    Layout.fillWidth: true
                    model: [
                        { label: "dark", value: "dark" },
                        { label: "light", value: "light" }
                    ]
                    current: Config.border
                    onPicked: v => Config.setValue("border", v)
                }

                // ---- behavior ----
                Text {
                    Layout.topMargin: 6
                    text: "BEHAVIOR"
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }

                Text {
                    text: "when a window is open"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                Segmented {
                    Layout.fillWidth: true
                    model: [
                        { label: "never hide", value: "never" },
                        { label: "hide, show on hover", value: "auto" }
                    ]
                    current: Config.hide
                    onPicked: v => Config.setValue("hide", v)
                }

                Toggle {
                    Layout.fillWidth: true
                    label: "online website icons"
                    hint: "downloads the favicon of each site"
                    checked: Config.onlineIcons
                    onToggled: v => Config.setValue("onlineIcons", v)
                }

                // ---- items ----
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6

                    Text {
                        text: "ITEMS"
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.letterSpacing: 2
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Btn {
                        text: "+ add"
                        primary: true
                        onClicked: win.adding = true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: Config.items.length === 0
                    text: "The dock is empty. Press \"+ add\" to put an app or a website here."
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: Config.items

                    ItemRow {
                        Layout.fillWidth: true
                    }
                }

                Item {
                    Layout.preferredHeight: 8
                }
            }
        }

        // ================= add page =================
        AddPanel {
            anchors.fill: parent
            anchors.margins: 20
            anchors.bottomMargin: 20 + win.dockReserve
            visible: win.adding
            onDone: win.adding = false
        }
    }
}
