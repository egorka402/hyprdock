pragma Singleton

import QtQuick
import Quickshell

// Starts apps and opens sites.
Singleton {
    id: root

    // Find a "new window" action in the app's .desktop file (Firefox has one, for example).
    function newWindowAction(entry) {
        try {
            for (let i = 0; i < entry.actions.length; i++) {
                const a = entry.actions[i];
                if (/new[-_ ]?(os[-_ ]?)?(window|instance)/i.test(a.id) && !/private|incognito/i.test(a.id))
                    return a;
            }
        } catch (e) {
            // no actions available: fall back to the normal launch
        }
        return null;
    }

    // Start the app normally.
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

    // Open another window of an app that may already be running.
    // Uses the app's own "new window" action when it has one, otherwise just starts it again.
    // (Some apps, like Telegram, only ever allow one window: starting them again just shows the existing one.)
    function launchNew(item) {
        if (item.kind === "app" && item.id) {
            const entry = DesktopEntries.byId(item.id);
            if (entry) {
                const action = root.newWindowAction(entry);
                if (action) {
                    action.execute();
                    return;
                }
                entry.execute();
                return;
            }
        }
        root.launch(item);
    }

    // Left click. For a running app: focus it, or open a new window (setting "runningClick").
    function activate(item) {
        if (item.kind === "app" && item.wmClass && Hypr.isRunning(item.wmClass)) {
            if (Config.runningClick === "new")
                root.launchNew(item);
            else
                Hypr.focusClass(item.wmClass);
        } else {
            root.launch(item);
        }
    }
}
