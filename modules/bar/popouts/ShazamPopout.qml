pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property PopoutState popouts

    implicitWidth: layout.implicitWidth + Tokens.padding.large * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.medium

        // Header with listening toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledText {
                text: qsTr("Music Recognition")
                font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                Layout.fillWidth: true
            }

            IconTextButton {
                id: toggleBtn
                text: Shazam.isListening ? qsTr("Listening") : qsTr("Paused")
                icon: Shazam.isListening ? "mic" : "mic_off"
                isToggle: true
                checked: Shazam.isListening
                onClicked: Shazam.toggle()
            }
        }

        // Active Track Hero Card
        StyledRect {
            Layout.preferredWidth: 320
            Layout.preferredHeight: Shazam.hasSong ? 180 : 70
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium
            clip: true

            Behavior on Layout.preferredHeight {
                Anim { type: Anim.SlowEffects }
            }

            // When a track is recognized
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small
                visible: Shazam.hasSong

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    // Album Art
                    StyledRect {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: Tokens.rounding.small
                        color: Colours.tPalette.m3surfaceContainerHighest
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: Shazam.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: Shazam.title
                            font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
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

                Item { Layout.fillHeight: true }

                // Actions Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    // 320kbps JioSaavn Download Button
                    IconTextButton {
                        Layout.fillWidth: true
                        text: Shazam.isDownloading ? qsTr("Downloading...") : qsTr("320kbps Download")
                        icon: Shazam.isDownloading ? "sync" : "download"
                        enabled: !Shazam.isDownloading
                        onClicked: Shazam.downloadCurrent()
                    }

                    // Apple Music 30s Preview Player
                    IconButton {
                        visible: Shazam.previewUrl.length > 0
                        icon: "play_arrow"
                        onClicked: Shazam.playPreview()
                    }
                }
            }

            // Listening Placeholder
            RowLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.medium
                visible: !Shazam.hasSong

                MaterialIcon {
                    text: Shazam.isListening ? "hearing" : "music_off"
                    color: Shazam.isListening ? Colours.palette.m3primary : Colours.palette.m3outline
                    animate: true
                }

                StyledText {
                    text: Shazam.isListening ? qsTr("Listening for ambient audio...") : qsTr("Recognition paused")
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Recognition History
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            visible: Shazam.history.length > 0

            StyledText {
                text: qsTr("Recent History")
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: Colours.palette.m3outline
            }

            Repeater {
                model: Shazam.history.slice(0, 3)

                StyledRect {
                    id: histItem
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    color: Colours.tPalette.m3surfaceContainer
                    radius: Tokens.rounding.small

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: "music_note"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3secondary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: histItem.modelData.title ?? ""
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: histItem.modelData.artist ?? ""
                                font: Tokens.font.body.extraSmall
                                color: Colours.palette.m3outline
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        IconButton {
                            icon: "download"
                            onClicked: Shazam.downloadTrack(histItem.modelData.title ?? "", histItem.modelData.artist ?? "")
                        }
                    }
                }
            }
        }
    }
}
