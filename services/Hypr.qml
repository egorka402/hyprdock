pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Asks Hyprland (via hyprctl) which windows are open.
// Used for: auto-hide logic and the "running" dot under icons.
Singleton {
    id: root

    property var clients: []
    property var monitors: []
    // lowercase window class -> real window class
    property var classMap: ({})

    // Is there a visible window on the active workspace of this monitor?
    function windowOpenOn(screenName) {
        let mon = null;
        for (const m of root.monitors) {
            if (m.name === screenName) {
                mon = m;
                break;
            }
        }
        if (!mon)
            return false;
        const ws = mon.activeWorkspace ? mon.activeWorkspace.id : -999;
        for (const c of root.clients) {
            if (c.mapped && !c.hidden && c.monitor === mon.id && c.workspace && c.workspace.id === ws)
                return true;
        }
        return false;
    }

    function isRunning(cls) {
        return !!cls && root.classMap[cls.toLowerCase()] !== undefined;
    }

    function focusClass(cls) {
        const real = root.classMap[cls.toLowerCase()];
        if (real === undefined)
            return;
        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "class:^(" + real + ")$"]);
    }

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    function parse(text) {
        const parts = text.split("\n@@@\n");
        try {
            const clients = JSON.parse(parts[0]);
            const monitors = JSON.parse(parts[1]);
            const map = {};
            for (const c of clients) {
                if (c.class && c.mapped)
                    map[c.class.toLowerCase()] = c.class;
            }
            root.clients = clients;
            root.monitors = monitors;
            root.classMap = map;
        } catch (e) {
            // hyprctl not ready yet, try again on the next event
        }
    }

    Process {
        id: proc
        command: ["sh", "-c", "hyprctl -j clients; printf '\\n@@@\\n'; hyprctl -j monitors"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    // Any Hyprland event (window opened/closed/moved, workspace changed...) -> refresh shortly after.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            debounce.restart();
        }
    }

    Timer {
        id: debounce
        interval: 120
        onTriggered: root.refresh()
    }

    // Safety net in case an event was missed.
    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
