import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    // State via IPC
    property bool connected: false
    property int leftBattery: 0
    property int rightBattery: 0

    IpcClient {
        id: client
        target: "plugin:ear-x"
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            client.call("getStatus", [], (status) => {
                root.connected = status.connected;
                root.leftBattery = status.leftBattery;
                root.rightBattery = status.rightBattery;
            });
        }
    }

    readonly property real contentWidth: contentRow.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: Style.capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        radius: Style.radiusL

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Style.marginS
            opacity: root.connected ? 1.0 : 0.4

            NIcon {
                icon: "headphones"
                applyUiScale: false
                color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
            }

            NText {
                text: root.connected ? Math.max(root.leftBattery, root.rightBattery) + "%" : "Off"
                color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
                pointSize: Style.fontSizeS
                font.weight: Font.Medium
                applyUiScale: false
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (pluginApi) {
                pluginApi.openPanel(root.screen)
            }
        }
    }
}
