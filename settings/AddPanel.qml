import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

// "Add item" page: pick an installed app, or paste a site link and choose a browser.
Item {
    id: root

    signal done()

    property string mode: "app"      // app | site
    property var selected: null      // chosen DesktopEntry (apps)
    property var browser: null       // chosen DesktopEntry, null = system default
    property string error: ""

    function allApps() {
        return [...DesktopEntries.applications.values].filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name));
    }

    function filteredApps() {
        const q = search.text.trim().toLowerCase();
        return root.allApps().filter(e => q === "" || e.name.toLowerCase().includes(q));
    }

    function browsers() {
        return root.allApps().filter(e => e.categories && Array.from(e.categories).indexOf("WebBrowser") >= 0);
    }

    function cleanCommand(entry) {
        return Array.from(entry.command).filter(a => !a.startsWith("%"));
    }

    function reset() {
        root.selected = null;
        root.browser = null;
        root.error = "";
        search.clear();
        nameField.clear();
        iconField.clear();
        cmdField.clear();
        urlField.clear();
    }

    function submit() {
        const name = nameField.text.trim();
        const icon = iconField.text.trim();
        let item = null;

        if (root.mode === "app") {
            if (root.selected) {
                item = {
                    kind: "app",
                    name: name || root.selected.name,
                    icon: icon,
                    id: root.selected.id,
                    cmd: root.cleanCommand(root.selected),
                    wmClass: root.selected.startupClass || String(root.selected.id).replace(/\.desktop$/, "")
                };
            } else if (cmdField.text.trim() !== "") {
                if (name === "") {
                    root.error = "Give it a name.";
                    return;
                }
                const parts = cmdField.text.trim().split(/\s+/);
                item = {
                    kind: "app",
                    name: name,
                    icon: icon,
                    id: "",
                    cmd: parts,
                    wmClass: parts[0].split("/").pop()
                };
            } else {
                root.error = "Pick an app from the list or type a command.";
                return;
            }
        } else {
            let url = urlField.text.trim();
            if (url === "") {
                root.error = "Paste a link first.";
                return;
            }
            if (!/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(url))
                url = "https://" + url;
            const host = url.replace(/^[a-zA-Z]+:\/\//, "").split("/")[0];
            item = {
                kind: "site",
                name: name || host,
                icon: icon,
                url: url,
                browser: root.browser ? root.cleanCommand(root.browser) : ["xdg-open"]
            };
        }

        Config.addItem(item);
        root.reset();
        root.done();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // header
        RowLayout {
            Layout.fillWidth: true

            Btn {
                text: "← back"
                onClicked: {
                    root.reset();
                    root.done();
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: "add item"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 14
                font.bold: true
            }
        }

        Segmented {
            Layout.fillWidth: true
            model: [
                { label: "app", value: "app" },
                { label: "website", value: "site" }
            ]
            current: root.mode
            onPicked: value => {
                root.mode = value;
                root.error = "";
            }
        }

        // ---------- app: search + list ----------
        Field {
            id: search
            Layout.fillWidth: true
            visible: root.mode === "app"
            placeholder: "search installed apps..."
        }

        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 80
            visible: root.mode === "app"
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds

            model: ScriptModel {
                values: root.mode === "app" ? root.filteredApps() : []
            }

            delegate: Rectangle {
                id: appRow
                required property var modelData

                readonly property bool active: root.selected === modelData

                width: appList.width
                height: 38
                radius: 8
                color: active ? Theme.surfaceHi : (rowHover.hovered ? Theme.surface : "transparent")
                border.width: active ? 1 : 0
                border.color: Theme.accent

                HoverHandler {
                    id: rowHover
                }

                ItemIcon {
                    id: rowIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    item: ({ kind: "app", name: appRow.modelData.name, icon: appRow.modelData.icon })
                }

                Text {
                    anchors.left: rowIcon.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: appRow.modelData.name
                    color: appRow.active ? Theme.accent : Theme.text
                    font.family: Theme.font
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selected = appRow.modelData;
                        nameField.text = appRow.modelData.name;
                        iconField.text = appRow.modelData.icon ? String(appRow.modelData.icon) : "";
                        root.error = "";
                    }
                }
            }
        }

        Field {
            id: cmdField
            Layout.fillWidth: true
            visible: root.mode === "app"
            placeholder: "or a custom command, e.g. kitty -e btop"
        }

        // ---------- website: link + browser ----------
        Field {
            id: urlField
            Layout.fillWidth: true
            visible: root.mode === "site"
            placeholder: "https://example.com"
        }

        Text {
            visible: root.mode === "site"
            text: "open in"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11
        }

        Flow {
            Layout.fillWidth: true
            visible: root.mode === "site"
            spacing: 6

            // system default
            Rectangle {
                readonly property bool active: root.browser === null
                width: defLabel.implicitWidth + 24
                height: 30
                radius: 8
                color: active ? Theme.surfaceHi : "transparent"
                border.width: 1
                border.color: active ? Theme.accent : Theme.line

                Text {
                    id: defLabel
                    anchors.centerIn: parent
                    text: "system default"
                    color: parent.active ? Theme.accent : Theme.text
                    font.family: Theme.font
                    font.pixelSize: 11
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.browser = null
                }
            }

            Repeater {
                model: ScriptModel {
                    values: root.mode === "site" ? root.browsers() : []
                }

                Rectangle {
                    id: bChip
                    required property var modelData
                    readonly property bool active: root.browser === modelData

                    width: bLabel.implicitWidth + 24
                    height: 30
                    radius: 8
                    color: active ? Theme.surfaceHi : "transparent"
                    border.width: 1
                    border.color: active ? Theme.accent : Theme.line

                    Text {
                        id: bLabel
                        anchors.centerIn: parent
                        text: bChip.modelData.name
                        color: bChip.active ? Theme.accent : Theme.text
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.browser = bChip.modelData
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "site"
        }

        // ---------- shared: name + icon ----------
        Field {
            id: nameField
            Layout.fillWidth: true
            placeholder: "name (optional for sites)"
        }

        Field {
            id: iconField
            Layout.fillWidth: true
            placeholder: "icon (optional): theme name or /path/to/image.png"
        }

        Text {
            Layout.fillWidth: true
            visible: root.error !== ""
            text: root.error
            color: Theme.danger
            font.family: Theme.font
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }

        Btn {
            Layout.fillWidth: true
            text: "add to dock"
            primary: true
            onClicked: root.submit()
        }
    }
}
