import QtQuick
import Quickshell
import qs.services

// Draws the icon of one dock entry.
// Order: custom icon (path or theme name) -> site favicon -> letter tile.
Item {
    id: root

    property var item: ({})

    readonly property string iconStr: root.item && root.item.icon ? String(root.item.icon) : ""
    readonly property string name: root.item && root.item.name ? String(root.item.name) : "?"

    function hostOf(url) {
        return String(url || "").replace(/^[a-zA-Z]+:\/\//, "").split("/")[0];
    }

    readonly property string src: {
        if (root.iconStr.length > 0) {
            if (root.iconStr.indexOf("/") === 0)
                return "file://" + root.iconStr;
            if (root.iconStr.indexOf("file://") === 0 || root.iconStr.indexOf("http") === 0)
                return root.iconStr;
            return Quickshell.iconPath(root.iconStr, true);
        }
        if (root.item && root.item.kind === "site" && Config.onlineIcons && root.item.url)
            return "https://www.google.com/s2/favicons?sz=128&domain=" + root.hostOf(root.item.url);
        return "";
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.src
        sourceSize: Qt.size(256, 256)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
        visible: status === Image.Ready
    }

    // Fallback: rounded tile with the first letter.
    Rectangle {
        anchors.fill: parent
        visible: img.status !== Image.Ready
        radius: width * 0.26
        color: Theme.surfaceHi
        border.width: 1
        border.color: Theme.line

        Text {
            anchors.centerIn: parent
            text: root.name.charAt(0).toUpperCase()
            color: Theme.accent
            font.family: Theme.font
            font.bold: true
            font.pixelSize: parent.width * 0.5
        }
    }
}
