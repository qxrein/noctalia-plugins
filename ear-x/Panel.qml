import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Services.UI
import qs.UI
import qs.Commons

Item {
    id: panel
    implicitWidth: 400
    implicitHeight: 600

    property var pluginApi: null

    // State
    property bool connected: false
    property int leftBattery: 0
    property int rightBattery: 0
    property int caseBattery: 0
    property int ancMode: 0
    property int eqMode: 0

    IpcClient {
        id: client
        target: "plugin:ear-x"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            client.call("getStatus", [], (status) => {
                panel.connected = status.connected;
                panel.leftBattery = status.leftBattery;
                panel.rightBattery = status.rightBattery;
                panel.caseBattery = status.caseBattery;
                panel.ancMode = status.ancMode;
                panel.eqMode = status.eqMode;
            });
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0F0F0F"
        radius: 20
        clip: true
        border.color: "#222"
        border.width: 1

        // Header
        Rectangle {
            id: header
            width: parent.width
            height: 70
            color: "#161616"
            
            Text {
                text: "Ear (x)"
                color: "white"
                font.pixelSize: 22
                font.weight: Font.DemiBold
                anchors.centerIn: parent
                font.family: "Inter"
            }

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: panel.connected ? "#00E676" : "#FF5252"
                anchors.right: parent.right
                anchors.rightMargin: 25
                anchors.verticalCenter: parent.verticalCenter
                
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: !panel.connected
                    NumberAnimation { from: 1; to: 0.2; duration: 800 }
                    NumberAnimation { from: 0.2; to: 1; duration: 800 }
                }
            }
        }

        ColumnLayout {
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 25
            spacing: 35

            // Earbuds Display (Premium visual)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                spacing: 15

                // Left
                ColumnLayout {
                    spacing: 10
                    Image {
                        source: Qt.resolvedUrl("assets/left.webp")
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 140
                        fillMode: Image.PreserveAspectFit
                        opacity: panel.leftBattery > 0 ? 1 : 0.3
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                    Text {
                        text: panel.leftBattery + "%"
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 15
                        font.weight: Font.Medium
                    }
                }

                // Case
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 12
                    Image {
                        source: Qt.resolvedUrl("assets/case.webp")
                        Layout.preferredWidth: 130
                        Layout.preferredHeight: 180
                        fillMode: Image.PreserveAspectFit
                        opacity: panel.caseBattery > 0 ? 1 : 0.3
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                    Text {
                        text: panel.caseBattery + "%"
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 15
                        font.weight: Font.Medium
                    }
                }

                // Right
                ColumnLayout {
                    spacing: 10
                    Image {
                        source: Qt.resolvedUrl("assets/right.webp")
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 140
                        fillMode: Image.PreserveAspectFit
                        opacity: panel.rightBattery > 0 ? 1 : 0.3
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                    Text {
                        text: panel.rightBattery + "%"
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 15
                        font.weight: Font.Medium
                    }
                }
            }

            // ANC Modes
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 15
                Text {
                    text: "NOISE CONTROL"
                    color: "#666"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    Layout.leftMargin: 5
                }

                RowLayout {
                    spacing: 12
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { name: "ANC", icon: "anc_on.svg", val: 1 },
                            { name: "Off", icon: "anc_off.svg", val: 0 },
                            { name: "Trans", icon: "anc_transparent.svg", val: 2 }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            color: panel.ancMode === modelData.val ? "#222" : "#161616"
                            radius: 12
                            border.color: panel.ancMode === modelData.val ? "#444" : "transparent"
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Image {
                                    source: Qt.resolvedUrl("assets/" + modelData.icon)
                                    sourceSize: Qt.size(20, 20)
                                    opacity: panel.ancMode === modelData.val ? 1 : 0.5
                                }
                                Text {
                                    text: modelData.name
                                    color: panel.ancMode === modelData.val ? "white" : "#888"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: client.call("setAnc", [modelData.val])
                            }
                        }
                    }
                }
            }

            // EQ Profiles
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 15
                Text {
                    text: "EQUALIZER"
                    color: "#666"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    Layout.leftMargin: 5
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 12
                    Repeater {
                        model: ["Balanced", "More Bass", "More Treble", "Voice"]
                        delegate: Rectangle {
                            width: (parent.width - 12) / 2
                            height: 45
                            color: panel.eqMode === index ? "#A9AEFE" : "#161616"
                            radius: 12
                            
                            Text {
                                text: modelData
                                color: panel.eqMode === index ? "black" : "white"
                                anchors.centerIn: parent
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: client.call("setEq", [index])
                            }
                        }
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
        }
    }
}
