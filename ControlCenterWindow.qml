import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import qs.Commons as Commons

FloatingWindow {
  id: rootWindow
  title: "Razer Control Center"
  color: Commons.Color.background
  implicitWidth: Style.space(1020)
  implicitHeight: Style.space(720)
  minimumSize: Qt.size(Style.space(860), Style.space(600))

  property var pluginRoot: null
  signal closing()

  readonly property string currentLang: pluginRoot ? pluginRoot.currentLang : "en"
  function t(key) { return pluginRoot ? pluginRoot.t(key) : key }

  function requestClose() {
    rootWindow.visible = false
    rootWindow.closing()
  }

  onVisibleChanged: {
    if (!visible) {
      rootWindow.closing()
    }
  }

  // Keyboard Tester State
  property var activeKeySet: ({})
  property int activeKeyCount: 0
  property int maxKro: 0
  property string lastKeyName: "—"
  property var testedKeySet: ({})

  // Console Logs
  property var logEntries: []

  function addLog(msg, type) {
    var time = Qt.formatTime(new Date(), "hh:mm:ss")
    var entry = "[" + time + "] " + msg
    var arr = rootWindow.logEntries.slice(0, 100)
    arr.unshift({ text: entry, type: type || "info" })
    rootWindow.logEntries = arr
  }

  function resetTester() {
    activeKeySet = {}
    activeKeyCount = 0
    maxKro = 0
    lastKeyName = "—"
    testedKeySet = {}
    addLog(currentLang === "fr" ? "Testeur de matrice réinitialisé." : (currentLang === "ja" ? "キーマトリクステストをリセットしました。" : "Key matrix tester reset."), "info")
  }

  Component.onCompleted: {
    addLog(currentLang === "fr" ? "Razer Control Center prêt (Moteur Quickshell natif)." : (currentLang === "ja" ? "Razer コントロールセンター (Quickshellネイティブ) 準備完了。" : "Razer Control Center ready (Native Quickshell engine)."), "ok")
  }

  FocusScope {
    id: windowFocusScope
    anchors.fill: parent
    focus: true

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape && !event.isAutoRepeat) {
        if (rootWindow.activeKeyCount === 0) {
          rootWindow.requestClose()
          event.accepted = true
          return
        }
      }

      var kCode = event.key
      var keyId = event.nativeScanCode ? ("SCAN_" + event.nativeScanCode) : ("KEY_" + kCode)

      var newActive = Object.assign({}, rootWindow.activeKeySet)
      newActive[keyId] = true
      rootWindow.activeKeySet = newActive

      var newTested = Object.assign({}, rootWindow.testedKeySet)
      newTested[keyId] = true
      rootWindow.testedKeySet = newTested

      var count = Object.keys(newActive).length
      rootWindow.activeKeyCount = count
      if (count > rootWindow.maxKro) rootWindow.maxKro = count

      rootWindow.lastKeyName = event.text ? ("'" + event.text + "' (0x" + kCode.toString(16).toUpperCase() + ")") : ("KEY_0x" + kCode.toString(16).toUpperCase())

      if (pluginRoot) pluginRoot.refresh()
    }

    Keys.onReleased: function(event) {
      var kCode = event.key
      var keyId = event.nativeScanCode ? ("SCAN_" + event.nativeScanCode) : ("KEY_" + kCode)
      var newActive = Object.assign({}, rootWindow.activeKeySet)
      delete newActive[keyId]
      rootWindow.activeKeySet = newActive
      rootWindow.activeKeyCount = Object.keys(newActive).length

      if (pluginRoot) pluginRoot.refresh()
    }

    // --- Window Root Container ---
    Item {
      anchors.fill: parent
      anchors.margins: Style.space(16)

      // --- Header Row ---
      Item {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(48)

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(12)

          Image {
            source: Qt.resolvedUrl("assets/razer.svg")
            sourceSize.width: Style.space(32)
            sourceSize.height: Style.space(32)
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            spacing: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter

            Text {
              text: rootWindow.pluginRoot ? rootWindow.pluginRoot.deviceName : "Razer Device"
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: (rootWindow.pluginRoot && rootWindow.pluginRoot.isConnected) ? (rootWindow.t("connected_ready") + " • " + (rootWindow.currentLang === "fr" ? "Moteur Matériel Quickshell" : (rootWindow.currentLang === "ja" ? "Quickshell ネイティブ制御" : "Native Quickshell Engine"))) : rootWindow.t("disconnected")
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              color: (rootWindow.pluginRoot && rootWindow.pluginRoot.isConnected) ? "#00e756" : Commons.Color.muted
            }
          }
        }

        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)

          // Language Switcher
          Rectangle {
            color: "#1a202c"
            radius: 6
            border.color: "#2d3748"
            border.width: 1
            width: langRowLayout.implicitWidth + Style.space(6)
            height: Style.space(34)
            anchors.verticalCenter: parent.verticalCenter

            Row {
              id: langRowLayout
              anchors.centerIn: parent
              spacing: Style.space(4)

              Button {
                text: "FR"
                selected: rootWindow.currentLang === "fr"
                width: Style.space(36)
                onClicked: if (rootWindow.pluginRoot) rootWindow.pluginRoot.setLanguage("fr")
              }
              Button {
                text: "EN"
                selected: rootWindow.currentLang === "en"
                width: Style.space(36)
                onClicked: if (rootWindow.pluginRoot) rootWindow.pluginRoot.setLanguage("en")
              }
              Button {
                text: "JA"
                selected: rootWindow.currentLang === "ja"
                width: Style.space(36)
                onClicked: if (rootWindow.pluginRoot) rootWindow.pluginRoot.setLanguage("ja")
              }
            }
          }

          // Close Button
          Button {
            text: "✕"
            width: Style.space(36)
            height: Style.space(34)
            anchors.verticalCenter: parent.verticalCenter
            onClicked: rootWindow.requestClose()
          }
        }
      }

      Rectangle {
        id: headerSep
        anchors.top: headerRow.bottom
        anchors.topMargin: Style.space(8)
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#2d3748"
      }

      // --- Main Dual-Panel Content Area ---
      Item {
        id: contentArea
        anchors.top: headerSep.bottom
        anchors.topMargin: Style.space(12)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // ==========================================
        // LEFT COLUMN: Controls & Settings
        // ==========================================
        ScrollView {
          id: leftScrollView
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          width: (contentArea.width - Style.space(16)) * 0.44
          clip: true
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

          Column {
            width: leftScrollView.availableWidth
            spacing: Style.space(12)

            // Backlight Card (only for backlit models)
            Rectangle {
              visible: Boolean(rootWindow.pluginRoot && rootWindow.pluginRoot.capabilities.brightness === true)
              width: parent.width
              color: "#151b23"
              radius: 8
              border.color: "#2d3748"
              border.width: 1
              implicitHeight: backlightCol.implicitHeight + Style.space(24)

              Column {
                id: backlightCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(12)
                spacing: Style.space(8)

                PanelSectionHeader { text: rootWindow.t("brightness") }

                Row {
                  width: parent.width
                  Text {
                    text: rootWindow.t("brightness") + " (" + Math.round(((rootWindow.pluginRoot ? rootWindow.pluginRoot.brightness : 255) / 255) * 100) + "%)"
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                    color: Commons.Color.muted
                  }
                }

                PanelSlider {
                  width: parent.width
                  minimum: 0
                  maximum: 255
                  value: rootWindow.pluginRoot ? rootWindow.pluginRoot.brightness : 255
                  integer: true
                  onMoved: function(v) { if (rootWindow.pluginRoot) rootWindow.pluginRoot.setBrightness(Math.round(v)) }
                }

                PanelSectionHeader { text: rootWindow.t("lighting_effects") }

                Row {
                  width: parent.width
                  spacing: Style.space(6)
                  Button {
                    text: rootWindow.t("static")
                    selected: rootWindow.pluginRoot && rootWindow.pluginRoot.activeMode === "static"
                    width: (parent.width - Style.space(12)) / 3
                    onClicked: if (rootWindow.pluginRoot) rootWindow.pluginRoot.setMode("static")
                  }
                  Button {
                    text: rootWindow.t("breathing")
                    selected: rootWindow.pluginRoot && rootWindow.pluginRoot.activeMode === "breathing"
                    width: (parent.width - Style.space(12)) / 3
                    onClicked: if (rootWindow.pluginRoot) rootWindow.pluginRoot.setMode("breathing")
                  }
                  Button {
                    text: rootWindow.t("off")
                    selected: rootWindow.pluginRoot && rootWindow.pluginRoot.activeMode === "off"
                    width: (parent.width - Style.space(12)) / 3
                    onClicked: if (rootWindow.pluginRoot) rootWindow.pluginRoot.setMode("off")
                  }
                }
              }
            }

            // Gaming Mode Card
            Rectangle {
              width: parent.width
              color: "#151b23"
              radius: 8
              border.color: "#2d3748"
              border.width: 1
              implicitHeight: gamingCol.implicitHeight + Style.space(24)

              Column {
                id: gamingCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(12)
                spacing: Style.space(8)

                PanelSectionHeader { text: rootWindow.t("game_mode_title") }

                Rectangle {
                  width: parent.width
                  height: Style.space(48)
                  color: "#0d2818"
                  radius: 6
                  border.color: "#00e756"
                  border.width: 1

                  Item {
                    anchors.fill: parent
                    anchors.margins: Style.space(10)

                    Column {
                      anchors.left: parent.left
                      anchors.verticalCenter: parent.verticalCenter
                      Text {
                        text: rootWindow.currentLang === "fr" ? "Contrôle Matériel Autonome" : (rootWindow.currentLang === "ja" ? "ハードウェア自動制御" : "Hardware Managed")
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        color: "#00e756"
                      }
                      Text {
                        text: rootWindow.currentLang === "fr" ? "Géré par le microprogramme • LED [G]" : (rootWindow.currentLang === "ja" ? "ファームウェア内部制御 • [G] LED点灯" : "Handled by firmware • [G] LED")
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption - 1
                        color: Commons.Color.muted
                      }
                    }

                    Rectangle {
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      width: Style.space(76)
                      height: Style.space(26)
                      color: "#101315"
                      radius: 4
                      border.color: "#00e756"
                      border.width: 1

                      Text {
                        anchors.centerIn: parent
                        text: "Fn + F10"
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        color: "#00ff66"
                      }
                    }
                  }
                }
              }
            }

            // Macro Mode OTF Guide Card
            Rectangle {
              width: parent.width
              color: "#151b23"
              radius: 8
              border.color: "#2d3748"
              border.width: 1
              implicitHeight: macroCol.implicitHeight + Style.space(24)

              Column {
                id: macroCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(12)
                spacing: Style.space(8)

                Item {
                  width: parent.width
                  height: Style.space(22)

                  PanelSectionHeader {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: rootWindow.currentLang === "fr" ? "Mode Macro [M] • Enregistrement OTF" : (rootWindow.currentLang === "ja" ? "マクロモード [M] • OTF記録" : "Macro Mode [M] • OTF Recording")
                  }

                  Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Fn + F9"
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    color: "#00e756"
                  }
                }

                Text {
                  text: rootWindow.currentLang === "fr" ? "1. Appuyer sur Fn + F9 (la LED [M] clignote lentement)\n2. Saisir la séquence de touches souhaitée\n3. Réappuyer sur Fn + F9 (la LED [M] clignote vite)\n4. Appuyer sur la touche de destination pour assigner\n(Échap pour annuler à tout moment)" : (rootWindow.currentLang === "ja" ? "1. Fn + F9 を押す（[M] LEDがゆっくり点滅）\n2. 記録したいキーの組み合わせを入力\n3. 再度 Fn + F9 を押す（[M] LEDが高速点滅）\n4. 割り当てたいキーを押して登録完了\n（Escキーでいつでもキャンセル可能）" : "1. Press Fn + F9 (LED [M] blinks slowly)\n2. Type your desired key sequence\n3. Press Fn + F9 again (LED [M] blinks rapidly)\n4. Press target key to bind and save\n(Press Esc at any time to cancel)")
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption - 1
                  color: Commons.Color.muted
                  lineHeight: 1.4
                  wrapMode: Text.WordWrap
                  width: parent.width
                }
              }
            }

            // Keyboard Locks & LED Status
            Rectangle {
              width: parent.width
              color: "#151b23"
              radius: 8
              border.color: "#2d3748"
              border.width: 1
              implicitHeight: locksCol.implicitHeight + Style.space(24)

              Column {
                id: locksCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(12)
                spacing: Style.space(10)

                PanelSectionHeader { text: rootWindow.t("keyboard_locks") }

                // 5 LED HUD
                Row {
                  width: parent.width
                  spacing: Style.space(6)

                  Repeater {
                    model: [
                      { label: "[1] Num", active: rootWindow.pluginRoot ? rootWindow.pluginRoot.numLock : false },
                      { label: "[A] Caps", active: rootWindow.pluginRoot ? rootWindow.pluginRoot.capsLock : false },
                      { label: "[S] Scroll", active: rootWindow.pluginRoot ? rootWindow.pluginRoot.scrollLock : false },
                      { label: "[M] Macro", active: false },
                      { label: "[G] Game", active: rootWindow.pluginRoot ? rootWindow.pluginRoot.gameMode : false }
                    ]

                    Rectangle {
                      width: (locksCol.width - Style.space(24)) / 5
                      height: Style.space(46)
                      color: modelData.active ? "#0a2612" : "#101315"
                      radius: 6
                      border.color: modelData.active ? "#00ff66" : "#2d3748"
                      border.width: 1

                      Column {
                        anchors.centerIn: parent
                        spacing: Style.space(3)

                        Rectangle {
                          width: Style.space(8)
                          height: Style.space(8)
                          radius: Style.space(4)
                          color: modelData.active ? "#00ff66" : "#3a4454"
                          anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                          text: modelData.label
                          font.family: Style.font.family
                          font.pixelSize: Style.font.caption - 2
                          font.bold: true
                          color: modelData.active ? "#00ff66" : Commons.Color.muted
                          anchors.horizontalCenter: parent.horizontalCenter
                        }
                      }
                    }
                  }
                }

                // Lock Toggle Buttons
                Row {
                  width: parent.width
                  spacing: Style.space(6)

                  Button {
                    text: rootWindow.t("caps") + (rootWindow.pluginRoot && rootWindow.pluginRoot.capsLock ? ": ON" : ": OFF")
                    selected: rootWindow.pluginRoot && rootWindow.pluginRoot.capsLock
                    width: (parent.width - Style.space(12)) / 3
                    onClicked: {
                      if (rootWindow.pluginRoot) rootWindow.pluginRoot.toggleCaps()
                      rootWindow.addLog("Caps Lock toggled", "ok")
                    }
                  }

                  Button {
                    text: rootWindow.t("num") + (rootWindow.pluginRoot && rootWindow.pluginRoot.numLock ? ": ON" : ": OFF")
                    selected: rootWindow.pluginRoot && rootWindow.pluginRoot.numLock
                    width: (parent.width - Style.space(12)) / 3
                    onClicked: {
                      if (rootWindow.pluginRoot) rootWindow.pluginRoot.toggleNum()
                      rootWindow.addLog("Num Lock toggled", "ok")
                    }
                  }

                  Button {
                    text: rootWindow.t("scroll") + (rootWindow.pluginRoot && rootWindow.pluginRoot.scrollLock ? ": ON" : ": OFF")
                    selected: rootWindow.pluginRoot && rootWindow.pluginRoot.scrollLock
                    width: (parent.width - Style.space(12)) / 3
                    onClicked: {
                      if (rootWindow.pluginRoot) rootWindow.pluginRoot.toggleScroll()
                      rootWindow.addLog("Scroll Lock toggled", "ok")
                    }
                  }
                }

                Text {
                  text: rootWindow.t("scroll_hint")
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption - 1
                  color: Commons.Color.muted
                  wrapMode: Text.WordWrap
                  width: parent.width
                  opacity: 0.85
                }
              }
            }

            // Polling Rate Card
            Rectangle {
              width: parent.width
              color: "#151b23"
              radius: 8
              border.color: "#2d3748"
              border.width: 1
              implicitHeight: pollCol.implicitHeight + Style.space(24)

              Column {
                id: pollCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(12)
                spacing: Style.space(8)

                PanelSectionHeader { text: rootWindow.currentLang === "fr" ? "Taux de rafraîchissement (Polling Rate)" : (rootWindow.currentLang === "ja" ? "ポーリングレート (応答速度)" : "Polling Rate") }

                Row {
                  width: parent.width
                  spacing: Style.space(6)

                  Button {
                    text: "125 Hz (8ms)"
                    selected: rootWindow.pluginRoot && rootWindow.pluginRoot.pollingRate === 125
                    width: (parent.width - Style.space(12)) / 3
                    onClicked: if (rootWindow.pluginRoot) rootWindow.pluginRoot.setPollingRate(125)
                  }
                  Button {
                    text: "500 Hz (2ms)"
                    selected: rootWindow.pluginRoot && rootWindow.pluginRoot.pollingRate === 500
                    width: (parent.width - Style.space(12)) / 3
                    onClicked: if (rootWindow.pluginRoot) rootWindow.pluginRoot.setPollingRate(500)
                  }
                  Button {
                    text: "1000 Hz (1ms)"
                    selected: rootWindow.pluginRoot && rootWindow.pluginRoot.pollingRate === 1000
                    width: (parent.width - Style.space(12)) / 3
                    onClicked: if (rootWindow.pluginRoot) rootWindow.pluginRoot.setPollingRate(1000)
                  }
                }
              }
            }
          }
        }

        // ==========================================
        // RIGHT COLUMN: Live Key Matrix & Event Logs
        // ==========================================
        ScrollView {
          id: rightScrollView
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.left: leftScrollView.right
          anchors.leftMargin: Style.space(16)
          anchors.right: parent.right
          clip: true
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

          Column {
            width: rightScrollView.availableWidth
            spacing: Style.space(12)

            // Live Key Rollover & Anti-Ghosting Tester Card
            Rectangle {
              width: parent.width
              color: "#151b23"
              radius: 8
              border.color: "#2d3748"
              border.width: 1
              implicitHeight: testerCol.implicitHeight + Style.space(24)

              Column {
                id: testerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(12)
                spacing: Style.space(10)

                Item {
                  width: parent.width
                  height: Style.space(24)

                  PanelSectionHeader {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: rootWindow.currentLang === "fr" ? "Testeur de Matrice & NKRO en Direct" : (rootWindow.currentLang === "ja" ? "キーマトリクス＆ロールオーバー テスター" : "Live Key Matrix & NKRO Tester")
                  }

                  Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: keyCountText.implicitWidth + Style.space(14)
                    height: Style.space(22)
                    radius: 11
                    color: rootWindow.activeKeyCount > 0 ? "#00e756" : "#101315"
                    border.color: "#00e756"
                    border.width: 1

                    Text {
                      id: keyCountText
                      anchors.centerIn: parent
                      text: rootWindow.activeKeyCount + " " + (rootWindow.currentLang === "fr" ? "touches pressées" : (rootWindow.currentLang === "ja" ? "キー入力中" : "keys pressed"))
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption - 1
                      font.bold: true
                      color: rootWindow.activeKeyCount > 0 ? "#000000" : Commons.Color.muted
                    }
                  }
                }

                // Tester Stats HUD
                Row {
                  width: parent.width
                  spacing: Style.space(8)

                  Rectangle {
                    width: (parent.width - Style.space(16) - Style.space(90)) / 2
                    height: Style.space(42)
                    color: "#101315"
                    radius: 6
                    border.color: "#2d3748"
                    border.width: 1

                    Column {
                      anchors.centerIn: parent
                      Text { text: rootWindow.currentLang === "fr" ? "Dernière touche" : (rootWindow.currentLang === "ja" ? "最終入力キー" : "Last key"); font.pixelSize: Style.font.caption - 2; color: Commons.Color.muted; anchors.horizontalCenter: parent.horizontalCenter }
                      Text { text: rootWindow.lastKeyName; font.pixelSize: Style.font.caption; font.bold: true; color: "#00ff66"; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                  }

                  Rectangle {
                    width: (parent.width - Style.space(16) - Style.space(90)) / 2
                    height: Style.space(42)
                    color: "#101315"
                    radius: 6
                    border.color: "#2d3748"
                    border.width: 1

                    Column {
                      anchors.centerIn: parent
                      Text { text: rootWindow.currentLang === "fr" ? "Roll-Over max" : (rootWindow.currentLang === "ja" ? "最大同時押し" : "Max Rollover"); font.pixelSize: Style.font.caption - 2; color: Commons.Color.muted; anchors.horizontalCenter: parent.horizontalCenter }
                      Text { text: rootWindow.maxKro + " KRO"; font.pixelSize: Style.font.caption; font.bold: true; color: "#00e756"; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                  }

                  Button {
                    text: rootWindow.currentLang === "fr" ? "Réinitialiser" : (rootWindow.currentLang === "ja" ? "リセット" : "Reset")
                    width: Style.space(90)
                    height: Style.space(42)
                    onClicked: rootWindow.resetTester()
                  }
                }

                // Interactive Keyboard Matrix Graphic
                Rectangle {
                  width: parent.width
                  height: Style.space(160)
                  color: "#101315"
                  radius: 8
                  border.color: "#2d3748"
                  border.width: 1
                  clip: true

                  Column {
                    anchors.centerIn: parent
                    spacing: Style.space(3)

                    // Function Row
                    Row {
                      spacing: Style.space(3)
                      Repeater {
                        model: ["ESC", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
                        Rectangle {
                          width: Style.space(34)
                          height: Style.space(24)
                          radius: 3
                          color: rootWindow.activeKeyCount > 0 ? "#143820" : "#1e293b"
                          border.color: "#334155"
                          border.width: 1
                          Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 8; font.bold: true; color: Commons.Color.muted }
                        }
                      }
                    }

                    // Number Row
                    Row {
                      spacing: Style.space(3)
                      Repeater {
                        model: ["~", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "⌫"]
                        Rectangle {
                          width: modelData === "⌫" ? Style.space(50) : Style.space(32)
                          height: Style.space(24)
                          radius: 3
                          color: "#1e293b"
                          border.color: "#334155"
                          border.width: 1
                          Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 9; color: Commons.Color.foreground }
                        }
                      }
                    }

                    // QWERTY Row
                    Row {
                      spacing: Style.space(3)
                      Repeater {
                        model: ["TAB", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]", "\\"]
                        Rectangle {
                          width: modelData === "TAB" ? Style.space(44) : (modelData === "\\" ? Style.space(38) : Style.space(32))
                          height: Style.space(24)
                          radius: 3
                          color: "#1e293b"
                          border.color: "#334155"
                          border.width: 1
                          Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 9; color: Commons.Color.foreground }
                        }
                      }
                    }

                    // ASDF Row
                    Row {
                      spacing: Style.space(3)
                      Repeater {
                        model: ["CAPS", "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "ENTER"]
                        Rectangle {
                          width: modelData === "CAPS" ? Style.space(52) : (modelData === "ENTER" ? Style.space(50) : Style.space(32))
                          height: Style.space(24)
                          radius: 3
                          color: (modelData === "CAPS" && rootWindow.pluginRoot && rootWindow.pluginRoot.capsLock) ? "#00e756" : "#1e293b"
                          border.color: "#334155"
                          border.width: 1
                          Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 9; color: (modelData === "CAPS" && rootWindow.pluginRoot && rootWindow.pluginRoot.capsLock) ? "#000000" : Commons.Color.foreground }
                        }
                      }
                    }

                    // ZXCV Row
                    Row {
                      spacing: Style.space(3)
                      Repeater {
                        model: ["SHIFT", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/", "SHIFT"]
                        Rectangle {
                          width: modelData === "SHIFT" ? Style.space(64) : Style.space(32)
                          height: Style.space(24)
                          radius: 3
                          color: "#1e293b"
                          border.color: "#334155"
                          border.width: 1
                          Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 9; color: Commons.Color.foreground }
                        }
                      }
                    }

                    // Bottom Space Row
                    Row {
                      spacing: Style.space(3)
                      Repeater {
                        model: ["CTRL", "WIN", "ALT", "SPACE", "ALT", "FN", "CTRL"]
                        Rectangle {
                          width: modelData === "SPACE" ? Style.space(190) : Style.space(42)
                          height: Style.space(24)
                          radius: 3
                          color: "#1e293b"
                          border.color: "#334155"
                          border.width: 1
                          Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 9; color: Commons.Color.foreground }
                        }
                      }
                    }
                  }
                }
              }
            }

            // Live Event & Action Log Console
            Rectangle {
              width: parent.width
              height: Style.space(180)
              color: "#151b23"
              radius: 8
              border.color: "#2d3748"
              border.width: 1
              clip: true

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(12)
                spacing: Style.space(8)

                Item {
                  width: parent.width
                  height: Style.space(24)

                  PanelSectionHeader {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: rootWindow.currentLang === "fr" ? "Journal des Événements & Trames Matérielles" : (rootWindow.currentLang === "ja" ? "イベント＆ハードウェアパケットログ" : "Hardware Event & Packet Logs")
                  }

                  Button {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: rootWindow.currentLang === "fr" ? "Effacer" : (rootWindow.currentLang === "ja" ? "消去" : "Clear")
                    width: Style.space(60)
                    height: Style.space(24)
                    onClicked: rootWindow.logEntries = []
                  }
                }

                ListView {
                  width: parent.width
                  height: parent.height - Style.space(34)
                  clip: true
                  model: rootWindow.logEntries

                  delegate: Text {
                    width: parent.width
                    text: modelData.text
                    font.family: "monospace"
                    font.pixelSize: 10
                    color: modelData.type === "ok" ? "#00ff66" : (modelData.type === "err" ? "#ff4444" : Commons.Color.muted)
                    wrapMode: Text.Wrap
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
