pragma Singleton

import QtQuick
import Quickshell

// Tiny shared state: is the settings window open?
Singleton {
    property bool settingsOpen: false
}
