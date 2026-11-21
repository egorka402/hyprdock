//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services
import qs.settings

// Hyprdock entry point. Run with:  qs -c hyprdock   (or:  hyprdock)
ShellRoot {
    // One dock per monitor.
    Variants {
        model: Quickshell.screens

        Dock {}
    }

    SettingsWindow {}

    // Control from the terminal:  hyprdock settings | hyprdock toggle
    IpcHandler {
        target: "hyprdock"

        function settings(): void {
            UiState.settingsOpen = true;
        }

        function toggle(): void {
            UiState.settingsOpen = !UiState.settingsOpen;
        }

        function close(): void {
            UiState.settingsOpen = false;
        }
    }
}
