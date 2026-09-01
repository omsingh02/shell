pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services

Item {
    id: root

    required property PopoutState popouts

    implicitWidth: 360
    implicitHeight: mainCol.implicitHeight + Tokens.padding.large * 2

    ColumnLayout {
        id: mainCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.medium

        // Top Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "graphic_eq"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
                animate: true
            }

            StyledText {
                text: qsTr("Shazam Audio Engine")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
                Layout.fillWidth: true
            }

            IconTextButton {
                id: listenToggleBtn

                isToggle: true
                checked: Shazam.isListening
                text: Shazam.isListening ? qsTr("Active") : qsTr("Listen")
                icon: Shazam.isListening ? "hearing" : "hearing_disabled"
                onClicked: Shazam.toggle()
            }
        }

        // Hero Stage (Active Song vs Listening Radar)
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Shazam.hasSong ? 260 : 160
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerHigh
            clip: true

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Colours.palette.m3outline
                shadowOpacity: 0.15
                blurMax: 4
            }

            Behavior on Layout.preferredHeight {
                Anim { type: Anim.FastSpatial }
            }

            // State A: Song Recognized Hero View
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium
                visible: Shazam.hasSong

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.large

                    // High-Res Rotating Cover Art
                    Item {
                        Layout.preferredWidth: 84
                        Layout.preferredHeight: 84

                        Item {
                            id: coverMask
                            anchors.fill: parent
                            layer.enabled: true

                            MaterialShape {
                                anchors.fill: parent
                                shape: MaterialShape.Cookie9Sided
                                color: Colours.palette.m3surfaceContainerHighest

                                Anim on rotation {
                                    running: Shazam.hasSong
                                    from: 0
                                    to: 360
                                    duration: 25000
                                    easing.type: Easing.Linear
                                    loops: Animation.Infinite
                                }
                            }
                        }

                        FadeImage {
                            anchors.fill: parent
                            source: Shazam.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true

                            layer.enabled: true
                            layer.effect: Mask {
                                maskSource: coverMask
                            }
                        }
                    }

                    // Track Metadata Info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        StyledText {
                            text: Shazam.title
                            font: Tokens.font.title.medium
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: Shazam.artist
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3secondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            visible: Shazam.album.length > 0
                            text: Shazam.album
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Quality Badge
                        RowLayout {
                            spacing: Tokens.spacing.extraSmall
                            Layout.topMargin: 4

                            StyledRect {
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: 82
                                radius: Tokens.rounding.full
                                color: Colours.tPalette.m3primaryContainer

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "320kbps AAC"
                                    font: Tokens.font.label.small
                                    color: Colours.palette.m3onPrimaryContainer
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Action Controls Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    IconTextButton {
                        Layout.fillWidth: true
                        text: Shazam.isDownloading ? qsTr("Downloading...") : qsTr("320kbps Download")
                        icon: Shazam.isDownloading ? "sync" : "download"
                        enabled: !Shazam.isDownloading
                        onClicked: Shazam.downloadCurrent()
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: "play_arrow"
                        isRound: true
                        visible: Shazam.previewUrl.length > 0
                        onClicked: Shazam.playPreview()
                    }
                }
            }

            // State B: Ambient Listening Radar View
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.medium
                visible: !Shazam.hasSong

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 60

                    // Pulsing Ring 1
                    StyledRect {
                        anchors.centerIn: parent
                        width: pulseScale * 56
                        height: pulseScale * 56
                        radius: Tokens.rounding.full
                        color: Qt.alpha(Colours.palette.m3primary, 0.2)

                        property real pulseScale: 1.0
                        SequentialAnimation on pulseScale {
                            running: Shazam.isListening
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.35; duration: 1200; easing.type: Easing.OutQuad }
                            NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Pulsing Center Icon
                    StyledRect {
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        radius: Tokens.rounding.full
                        color: Shazam.isListening ? Colours.palette.m3primary : Colours.palette.m3surfaceVariant

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: Shazam.isListening ? "hearing" : "music_note"
                            color: Shazam.isListening ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                            animate: true
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Shazam.isListening ? qsTr("Listening for ambient audio...") : qsTr("Recognition paused")
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Recognition History Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            visible: Shazam.history.length > 0

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Recent Recognitions")
                    font: Tokens.font.label.large
                    color: Colours.palette.m3outline
                    Layout.fillWidth: true
                }
            }

            Repeater {
                model: Shazam.history.slice(0, 3)

                StyledRect {
                    id: histCard
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    color: Colours.tPalette.m3surfaceContainer
                    radius: Tokens.rounding.medium

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "music_note"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: histCard.modelData.title ?? ""
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: histCard.modelData.artist ?? ""
                                font: Tokens.font.body.extraSmall
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        IconButton {
                            type: IconButton.Tonal
                            icon: "download"
                            onClicked: Shazam.downloadTrack(histCard.modelData.title ?? "", histCard.modelData.artist ?? "")
                        }
                    }
                }
            }
        }
    }
}
