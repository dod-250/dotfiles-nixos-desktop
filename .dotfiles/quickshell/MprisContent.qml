import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: root
    width: 280; height: 72
    radius: Colors.barRadius
    color: Colors.mantle
    border.color: Colors.peach
    border.width: 2

    property MprisPlayer mprisPlayer: Mpris.players.values.find(
        p => p.playbackState === MprisPlaybackState.Playing
    ) ?? Mpris.players.values[0] ?? null

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Rectangle {
            width: 48; height: 48; radius: 6
            color: Colors.surface0; clip: true
            Image {
                anchors.fill: parent
                source: root.mprisPlayer?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.mprisPlayer?.trackTitle || "—"
                font.pixelSize: 12; font.weight: Font.Medium
                color: Colors.text; elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.mprisPlayer?.trackArtist || ""
                font.pixelSize: 10; color: Colors.subtext0; elide: Text.ElideRight
            }

            RowLayout {
                spacing: 12
                Repeater {
                    model: [
                        { label: "⏮", action: () => root.mprisPlayer?.previous() },
                        { label: root.mprisPlayer?.playbackState === MprisPlaybackState.Playing ? "⏸" : "▶", action: () => root.mprisPlayer?.togglePlaying() },
                        { label: "⏭", action: () => root.mprisPlayer?.next() }
                    ]
                    delegate: Text {
                        required property var modelData
                        required property int index
                        text: modelData.label; font.pixelSize: 13
                        color: index === 1 ? Colors.peach : Colors.overlay0
                        MouseArea {
                            anchors.fill: parent
                            onClicked: parent.modelData.action()
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.color = Colors.text
                            onExited: parent.color = parent.index === 1 ? Colors.peach : Colors.overlay0
                        }
                    }
                }
            }
        }
    }
}