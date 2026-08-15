import QtQuick
import Quickshell
import Quickshell.Services.Mpris

PanelWindow {
    id: mprisWindow

    visible: Mpris.players.values.length > 0 && root.mprisVisible

    anchors.left: true
    anchors.bottom: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 296
    implicitHeight: 88
    color: "transparent"

    MprisContent {
        x: 8; y: 8
    }
}