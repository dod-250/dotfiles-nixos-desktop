pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris

Item {
    id: root
    required property var root // la Scope parente (Lock.qml)

    // Fond flouté : screenshot pris juste avant le lock
    Image {
        id: bg
        anchors.fill: parent
        source: "file:///home/dod/Pictures/misc/league_beneath_2.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: false
        cache: false
    }

    MultiEffect {
        anchors.fill: bg
        source: bg
        blurEnabled: true
        blur: 0
        blurMax: 64
        brightness: -0.12
    }

    Rectangle { anchors.fill: parent; color: "#a11c1b29" } // voile Catppuccin Mocha/Macchiato

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24

        // Photo de profil
        ClippingRectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 120; height: 120; radius: 60
            color: "transparent"
            Image {
                anchors.fill: parent
                source: "file:///home/dod/Pictures/user_pics/user-pic2.png" // adapte le chemin
                fillMode: Image.PreserveAspectCrop
            }
        }

        // Heure / date
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            font.pixelSize: 72
            font.family: "0xProto Nerd Font"
            color: "#f5a97f" // peach
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(clock.date, "dddd d MMMM")
            font.pixelSize: 20
            color: "#cad3f5"
        }

        SystemClock {
            id: clock
            precision: SystemClock.Seconds
        }

        // Uptime
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: uptimeText
            font.pixelSize: 14
            color: "#a6da95" // green
        }

        // MPRIS — réutilise ton widget existant de la bar
        MprisContent {
            Layout.alignment: Qt.AlignHCenter
            visible: Mpris.players.values.length > 0
        }

        // Champ mot de passe
        Rectangle {
            id: pwBox
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 260
            Layout.preferredHeight: 48
            radius: 12
            color: "#1e2030"
            border.color: root.root.showError ? "#ed8796" : "#f5a97f"
            border.width: 2

            property real shakeX: 0
            transform: Translate { x: pwBox.shakeX }

            Behavior on border.color { ColorAnimation { duration: 150 } }

            TextInput {
                id: pwField
                anchors.fill: parent
                anchors.margins: 12
                echoMode: TextInput.Password
                color: "#cad3f5"
                font.pixelSize: 16
                verticalAlignment: TextInput.AlignVCenter
                focus: true
                onTextChanged: {
                    root.root.enteredPassword = text
                    if (root.root.showError) root.root.showError = false
                }
                Keys.onReturnPressed: root.root.tryUnlock()
                onActiveFocusChanged: console.log("[lock] pwField activeFocus:", activeFocus, "screen:", root.outputName)

                Component.onCompleted: {
                    console.log("[lock] pwField completed on screen:", root.outputName)
                    pwField.forceActiveFocus()
                }
            }

            Text {
                anchors.centerIn: parent
                text: "Mot de passe"
                color: "#6e738d"
                font.pixelSize: 14
                visible: pwField.text.length === 0 && !pwField.activeFocus
            }

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: pwBox; property: "shakeX"; to: -8; duration: 40 }
                NumberAnimation { target: pwBox; property: "shakeX"; to: 8; duration: 40 }
                NumberAnimation { target: pwBox; property: "shakeX"; to: -6; duration: 40 }
                NumberAnimation { target: pwBox; property: "shakeX"; to: 6; duration: 40 }
                NumberAnimation { target: pwBox; property: "shakeX"; to: 0; duration: 40 }
            }

            Connections {
                target: root.root
                function onAuthFailed() {
                    shakeAnim.start()
                }
            }
        }

        // Message d'erreur
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Mot de passe incorrect"
            color: "#ed8796"
            font.pixelSize: 13
            visible: root.root.showError
            opacity: root.root.showError ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    property string uptimeText: ""
    Process {
        id: uptimeProc
        command: ["bash", "-c", "awk '{printf \"%dh %dmin\", $1/3600, ($1%3600)/60}' /proc/uptime"]
        stdout: StdioCollector { onStreamFinished: {
            root.uptimeText = this.text.trim()
        } }
    }
    Timer {
        interval: 30000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            console.log("[lock] uptime timer fired")
            uptimeProc.running = true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: pwField.forceActiveFocus()
    }
}