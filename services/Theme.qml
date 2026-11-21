pragma Singleton

import QtQuick
import Quickshell

// Colors and font used everywhere. Minimal dark palette with one accent.
Singleton {
    readonly property string font: "JetBrains Mono"

    // Dock background color (its opacity comes from the settings slider)
    readonly property color panelBase: "#1a1b26"
    readonly property color surface: "#1f2335"
    readonly property color surfaceHi: "#2a2f45"
    readonly property color line: "#33384f"
    readonly property color text: "#c0caf5"
    readonly property color dim: "#7a82a8"
    readonly property color accent: "#7aa2f7"
    readonly property color danger: "#f7768e"
}
