import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "com.github.djkawada.razer-control"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property string ctlPath: Qt.resolvedUrl("bin/razer-ctl.py").toString().replace(/^file:\/\//, "")
  
  property string manualLang: ""
  readonly property string currentLang: {
    if (manualLang && (manualLang === "fr" || manualLang === "ja" || manualLang === "en")) return manualLang
    var loc = Qt.locale().name.toLowerCase()
    if (loc.startsWith("fr")) return "fr"
    if (loc.startsWith("ja") || loc.startsWith("jp")) return "ja"
    return "en"
  }

  readonly property var i18n: ({
    "fr": {
      "no_device": "Aucun périphérique",
      "connected_ready": "Connecté • Prêt",
      "disconnected": "Périphérique déconnecté",
      "not_connected": "Razer: Non connecté",
      "brightness": "Luminosité",
      "lighting_effects": "Effets lumineux",
      "static": "Statique",
      "breathing": "Respiration",
      "off": "Éteint",
      "game_mode_title": "Mode Gaming (Verrou Win)",
      "keyboard_locks": "Verrous Clavier",
      "caps": "[A] Caps",
      "num": "[1] Num",
      "scroll": "[S] ScrLk",
      "open_control_center": "Ouvrir Razer Control Center ↗",
      "active": "Actif",
      "inactive": "Inactif",
      "game_mode_tooltip": "Mode Gaming: Fn + F10",
      "num_tooltip": "Verr Num: ",
      "caps_tooltip": "Verr Maj: ",
      "scroll_hint": "Arrêt Défil n'a pas d'effet par défaut sous Linux et peut être assigné dans vos raccourcis Hyprland.",
      "lang_label": "Langue"
    },
    "ja": {
      "no_device": "デバイス未接続",
      "connected_ready": "接続完了 • 準備完了",
      "disconnected": "デバイス切断",
      "not_connected": "Razer: 未接続",
      "brightness": "輝度",
      "lighting_effects": "ライティング効果",
      "static": "スタティック",
      "breathing": "ブリージング",
      "off": "消灯",
      "game_mode_title": "ゲーミングモード (Winキー無効化)",
      "keyboard_locks": "キーボードロック＆LED",
      "caps": "[A] Caps",
      "num": "[1] Num",
      "scroll": "[S] ScrLk",
      "open_control_center": "Razer コントロールセンターを開く ↗",
      "active": "有効",
      "inactive": "無効",
      "game_mode_tooltip": "ゲーミングモード: Fn + F10",
      "num_tooltip": "Num Lock: ",
      "caps_tooltip": "Caps Lock: ",
      "scroll_hint": "Scroll LockはLinuxで標準機能がないため、Hyprlandで自由にショートカットを割り当て可能です。",
      "lang_label": "言語 (Language)"
    },
    "en": {
      "no_device": "No device connected",
      "connected_ready": "Connected • Ready",
      "disconnected": "Device disconnected",
      "not_connected": "Razer: Not connected",
      "brightness": "Brightness",
      "lighting_effects": "Lighting Effects",
      "static": "Static",
      "breathing": "Breathing",
      "off": "Off",
      "game_mode_title": "Gaming Mode (Win-Lock)",
      "keyboard_locks": "Keyboard Locks",
      "caps": "[A] Caps",
      "num": "[1] Num",
      "scroll": "[S] ScrLk",
      "open_control_center": "Open Razer Control Center ↗",
      "active": "Active",
      "inactive": "Inactive",
      "game_mode_tooltip": "Gaming Mode: Fn + F10",
      "num_tooltip": "Num Lock: ",
      "caps_tooltip": "Caps Lock: ",
      "scroll_hint": "Scroll Lock has no default action on Linux and can be assigned as a custom Hyprland shortcut.",
      "lang_label": "Language"
    }
  })

  function t(key) {
    var dict = i18n[currentLang] || i18n["en"]
    return dict[key] || key
  }

  property bool isConnected: false
  property string rawDeviceName: ""
  property string deviceName: isConnected ? (rawDeviceName || "Razer Device") : t("no_device")
  property int brightness: 255
  property string activeMode: "static"
  property bool gameMode: false
  property int pollingRate: 500
  property var capabilities: ({})
  property bool panelOpen: false

  // Lock key states
  property bool capsLock: false
  property bool numLock: true
  property bool scrollLock: false

  function close() {
    root.panelOpen = false
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  onPanelOpenChanged: {
    if (root.panelOpen) {
      root.refresh()
    }
  }

  function setBrightness(val) {
    brightness = val
    setBrightnessProc.command = [root.ctlPath, "set-brightness", String(val)]
    setBrightnessProc.running = true
  }

  function setMode(mode) {
    activeMode = mode
    setModeProc.command = [root.ctlPath, "set-mode", mode]
    setModeProc.running = true
  }

  function toggleGameMode() {
    gameMode = !gameMode
    setGameModeProc.command = [root.ctlPath, "set-game-mode", gameMode ? "on" : "off"]
    setGameModeProc.running = true
  }

  function setPollingRate(rate) {
    pollingRate = rate
    setPollingProc.command = [root.ctlPath, "set-polling", String(rate)]
    setPollingProc.running = true
  }

  function setLanguage(l) {
    root.manualLang = l
    setLangProc.command = [root.ctlPath, "set-lang", l]
    setLangProc.running = true
  }

  function toggleCaps() {
    toggleCapsProc.running = true
  }

  function toggleNum() {
    toggleNumProc.running = true
  }

  function toggleScroll() {
    toggleScrollProc.running = true
  }

  property bool controlCenterOpen: false

  function openControlCenter() {
    root.controlCenterOpen = true
  }

  function closeControlCenter() {
    root.controlCenterOpen = false
  }

  Loader {
    id: controlCenterLoader
    active: root.controlCenterOpen
    sourceComponent: Component {
      ControlCenterWindow {
        pluginRoot: root
        visible: true
        onClosing: root.closeControlCenter()
      }
    }
  }

  Component.onCompleted: refresh()

  // Real-time dynamic polling: fast (300ms) when open, background (3000ms) when closed
  Timer {
    interval: root.panelOpen ? 300 : 3000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  // --- Backend Process Handlers ---
  Process {
    id: statusProc
    command: [root.ctlPath, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text || "{}")
          root.isConnected = Boolean(data.connected)
          if (data.active_device) {
            root.rawDeviceName = data.active_device.name || "Razer Device"
            root.capabilities = data.active_device.capabilities || {}
          } else {
            root.rawDeviceName = ""
            root.capabilities = {}
          }
          if (data.state) {
            root.brightness = data.state.brightness !== undefined ? data.state.brightness : 255
            root.activeMode = data.state.mode || "static"
            root.gameMode = Boolean(data.state.game_mode)
            root.pollingRate = data.state.polling_rate || 500
            if (data.state.lang) {
              root.manualLang = data.state.lang
            }
          }
          if (data.locks) {
            root.capsLock = Boolean(data.locks.caps_lock)
            root.numLock = Boolean(data.locks.num_lock)
            root.scrollLock = Boolean(data.locks.scroll_lock)
          }
        } catch (e) {}
      }
    }
  }

  Process { id: setBrightnessProc }
  Process { id: setModeProc }
  Process { id: setGameModeProc }
  Process { id: setPollingProc }
  Process { id: setLangProc }

  Process {
    id: toggleCapsProc
    command: [root.ctlPath, "toggle-caps"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.refresh()
    }
  }

  Process {
    id: toggleNumProc
    command: [root.ctlPath, "toggle-num"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.refresh()
    }
  }

  Process {
    id: toggleScrollProc
    command: [root.ctlPath, "toggle-scroll"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.refresh()
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: root.isConnected ? (root.deviceName + "\n" + root.t("num_tooltip") + (root.numLock ? root.t("active") : root.t("inactive")) + "\n" + root.t("caps_tooltip") + (root.capsLock ? root.t("active") : root.t("inactive")) + (root.capabilities.hardware_game_mode ? "\n" + root.t("game_mode_tooltip") : "")) : root.t("not_connected")

    iconComponent: Component {
      Item {
        anchors.fill: parent

        Image {
          anchors.centerIn: parent
          source: Qt.resolvedUrl("assets/razer.svg")
          sourceSize.width: Style.space(16)
          sourceSize.height: Style.space(16)
          opacity: root.isConnected ? 1.0 : 0.35
        }

        Rectangle {
          visible: root.isConnected && root.gameMode
          width: Style.space(5)
          height: Style.space(5)
          radius: Style.space(2.5)
          color: "#00ff66"
          anchors.right: parent.right
          anchors.bottom: parent.bottom
        }
      }
    }

    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.openControlCenter()
      } else {
        root.panelOpen = !root.panelOpen
      }
    }
  }

  // --- Flyout Popup Panel ---
  PopupCard {
    id: popupPanel
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.panelOpen
    contentWidth: popupPanel.fittedContentWidth(Style.space(320))
    contentHeight: popupPanel.fittedContentHeight(contentColumn.implicitHeight)

    Column {
      id: contentColumn
      anchors.fill: parent
      spacing: Style.space(10)

      // Header
      Row {
        spacing: Style.space(8)
        width: parent.width

        Image {
          source: Qt.resolvedUrl("assets/razer.svg")
          sourceSize.width: Style.space(22)
          sourceSize.height: Style.space(22)
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          spacing: Style.space(2)
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Style.space(30)

          Text {
            text: root.deviceName
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
            color: root.isConnected ? Color.foreground : Color.muted
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            text: root.isConnected ? root.t("connected_ready") : root.t("disconnected")
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            color: root.isConnected ? "#00e756" : Color.muted
          }
        }
      }

      PanelSeparator {}

      // Brightness (only for backlit models)
      Column {
        width: parent.width
        spacing: Style.space(4)
        visible: Boolean(root.capabilities.brightness === true)

        Row {
          width: parent.width
          Text {
            text: root.t("brightness")
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            color: Color.muted
          }
          Item {
            width: parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth
            height: 1
          }
          Text {
            text: Math.round((root.brightness / 255) * 100) + "%"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            color: "#00e756"
          }
        }

        PanelSlider {
          bar: root.bar
          width: parent.width
          minimum: 0
          maximum: 255
          value: root.brightness
          integer: true
          onMoved: function(v) { root.setBrightness(Math.round(v)) }
        }
      }

      // Modes (only for models with lighting modes)
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: Boolean(root.capabilities.modes && root.capabilities.modes.length > 0)

        PanelSectionHeader {
          text: root.t("lighting_effects")
        }

        Row {
          width: parent.width
          spacing: Style.space(6)

          Button {
            text: root.t("static")
            selected: root.activeMode === "static"
            width: (parent.width - Style.space(12)) / 3
            onClicked: root.setMode("static")
          }
          Button {
            text: root.t("breathing")
            selected: root.activeMode === "breathing"
            width: (parent.width - Style.space(12)) / 3
            onClicked: root.setMode("breathing")
          }
          Button {
            text: root.t("off")
            selected: root.activeMode === "off"
            width: (parent.width - Style.space(12)) / 3
            onClicked: root.setMode("off")
          }
        }
      }

      // Gaming Mode Section
      Column {
        width: parent.width
        spacing: Style.space(4)
        visible: Boolean(root.capabilities.game_mode === true)

        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            text: root.t("game_mode_title")
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Color.foreground
            anchors.verticalCenter: parent.verticalCenter
          }

          Item {
            width: Math.max(8, parent.width - parent.children[0].implicitWidth - (tagText.visible ? tagText.implicitWidth : switchLoader.implicitWidth) - Style.space(16))
            height: 1
          }

          Text {
            id: tagText
            visible: Boolean(root.capabilities.hardware_game_mode)
            text: "Fn + F10"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            color: "#00e756"
            anchors.verticalCenter: parent.verticalCenter
          }

          ToggleSwitch {
            id: switchLoader
            visible: !root.capabilities.hardware_game_mode
            checked: root.gameMode
            anchors.verticalCenter: parent.verticalCenter
            onToggled: root.toggleGameMode()
          }
        }
      }

      // Lock Keys Section
      Column {
        width: parent.width
        spacing: Style.space(6)

        PanelSectionHeader {
          text: root.t("keyboard_locks")
        }

        Row {
          width: parent.width
          spacing: Style.space(6)

          Button {
            text: root.t("caps") + (root.capsLock ? ": ON" : ": OFF")
            selected: root.capsLock
            width: (parent.width - Style.space(12)) / 3
            onClicked: root.toggleCaps()
          }

          Button {
            text: root.t("num") + (root.numLock ? ": ON" : ": OFF")
            selected: root.numLock
            width: (parent.width - Style.space(12)) / 3
            onClicked: root.toggleNum()
          }

          Button {
            text: root.t("scroll") + (root.scrollLock ? ": ON" : ": OFF")
            selected: root.scrollLock
            width: (parent.width - Style.space(12)) / 3
            onClicked: root.toggleScroll()
          }
        }

        Text {
          text: root.t("scroll_hint")
          font.family: Style.font.family
          font.pixelSize: Style.font.caption - 1
          color: Color.muted
          wrapMode: Text.WordWrap
          width: parent.width
          opacity: 0.8
        }
      }

      // Language Switcher Row
      Row {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: root.t("lang_label")
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          color: Color.muted
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          width: Math.max(4, parent.width - parent.children[0].implicitWidth - (3 * Style.space(42) + 2 * Style.space(6)) - Style.space(10))
          height: 1
        }

        Button {
          text: "FR"
          selected: root.currentLang === "fr"
          width: Style.space(42)
          onClicked: root.setLanguage("fr")
        }
        Button {
          text: "EN"
          selected: root.currentLang === "en"
          width: Style.space(42)
          onClicked: root.setLanguage("en")
        }
        Button {
          text: "JA"
          selected: root.currentLang === "ja"
          width: Style.space(42)
          onClicked: root.setLanguage("ja")
        }
      }

      PanelSeparator {}

      // Action Button
      Button {
        width: parent.width
        text: root.t("open_control_center")
        bordered: true
        onClicked: {
          root.panelOpen = false
          root.openControlCenter()
        }
      }
    }
  }
}
