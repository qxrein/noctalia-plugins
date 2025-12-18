import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  readonly property int minutesToMillis: 60_000

  property int updateCount: 0
  property bool isInitialized: false

  readonly property int updateIntervalMinutes: pluginApi?.pluginSettings.updateIntervalMinutes || pluginApi?.manifest?.metadata.defaultSettings?.updateIntervalMinutes || 30
  readonly property string updateTerminalCommand: pluginApi?.pluginSettings.updateTerminalCommand || pluginApi?.manifest?.metadata.defaultSettings?.updateTerminalCommand || ""

  readonly property string customCmdGetNumUpdate: pluginApi?.pluginSettings.customCmdGetNumUpdate || ""
  readonly property string customCmdDoSystemUpdate: pluginApi?.pluginSettings.customCmdDoSystemUpdate || ""

  //
  // ------ Configuration ------
  //
  property bool hasCommandYay: false
  property bool hasCommandParu: false
  property bool hasCommandPacman: false
  property bool hasCommandDnf: false

  property var updater: [
    {
      key: "hasCommandYay",
      name: "yay",
      cmdCheck: "command -v yay >/dev/null 2>&1",
      cmdGetNumUpdates: "yay -Sy >/dev/null 2>&1; yay -Quq 2>/dev/null | wc -l",
      cmdDoSystemUpdate: "yay -Syu"
    },
    {
      key: "hasCommandParu",
      name: "paru",
      cmdCheck: "command -v paru >/dev/null 2>&1",
      cmdGetNumUpdates: "paru -Sy >/dev/null 2>&1; paru -Quq 2>/dev/null | wc -l",
      cmdDoSystemUpdate: "paru -Syu"
    },
    {
      // FIX: checkupdates is an additional package, pacman -Syu needs sudo. Don't know
      // what the best way here is. Currently, database would not be updated, which renders
      // the update function useless.
      //
      // cmdGetNumUpdates: "sudo pacman -Sy >/dev/null 2>&1; sudo pacman -Q 2>/dev/null | wc -l",
      key: "hasCommandPacman",
      name: "pacman",
      cmdCheck: "command -v pacman >/dev/null 2>&1",
      cmdGetNumUpdates: "pacman -Quq 2>/dev/null | wc -l",
      cmdDoSystemUpdate: "sudo pacman -Syu"
    },
    {
      key: "hasCommandDnf",
      name: "dnf",
      cmdCheck: "command -v dnf >/dev/null 2>&1",
      cmdGetNumUpdates: "dnf -q check-update --refresh 2>/dev/null | awk 'BEGIN{c=0} /^[[:alnum:]][^[:space:]]*[[:space:]]/ {c++} END{print c+0}'",
      cmdDoSystemUpdate: "sudo dnf upgrade -y --refresh"
    }
  ]

  //
  // ------ Initialization -----
  //
  Process {
    id: checkAvailableCommands

    command: ["sh", "-c", root.buildCommandCheckScript()]

    stdout: StdioCollector {
      onStreamFinished: {
        root.checkForUpdater(text);
      }
    }
  }

  function buildCommandCheckScript() {
    return updater.map(e => `${e.cmdCheck} && echo ${e.key}=1 || echo ${e.key}=0`).join("; ");
  }

  function checkForUpdater(text) {
    const tokens = text.trim().split(/\s+/);

    for (let i = 0; i < tokens.length; i++) {
      const parts = tokens[i].split("=");
      if (parts.length !== 2) { continue; }

      const key = parts[0];
      const present = (parts[1] === "1");
      root[key] = present;

      const entry = updater.find(e => e.key === key);
      const label = entry ? entry.name : key;

      if (present) {
        Logger.i("UpdateCount", `Detected command: ${label}.`);
      }
    }

    root.isInitialized = true

    Logger.i("UpdateCount", "Initialization finished.");
  }

  //
  // ------ Get number of updates ------
  //
  Timer {
    id: timerGetNumUpdates

    interval: root.updateIntervalMinutes * root.minutesToMillis
    running: root.isInitialized
    repeat: true
    onTriggered: function () {
      getNumUpdates.running = true;
    }
  }

  function findCmdGetNumUpdates() {
    if (root.customCmdGetNumUpdate !== "") { return root.customCmdGetNumUpdate; }

    for (let i = 0; i < root.updater.length; i++) {
      const e = root.updater[i];
      if (root[e.key] && e.cmdGetNumUpdates) {
        return e.cmdGetNumUpdates;
      }
    }
  }

  Process {
    id: getNumUpdates

    running: root.isInitialized
    command: ["sh", "-c", root.findCmdGetNumUpdates()]

    stdout: StdioCollector {
      onStreamFinished: {
        var count = parseInt(text.trim());
        root.updateCount = isNaN(count) ? 0 : count;
        Logger.i("UpdateCount", `Updates available: ${root.updateCount}`);
      }
    }
  }

  function startGetNumUpdates() {
    getNumUpdates.running = true;
  }

  //
  // ------ Start update ------
  //
  function findCmdDoSystemUpdate() {
    if (root.customCmdDoSystemUpdate != "") {
      return root.customCmdDoSystemUpdate;
    }

    for (let i = 0; i < root.updater.length; i++) {
      const e = root.updater[i];
      if (root[e.key] && e.cmdDoSystemUpdate) {
        return e.cmdDoSystemUpdate;
      }
    }
  }

  function startDoSystemUpdate() {
    const term = root.updateTerminalCommand.trim();
    const cmd  = root.findCmdDoSystemUpdate();

    const fullCmd = (term.indexOf("{}") !== -1) ? term.replace("{}", cmd) : term + " " + cmd;

    Quickshell.execDetached(["sh", "-c", fullCmd])
    Logger.i("UpdateCount", `Executed update command: ${fullCmd}`)
  }

  //
  // ------ Start ------
  //
  Component.onCompleted: {
    checkAvailableCommands.running = true;
  }
}
