pragma Singleton

import QtQuick
import Quickshell

// Starts apps and opens sites.
Singleton {
    id: root

    // Always start a new instance.
    function launch(item) {
        if (item.kind === "site") {
            const browser = (item.browser && item.browser.length > 0) ? Array.from(item.browser) : ["xdg-open"];
            Quickshell.execDetached(browser.concat([item.url]));
            return;
        }
        if (item.id) {
            const entry = DesktopEntries.byId(item.id);
            if (entry) {
                entry.execute();
                return;
            }
        }
        if (item.cmd && item.cmd.length > 0)
            Quickshell.execDetached(Array.from(item.cmd));
    }

    // Left click: focus the app if it is already running, otherwise start it.
    function activate(item) {
        if (item.kind === "app" && item.wmClass && Hypr.isRunning(item.wmClass))
            Hypr.focusClass(item.wmClass);
        else
            root.launch(item);
    }
}
