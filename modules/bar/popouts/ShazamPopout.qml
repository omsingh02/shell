pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    width: 300
    spacing: Tokens.spacing.small

    StyledText {
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("Music Recognition")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    Toggle {
        label: qsTr("Listening")
        checked: Shazam.isListening
        toggle.onToggled: Shazam.toggle()
    }

    // Status / Now Recognized Section
    StyledText {
        Layout.topMargin: Tokens.spacing.small
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Shazam.hasSong ? qsTr("Current Track") : (Shazam.isListening ? qsTr("Listening for ambient audio...") : qsTr("Recognition paused"))
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    // Active Recognized Track Card
    StyledRect {
        visible: Shazam.hasSong
        Layout.fillWidth: true
        Layout.preferredHeight: activeCol.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainerHigh

        ColumnLayout {
            id: activeCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                // Thumbnail Art or Icon
                StyledRect {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: Tokens.rounding.small
                    color: Colours.tPalette.m3surfaceContainerHighest
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: Shazam.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: Shazam.artUrl.length > 0
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "music_note"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                        visible: Shazam.artUrl.length === 0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: Shazam.title
                        font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: Shazam.artist
                        font: Tokens.font.body.extraSmall
                        color: Colours.palette.m3secondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: Shazam.album.length > 0
                        text: Shazam.album
                        font: Tokens.font.body.extraSmall
                        color: Colours.palette.m3outline
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                IconTextButton {
                    Layout.fillWidth: true
                    text: Shazam.isDownloading ? qsTr("Downloading...") : qsTr("320kbps Download")
                    icon: Shazam.isDownloading ? "sync" : "download"
                    disabled: Shazam.isDownloading
                    onClicked: Shazam.downloadCurrent()
                }

                IconButton {
                    visible: Shazam.previewUrl.length > 0
                    icon: "play_arrow"
                    type: IconButton.Tonal
                    onClicked: Shazam.playPreview(Shazam.previewUrl)
                }
            }
        }
    }

    // Recent History Section Header
    StyledText {
        visible: Shazam.history.length > 0
        Layout.topMargin: Tokens.spacing.small
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("Recent Recognitions")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    // History Repeater
    Repeater {
        model: Shazam.history.slice(0, 4)

        RowLayout {
            id: histRow

            required property var modelData

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "music_note"
                fontStyle: Tokens.font.icon.small
                color: Colours.palette.m3secondary
            }

            ColumnLayout {
                Layout.leftMargin: Tokens.spacing.extraSmall
                Layout.rightMargin: Tokens.spacing.extraSmall
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: histRow.modelData.title ?? ""
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: histRow.modelData.artist ?? ""
                    font: Tokens.font.body.extraSmall
                    color: Colours.palette.m3outline
                    elide: Text.ElideRight
                }
            }

            IconButton {
                icon: "download"
                type: IconButton.Tonal
                onClicked: Shazam.downloadTrack(histRow.modelData.title ?? "", histRow.modelData.artist ?? "")
            }
        }
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
