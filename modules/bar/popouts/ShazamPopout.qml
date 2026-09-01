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

    width: 320
    spacing: Tokens.spacing.small

    // Header Row
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "graphic_eq"
            color: Shazam.isListening ? Colours.palette.m3primary : Colours.palette.m3outline
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: qsTr("Music Recognition")
                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: Shazam.isListening ? (Shazam.hasSong ? qsTr("Track Detected") : qsTr("Listening actively...")) : qsTr("Recognition Paused")
                font: Tokens.font.body.extraSmall
                color: Shazam.isListening ? Colours.palette.m3primary : Colours.palette.m3outline
            }
        }

        StyledSwitch {
            checked: Shazam.isListening
            onToggled: Shazam.toggle()
        }
    }

    // Now Recognized Hero Card
    StyledRect {
        visible: Shazam.hasSong
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.extraSmall
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainerHigh

        ColumnLayout {
            id: currentCardCol
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                // Squircle Cover Artwork
                StyledRect {
                    Layout.preferredWidth: 54
                    Layout.preferredHeight: 54
                    radius: Tokens.rounding.medium
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
                        fontStyle: Tokens.font.icon.large
                        visible: Shazam.artUrl.length === 0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: Shazam.title
                        font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: Shazam.artist
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
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

            // Action Buttons Row
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                IconTextButton {
                    Layout.fillWidth: true
                    text: Shazam.isDownloading ? qsTr("Downloading...") : qsTr("320k Download")
                    icon: Shazam.isDownloading ? "sync" : "download"
                    disabled: Shazam.isDownloading
                    onClicked: Shazam.downloadCurrent()
                }

                IconButton {
                    visible: Shazam.previewUrl.length > 0
                    icon: Shazam.isPreviewPlaying ? "stop" : "play_arrow"
                    type: IconButton.Tonal
                    isRound: true
                    onClicked: Shazam.playPreview(Shazam.previewUrl)
                }

                IconButton {
                    icon: "content_copy"
                    type: IconButton.Tonal
                    isRound: true
                    onClicked: Shazam.copyTrackInfo(Shazam.title, Shazam.artist)
                }
            }
        }
    }

    // Ambient Listening Wave Card (when listening and no track detected yet)
    StyledRect {
        visible: Shazam.isListening && !Shazam.hasSong
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.extraSmall
        Layout.preferredHeight: 74
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainerHigh

        RowLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "hearing"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.large
                animate: true
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: qsTr("Listening for music...")
                    font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: qsTr("Play audio near mic or on desktop")
                    font: Tokens.font.body.extraSmall
                    color: Colours.palette.m3outline
                }
            }
        }
    }

    // Recent History Header
    RowLayout {
        visible: Shazam.history.length > 0
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Recent History")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.builders.small.weight(Font.Medium).build()
        }

        StyledText {
            text: qsTr("%1 tracks").arg(Math.min(Shazam.history.length, 5))
            color: Colours.palette.m3outline
            font: Tokens.font.body.extraSmall
        }
    }

    // Recent History Items
    Repeater {
        model: Shazam.history.slice(0, 5)

        StyledRect {
            id: histItem

            required property var modelData

            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: Tokens.rounding.medium
            color: stateLayer.hovered ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

            StateLayer {
                id: stateLayer
                anchors.fill: parent
                radius: Tokens.rounding.medium
                onClicked: Shazam.copyTrackInfo(histItem.modelData.title ?? "", histItem.modelData.artist ?? "")
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.extraSmall
                anchors.rightMargin: Tokens.padding.extraSmall
                spacing: Tokens.spacing.small

                // Thumbnail Cover Art
                StyledRect {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: Tokens.rounding.small
                    color: Colours.tPalette.m3surfaceContainerHigh
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: histItem.modelData.cover_art ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: (histItem.modelData.cover_art ?? "").length > 0
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "music_note"
                        color: Colours.palette.m3secondary
                        fontStyle: Tokens.font.icon.small
                        visible: !(histItem.modelData.cover_art ?? "").length
                    }
                }

                // Title + Artist
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: histItem.modelData.title ?? ""
                        font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: histItem.modelData.artist ?? ""
                        font: Tokens.font.body.extraSmall
                        color: Colours.palette.m3outline
                        elide: Text.ElideRight
                    }
                }

                // Download Button for this track
                IconButton {
                    icon: "download"
                    type: IconButton.Tonal
                    isRound: true
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: Shazam.downloadTrack(histItem.modelData.title ?? "", histItem.modelData.artist ?? "")
                }
            }
        }
    }
}
