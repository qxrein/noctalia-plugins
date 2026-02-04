import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.UI

Item {
    id: root
    implicitWidth: content.width + 16
    implicitHeight: 32

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

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 6

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 8
            opacity: root.connected ? 1.0 : 0.4

            // Small Nothing earbud icon dot
            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: root.connected ? "white" : "#555"
                border.color: "#333"
                border.width: 1
                
                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: "black"
                }
            }

            Text {
                text: root.connected ? Math.max(root.leftBattery, root.rightBattery) + "%" : "Off"
                color: "white"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: "Inter"
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: client.call("toggle", [])
        }
    }
}
