import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    
    readonly property bool active: 
        pluginApi.pluginSettings.active || 
        false

    icon: "wallpaper-selector"

    onClicked: {
        pluginApi?.openPanel(root.screen, root);
    }

    onRightClicked: {
        PanelService.showContextMenu(contextMenu, root, screen);
    }
    
    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": pluginApi?.tr("barWidget.contextMenu.panel") || "Panel",
                "action": "panel",
                "icon": "rectangle"
            },
            {
                "label": pluginApi?.tr("barWidget.contextMenu.toggle") || "Toggle",
                "action": "toggle",
                "icon": "power"
            }
        ]

        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);

            if(action === "panel") {
                pluginApi?.openPanel(root.screen, root);
            } else if (action === "toggle") {
                pluginApi.pluginSettings.active = !root.active;
                pluginApi.saveSettings();
            }
        }
    }
}
