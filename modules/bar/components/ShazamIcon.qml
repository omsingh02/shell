pragma ComponentBehavior: Bound

import qs.components
import qs.services
import QtQuick
import Caelestia.Config

Item {
    id: root

    property color colour: Colours.palette.m3secondary

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter

        text: "music_note"
        fontStyle: Tokens.font.icon.medium
        color: root.colour
    }
}
