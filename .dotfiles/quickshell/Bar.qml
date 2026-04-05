import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris

PanelWindow {
    required property ShellScreen modelData
    screen: modelData
    visible: modelData.name === "DP-3"
    id: bar
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 56
    color: "transparent"
    exclusiveZone: 56

    // ── Processes ────────────────────────────────────────────────────

    Process {
        id: cpuProc
        command: ["bash", "-c", "cat /sys/class/hwmon/hwmon3/temp1_input"]
        running: true
        stdout: SplitParser {
            onRead: data => cpuTemp.text = Math.round(parseInt(data) / 1000) + "°"
        }
        onExited: cpuTimer.restart()
    }
    Timer { id: cpuTimer; interval: 3000; repeat: false; onTriggered: cpuProc.running = true }

    Process {
        id: ramProc
        command: ["bash", "-c", "free -m | awk 'NR==2{printf \"%d%%\", $3/$2*100}'"]
        running: true
        stdout: SplitParser {
            onRead: data => ramUsage.text = data.trim()
        }
        onExited: ramTimer.restart()
    }
    Timer { id: ramTimer; interval: 5000; repeat: false; onTriggered: ramProc.running = true }

    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                const muted = line.includes("MUTED")
                const match = line.match(/(\d+\.\d+)/)
                if (!match) return
                const vol = Math.round(parseFloat(match[1]) * 100)
                const filled = Math.round(vol / 10)
                volBar.text = "[" + "█".repeat(Math.min(filled, 10)) + "░".repeat(Math.max(10 - filled, 0)) + "]"
                volValue.text = vol + "%"
                if (muted || vol === 0) {
                    volIcon.text = "󰸈"; volIcon.color = Colors.overlay0
                    volBar.color = Colors.overlay0; volValue.color = Colors.overlay0
                } else if (vol <= 33) {
                    volIcon.text = "󰕿"; volIcon.color = Colors.subtext0
                    volBar.color = Colors.subtext0; volValue.color = Colors.subtext0
                } else if (vol <= 66) {
                    volIcon.text = "󰖀"; volIcon.color = Colors.subtext0
                    volBar.color = Colors.subtext0; volValue.color = Colors.subtext0
                } else {
                    volIcon.text = "󰕾"; volIcon.color = Colors.green
                    volBar.color = Colors.green; volValue.color = Colors.green
                }
            }
        }
        onExited: volTimer.restart()
    }
    Timer { id: volTimer; interval: 2000; repeat: false; onTriggered: volProc.running = true }
    Process { id: muteProc; running: false; onExited: volProc.running = true }

    Process {
        id: btProc
        command: ["bash", "-c", "bluetoothctl show | grep 'Powered: yes' | wc -l"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const on = data.trim() === "1"
                btIcon.text = on ? "󰂯" : "󰂲"
                btIcon.color = on ? Colors.blue : Colors.overlay0
            }
        }
        onExited: btTimer.restart()
    }
    Timer { id: btTimer; interval: 10000; repeat: false; onTriggered: btProc.running = true }

    Process { id: powerProc; running: false }

    // ── UI ───────────────────────────────────────────────────────────

    Rectangle {
        anchors {
            top: parent.top; left: parent.left; right: parent.right
            topMargin: Colors.barMargin
            leftMargin: Colors.barMargin
            rightMargin: Colors.barMargin
            bottomMargin: Colors.barMargin
        }
        height: Colors.barHeight
        radius: Colors.barRadius
        color: Colors.base
        border.color: Colors.peach
        border.width: 3

        // ── Gauche ───────────────────────────────────────────────────
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: Colors.barPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Bouton power
            Text {
                text: "[ 󰐥 ]"; font.pixelSize: 13; font.family: Colors.nerdFont
                color: Colors.overlay0
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.color = Colors.red
                    onExited: parent.color = Colors.overlay0
                    onClicked: {
                        powerProc.command = ["bash", "/home/dod/.config/waybar/scripts/powermenu.sh"]
                        powerProc.running = true
                    }
                }
            }

            Rectangle { width: 1; height: 18; color: Colors.surface1 }

            // Volume
            RowLayout {
                spacing: 3
                Text {
                    id: volIcon; text: "󰖀"; font.pixelSize: 15; font.family: Colors.nerdFont; color: Colors.subtext0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]; muteProc.running = true }
                    }
                }
                Text { id: volBar; text: "[░░░░░░░░░░]"; font.pixelSize: 11; color: Colors.subtext0; Behavior on color { ColorAnimation { duration: 150 } } }
                Text { id: volValue; text: "—"; font.pixelSize: 11; color: Colors.subtext0; Behavior on color { ColorAnimation { duration: 150 } } }
            }

            Rectangle { width: 1; height: 18; color: Colors.surface1 }

            // Bouton MPRIS
            Text {
                visible: Mpris.players.values.length > 0
                text: "󰝚"; font.pixelSize: 13; font.family: Colors.nerdFont
                color: root.mprisVisible ? Colors.peach : Colors.overlay0
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.mprisVisible = !root.mprisVisible
                    cursorShape: Qt.PointingHandCursor
                }
            }
            Rectangle {
                visible: Mpris.players.values.length > 0
                width: 1; height: 18; color: Colors.surface1
            }

            // Bouton wallpaper picker
            Text {
                text: "󰸉"; font.pixelSize: 13; font.family: Colors.nerdFont
                color: root.pickerVisible ? Colors.peach : Colors.overlay0
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.pickerVisible = !root.pickerVisible
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Rectangle { width: 1; height: 18; color: Colors.surface1 }

            // Workspaces
            Repeater {
                model: Hyprland.workspaces.values
                delegate: Item {
                    required property HyprlandWorkspace modelData
                    readonly property bool isActive: modelData.id === Hyprland.focusedMonitor?.activeWorkspace?.id
                    width: isActive ? 24 : 8
                    height: Colors.barHeight
                    Layout.preferredWidth: isActive ? 24 : 8
                    Layout.preferredHeight: Colors.barHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: isActive ? 24 : 8
                        height: isActive ? 24 : 8
                        radius: isActive ? 6 : 4
                        color: isActive ? Colors.green : Colors.surface1
                        Behavior on width  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color  { ColorAnimation  { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            visible: parent.parent.isActive
                            text: parent.parent.modelData.id
                            color: Colors.mantle; font.pixelSize: 11; font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + parent.parent.modelData.id)
                            cursorShape: Qt.PointingHandCursor
                       }
                   }
               }
           }
           }

        // ── Centre : horloge — FIX : MouseArea sorti du ColumnLayout dans un Item wrapper
        Item {
            anchors.centerIn: parent
            implicitWidth:  clockCol.implicitWidth
            implicitHeight: clockCol.implicitHeight

            ColumnLayout {
                id: clockCol
                anchors.fill: parent
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatTime(clock.date, "HH:mm:ss")
                    color: Colors.peach; font.pixelSize: 13; font.weight: Font.Medium
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(clock.date, "ddd dd MMM")
                    color: Colors.subtext0; font.pixelSize: 10
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.calendarVisible = !root.calendarVisible
                cursorShape: Qt.PointingHandCursor
            }
        }

        // ── Droite ───────────────────────────────────────────────────
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: Colors.barPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            /// CPU
            RowLayout {
                spacing: 3
                Text { text: "󰍛"; font.pixelSize: 13; font.family: Colors.nerdFont; color: Colors.peach }
                Text { id: cpuTemp; text: "—"; font.pixelSize: 11; color: Colors.subtext0 }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sysPopupVisible = !root.sysPopupVisible
                }
            }

            // RAM
            RowLayout {
                spacing: 3
                Text { text: ""; font.pixelSize: 13; font.family: Colors.nerdFont; color: Colors.green }
                Text { id: ramUsage; text: "—"; font.pixelSize: 11; color: Colors.subtext0 }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sysPopupVisible = !root.sysPopupVisible
                }
            }

            Rectangle { width: 1; height: 18; color: Colors.surface1 }

            // Bluetooth
            Text {
                id: btIcon; text: "󰂲"; font.pixelSize: 14; font.family: Colors.nerdFont; color: Colors.overlay0
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Rectangle { width: 1; height: 18; color: Colors.surface1 }

            // Systray (Nextcloud uniquement)
            Repeater {
                model: SystemTray.items
                delegate: Item {
                    required property SystemTrayItem modelData
                    visible: !modelData.id.toLowerCase().includes("blueman")
                          && !modelData.id.toLowerCase().includes("nm-applet")
                          && !modelData.id.toLowerCase().includes("network")
                    implicitWidth: visible ? 22 : 0
                    implicitHeight: 22
                    Image {
                        anchors.fill: parent
                        source: modelData.icon
                        smooth: true
                        sourceSize.width: 22
                        sourceSize.height: 22
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) modelData.activate()
                            else modelData.secondaryActivate()
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            Rectangle { width: 1; height: 18; color: Colors.surface1 }

            // Bouton notifications
            Item {
                implicitWidth: 20; implicitHeight: 20

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"; font.pixelSize: 14; font.family: Colors.nerdFont
                    color: root.notifCenterVisible ? Colors.peach : (root.unreadCount > 0 ? Colors.green : Colors.overlay0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Rectangle {
                    visible: root.unreadCount > 0 && !root.notifCenterVisible
                    anchors.top: parent.top; anchors.right: parent.right
                    width: 14; height: 14; radius: 7
                    color: Colors.red

                    Text {
                        anchors.centerIn: parent
                        text: root.unreadCount > 9 ? "9+" : root.unreadCount
                        font.pixelSize: 8; font.weight: Font.Medium; color: Colors.mantle
                    }
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.notifCenterVisible = !root.notifCenterVisible
                        if (root.notifCenterVisible) root.unreadCount = 0
                    }
                }
            }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }
}
