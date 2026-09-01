pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Caelestia.Config

Item {
    id: root

    implicitWidth: layout.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    property string shazamClass: "paused"
    property string currentSong: ""
    property var historyItems: []
    property string actionStatus: ""

    // Read state from state file existence
    Process {
        id: stateProc
        command: ["sh", "-c", "test -f /tmp/waybar-shazam-state && echo active || echo paused"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.shazamClass = text.trim() === "active" ? "ambient" : "paused";
            }
        }
    }

    // Read JSON history
    Process {
        id: historyProc
        command: ["sh", "-c", "touch ~/.local/share/shazam_history.jsonl && tail -n 3 ~/.local/share/shazam_history.jsonl | tac"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split('\n').filter(l => l.length > 0);
                try {
                    root.historyItems = lines.map(JSON.parse);
                } catch (e) {
                    root.historyItems = [];
                }
            }
        }
    }

    // Read current song from state file written by scanner.py
    Process {
        id: currentSongProc
        command: ["sh", "-c", "cat /tmp/waybar-shazam-current 2>/dev/null || true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.currentSong = text.trim();
            }
        }
    }

    // Read action status for download/play button feedback
    Process {
        id: actionStatusProc
        command: ["sh", "-c", "cat /tmp/waybar-shazam-action-status 2>/dev/null || true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.actionStatus = text.trim();
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            stateProc.running = true;
            historyProc.running = true;
            currentSongProc.running = true;
            actionStatusProc.running = true;
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.medium

        // Current Song Info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: {
                    if (root.shazamClass === "paused") return qsTr("Status: Paused");
                    if (root.currentSong !== "") return qsTr("Now Playing");
                    return qsTr("Listening...");
                }
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            StyledText {
                visible: root.currentSong !== ""
                Layout.fillWidth: true
                text: root.currentSong
                font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                color: Colours.palette.m3primary
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignLeft
            }

            StyledRect {
                Layout.fillWidth: true
                height: 4
                visible: root.actionStatus.startsWith("downloading:")
                color: Colours.palette.m3surfaceVariant
                radius: 2

                StyledRect {
                    height: parent.height
                    width: parent.width * (root.actionStatus.startsWith("downloading:") ? parseFloat(root.actionStatus.split(":")[1]) / 100.0 : 0)
                    color: Colours.palette.m3primary
                    radius: 2
                    
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            IconTextButton {
                Layout.fillWidth: true
                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer
                verticalPadding: Tokens.padding.small
                text: root.shazamClass === "paused" ? qsTr("Resume Listening") : qsTr("Pause Listening")
                icon: root.shazamClass === "paused" ? "play_arrow" : "pause"

                onClicked: {
                    root.shazamClass = root.shazamClass === "paused" ? "listening" : "paused";
                    Quickshell.execDetached(["/home/faulter/.local/bin/musicRecognition/shazam-waybar.sh", "toggle"]);
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                // Download Button
                IconTextButton {
                    Layout.fillWidth: true
                    inactiveColour: root.currentSong !== "" ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainerHigh
                    inactiveOnColour: root.currentSong !== "" ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                    verticalPadding: Tokens.padding.small
                    enabled: root.currentSong !== "" && root.actionStatus === ""
                    text: {
                        if (root.actionStatus === "downloading") return qsTr("Downloading...");
                        if (root.actionStatus === "done") return qsTr("Ready ✓");
                        if (root.actionStatus === "error") return qsTr("Failed ✗");
                        return qsTr("Download");
                    }
                    icon: {
                        if (root.actionStatus === "downloading") return "hourglass_top";
                        if (root.actionStatus === "done") return "check_circle";
                        if (root.actionStatus === "error") return "error";
                        return "download";
                    }

                    onClicked: {
                        Quickshell.execDetached(["/home/faulter/.local/bin/musicRecognition/shazam-action.sh", "download"]);
                    }
                }

                // YouTube Button
                IconTextButton {
                    Layout.fillWidth: true
                    inactiveColour: root.currentSong !== "" ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                    inactiveOnColour: root.currentSong !== "" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    verticalPadding: Tokens.padding.small
                    enabled: root.currentSong !== "" && root.actionStatus === ""
                    text: {
                        if (root.actionStatus === "searching-yt") return qsTr("Searching...");
                        if (root.actionStatus === "opened-yt") return qsTr("Playing...");
                        return qsTr("YouTube");
                    }
                    icon: {
                        if (root.actionStatus === "searching-yt") return "hourglass_top";
                        if (root.actionStatus === "opened-yt") return "play_circle";
                        return "smart_display"; // YouTube-like icon
                    }

                    onClicked: {
                        Quickshell.execDetached(["/home/faulter/.local/bin/musicRecognition/shazam-action.sh", "youtube"]);
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
            Layout.topMargin: Tokens.spacing.extraSmall
            Layout.bottomMargin: Tokens.spacing.extraSmall
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("History")
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            Repeater {
                model: root.historyItems.length > 0 ? root.historyItems : [{"title": qsTr("No history found"), "artist": ""}]

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    // Music Note Indicator Icon
                    MaterialIcon {
                        text: "music_note"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                        opacity: 0.7
                    }

                    // Song Title & Artist Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.title || qsTr("Unknown Title")
                            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: !!modelData.artist
                            text: modelData.artist || ""
                            font: Tokens.font.body.builders.small.build()
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideRight
                        }
                    }

                    // Action buttons layout
                    RowLayout {
                        spacing: Tokens.spacing.extraSmall
                        visible: modelData.title !== undefined && modelData.artist !== "" && modelData.title !== qsTr("No history found")

                        IconButton {
                            type: IconButton.Tonal
                            icon: "download"
                            onClicked: {
                                Quickshell.execDetached(["/home/faulter/.local/bin/musicRecognition/shazam-action.sh", "download", "--title", modelData.title, "--artist", modelData.artist]);
                            }
                        }

                        IconButton {
                            type: IconButton.Tonal
                            icon: "smart_display"
                            onClicked: {
                                Quickshell.execDetached(["/home/faulter/.local/bin/musicRecognition/shazam-action.sh", "youtube", "--title", modelData.title, "--artist", modelData.artist]);
                            }
                        }
                    }
                }
            }
        }

        IconTextButton {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            inactiveColour: Colours.palette.m3surfaceContainerHigh
            inactiveOnColour: Colours.palette.m3onSurface
            verticalPadding: Tokens.padding.small
            text: qsTr("Open Full Log")
            icon: "menu_book"

            onClicked: Quickshell.execDetached(["foot", "--title", "Shazam History", "-e", "sh", "-c", "tac ~/.local/share/shazam_history.txt | bat --paging=always"])
        }
    }
}
