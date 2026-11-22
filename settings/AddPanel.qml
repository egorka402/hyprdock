import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

// "Add item" page: pick one or several installed apps, or paste one or several site links
// and choose a browser. Everything chosen is added to the dock with one click.
Item {
    id: root

    signal done()

    property string mode: "app"      // app | site
    property var chosen: []         // chosen DesktopEntry objects (apps)
    property var browser: null       // chosen DesktopEntry, null = system default
    property string error: ""

    // Name and icon can only be set by hand when exactly one thing is being added.
    readonly property int count: root.mode === "app" ? root.chosen.length : root.urls().length
    readonly property bool canName: root.count <= 1
    readonly property string addLabel: root.count > 1 ? "add " + root.count + " to dock" : "add to dock"

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
        const args = Array.from(entry.command).filter(a => !a.startsWith("%"));
        // "app --  %U" leaves a dangling "--" once the placeholder is removed
        if (args.length > 1 && args[args.length - 1] === "--")
            args.pop();
        return args;
    }

    // One link per line (or separated by spaces).
    function urls() {
        return urlArea.text.split(/\s+/).filter(s => s.length > 0);
    }

    function toggle(entry) {
        const list = root.chosen.slice();
        const i = list.indexOf(entry);
        if (i >= 0)
            list.splice(i, 1);
        else
            list.push(entry);
        root.chosen = list;
        root.error = "";
        root.syncFields();
    }

    // With exactly one app chosen, prefill the name and icon so they can be edited.
    function syncFields() {
        if (root.chosen.length === 1) {
            nameField.text = root.chosen[0].name;
            iconField.text = root.chosen[0].icon ? String(root.chosen[0].icon) : "";
        } else if (root.chosen.length === 0) {
            nameField.clear();
            iconField.clear();
        }
    }

    function reset() {
        root.chosen = [];
        root.browser = null;
        root.error = "";
        search.clear();
        nameField.clear();
        iconField.clear();
        cmdField.clear();
        urlArea.clear();
    }

    function submit() {
        const name = nameField.text.trim();
        const icon = iconField.text.trim();
        const items = [];

        if (root.mode === "app") {
            if (root.chosen.length > 0) {
                const single = root.chosen.length === 1;
                for (const e of root.chosen) {
                    items.push({
                        kind: "app",
                        name: single ? (name || e.name) : e.name,
                        icon: single ? icon : (e.icon ? String(e.icon) : ""),
                        id: e.id,
                        cmd: root.cleanCommand(e),
                        wmClass: e.startupClass || String(e.id).replace(/\.desktop$/, "")
                    });
                }
            } else if (cmdField.text.trim() !== "") {
                if (name === "") {
                    root.error = "Give it a name.";
                    return;
                }
                const parts = cmdField.text.trim().split(/\s+/);
                items.push({
                    kind: "app",
                    name: name,
                    icon: icon,
                    id: "",
                    cmd: parts,
                    wmClass: parts[0].split("/").pop()
                });
            } else {
                root.error = "Pick one or more apps from the list, or type a command.";
                return;
            }
        } else {
            const links = root.urls();
            if (links.length === 0) {
                root.error = "Paste a link first.";
                return;
            }
            const single = links.length === 1;
            for (const raw of links) {
                const url = /^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(raw) ? raw : "https://" + raw;
                const host = url.replace(/^[a-zA-Z]+:\/\//, "").split("/")[0];
                items.push({
                    kind: "site",
                    name: single ? (name || host) : host,
                    icon: single ? icon : "",
                    url: url,
                    browser: root.browser ? root.cleanCommand(root.browser) : ["xdg-open"]
                });
            }
        }

        Config.addItems(items);
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
                text: "add items"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 14
                font.bold: true
            }
        }

        Segmented {
            Layout.fillWidth: true
            model: [
                { label: "apps", value: "app" },
                { label: "websites", value: "site" }
            ]
            current: root.mode
            onPicked: value => {
                root.mode = value;
                root.error = "";
            }
        }

        // ---------- apps: search + list (tick as many as you like) ----------
        RowLayout {
            Layout.fillWidth: true
            visible: root.mode === "app"
            spacing: 10

            Field {
                id: search
                Layout.fillWidth: true
                placeholder: "search installed apps..."
            }
            Text {
                visible: root.chosen.length > 0
                text: root.chosen.length + " selected"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 11
            }
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

                readonly property bool active: root.chosen.indexOf(modelData) >= 0

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
                    anchors.right: tick.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: appRow.modelData.name
                    color: appRow.active ? Theme.accent : Theme.text
                    font.family: Theme.font
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                // checkbox
                Rectangle {
                    id: tick
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 5
                    color: appRow.active ? Theme.accent : "transparent"
                    border.width: 1
                    border.color: appRow.active ? Theme.accent : Theme.line

                    Text {
                        anchors.centerIn: parent
                        visible: appRow.active
                        text: "✓"
                        color: Theme.surface
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggle(appRow.modelData)
                }
            }
        }

        Field {
            id: cmdField
            Layout.fillWidth: true
            visible: root.mode === "app"
            placeholder: "or a custom command, e.g. kitty -e btop"
        }

        // ---------- websites: links + browser ----------
        MultiField {
            id: urlArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 90
            visible: root.mode === "site"
            placeholder: "paste links, one per line:\nhttps://example.com\nhttps://another.org"
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

        // ---------- shared: name + icon (only when adding a single item) ----------
        Field {
            id: nameField
            Layout.fillWidth: true
            visible: root.canName
            placeholder: "name (optional for sites)"
        }

        Field {
            id: iconField
            Layout.fillWidth: true
            visible: root.canName
            placeholder: "icon (optional): theme name or /path/to/image.png"
        }

        Text {
            Layout.fillWidth: true
            visible: !root.canName
            text: "Several items: each keeps its own name and icon."
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 10
            wrapMode: Text.WordWrap
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
            text: root.addLabel
            primary: true
            onClicked: root.submit()
        }
    }
}
