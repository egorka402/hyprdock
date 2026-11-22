pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings, stored in ~/.config/hyprdock/config.json.
// Changes made in the settings window are applied live and saved automatically.
Singleton {
    id: root

    readonly property string configDir: Quickshell.env("HOME") + "/.config/hyprdock"

    // Values (read them from anywhere: Config.radius, Config.items, ...)
    readonly property int radius: store.radius        // 0..100
    readonly property int size: store.size            // 0..100
    readonly property int spacing: store.spacing      // 0..100
    readonly property int bgOpacity: store.bgOpacity  // 0 (invisible) .. 100 (solid)
    readonly property string border: store.border === "light" ? "light" : "dark"     // dark | light
    readonly property string hide: store.hide         // never | auto
    readonly property bool onlineIcons: store.onlineIcons
    readonly property var items: root.normalizeItems(store.items)

    // The list read from the JSON file may not be a "real" JS array (it can be an array-like wrapper),
    // so never rely on Array.isArray here. Copy every entry into plain JS objects instead.
    function normalizeItems(raw) {
        if (raw === undefined || raw === null)
            return [];
        try {
            return Array.from(raw).map(x => JSON.parse(JSON.stringify(x))).filter(x => x && typeof x === "object");
        } catch (e) {
            console.warn("hyprdock: could not read items from config: " + e);
            return [];
        }
    }

    function setValue(key, value) {
        store[key] = value;
    }

    // Every item gets a permanent number (uid). The dock uses it to recognise an icon
    // after the order changes, so the icon can slide to its new place instead of being redrawn.
    readonly property var uids: root.items.map(i => i.uid).filter(u => typeof u === "number").sort((a, b) => a - b)

    function itemByUid(uid) {
        for (const it of root.items) {
            if (it.uid === uid)
                return it;
        }
        return ({});
    }

    function indexOfUid(uid) {
        return root.items.findIndex(it => it.uid === uid);
    }

    function nextUid() {
        let max = 0;
        for (const it of root.items) {
            if (typeof it.uid === "number")
                max = Math.max(max, it.uid);
        }
        return max + 1;
    }

    // Add several items with a single save.
    function addItems(newItems) {
        const list = root.items.slice();
        let uid = root.nextUid();
        for (const it of newItems) {
            it.uid = uid++;
            list.push(it);
        }
        store.items = list;
    }

    function addItem(item) {
        root.addItems([item]);
    }

    function removeItem(index) {
        const list = root.items.slice();
        list.splice(index, 1);
        store.items = list;
    }

    function moveItem(index, delta) {
        const target = index + delta;
        const list = root.items.slice();
        if (target < 0 || target >= list.length)
            return;
        const tmp = list[index];
        list[index] = list[target];
        list[target] = tmp;
        store.items = list;
    }

    // Save a moment after the last change (so dragging a slider doesn't spam the disk).
    Timer {
        id: saveTimer
        interval: 300
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file
        path: root.configDir + "/config.json"
        watchChanges: false
        atomicWrites: true
        printErrors: false

        onAdapterUpdated: saveTimer.restart()

        // Older/hand-written configs may have items without a uid: number them.
        onLoaded: {
            // Shows up in `hyprdock logs`: helps to find problems with saved items.
            console.log("hyprdock: config loaded from " + file.path + ", items in file: " + root.items.length);
            const list = root.items.slice();
            let max = 0;
            for (const it of list) {
                if (typeof it.uid === "number")
                    max = Math.max(max, it.uid);
            }
            let changed = false;
            for (const it of list) {
                if (typeof it.uid !== "number") {
                    it.uid = ++max;
                    changed = true;
                }
            }
            if (changed)
                store.items = list;
        }
        onLoadFailed: error => {
            // First start: no config yet, create one with defaults.
            if (error == FileViewError.FileNotFound)
                file.writeAdapter();
        }

        adapter: JsonAdapter {
            id: store
            property int radius: 60
            property int size: 40
            property int spacing: 30
            property int bgOpacity: 80
            property string border: "dark"
            property string hide: "never"
            property bool onlineIcons: true
            property var items: []
        }
    }
}
