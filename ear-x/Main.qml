import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null

    // State
    property bool connected: false
    property int leftBattery: 0
    property int rightBattery: 0
    property int caseBattery: 0
    property int ancMode: 0
    property int eqMode: 0

    // Process to run NothingCore.py
    Process {
        id: backend
        command: [
            "python3",
            Qt.resolvedUrl("NothingCore.py"),
            "--mock" // Default to mock mode for first run
        ]
        running: true

        onStdoutReceived: (line) => {
            try {
                let msg = JSON.parse(line);
                if (msg.type === "status") {
                    let data = msg.data;
                    root.connected = data.connected;
                    root.leftBattery = data.left_battery;
                    root.rightBattery = data.right_battery;
                    root.caseBattery = data.case_battery;
                    root.ancMode = data.anc_mode;
                    root.eqMode = data.eq_mode;
                } else if (msg.type === "log") {
                    console.log("[Ear X Backend]: " + msg.message);
                }
            } catch (e) {
                console.error("[Ear X Backend Parse Error]: " + e + " Line: " + line);
            }
        }
    }

    function sendCommand(type, value) {
        backend.write(JSON.stringify({type: type, value: value}) + "\n");
    }

    IpcHandler {
        target: "plugin:ear-x"
        
        function getStatus() {
            return {
                connected: root.connected,
                leftBattery: root.leftBattery,
                rightBattery: root.rightBattery,
                caseBattery: root.caseBattery,
                ancMode: root.ancMode,
                eqMode: root.eqMode
            };
        }

        function setAnc(mode) {
            sendCommand("set_anc", mode);
        }

        function setEq(mode) {
            sendCommand("set_eq", mode);
        }

        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen);
                });
            }
        }
    }

    Component.onCompleted: {
        // Initial refresh
        timer.start();
    }

    Timer {
        id: timer
        interval: 5000
        repeat: true
        onTriggered: sendCommand("refresh", 0)
    }
}
