pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services

Column {
    id: root

    spacing: Tokens.spacing.medium
    width: Tokens.sizes.bar.batteryWidth

    // Level 1 Optimized Reader: 1 single process, zero shell pipes.
    Process {
        id: asusctlProc
        property string currentProfile: "Balanced"
        
        command: ["asusctl", "profile", "get"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split('\n');
                if (lines.length > 0) {
                    let p = lines[0].replace("Active profile:", "").trim();
                    if (p === "Quiet" || p === "Balanced" || p === "Performance") {
                        asusctlProc.currentProfile = p;
                    }
                }
            }
        }
    }

    // Relaxed Timer: Polling every 15 seconds instead of 5 to save CPU
    Timer {
        interval: 15000 
        running: true
        repeat: true
        onTriggered: asusctlProc.running = true
    }

    // Dedicated Writer Process
    Process {
        id: asusctlSetProc
        property string targetProfile: ""
        command: ["sh", "-c", "asusctl profile set " + targetProfile]
        running: false 
    }

    // Function to trigger the writer and update UI optimistically
    function setAsusctlProfile(profileName: string): void {
        asusctlSetProc.targetProfile = profileName;
        asusctlSetProc.running = true;
        asusctlProc.currentProfile = profileName;
    }

    StyledText {
        text: UPower.displayDevice.isLaptopBattery ? qsTr("Remaining: %1%").arg(Math.round(UPower.displayDevice.percentage * 100)) : qsTr("No battery detected")
    }

    StyledText {
        function formatSeconds(s: int, fallback: string): string {
            const day = Math.floor(s / 86400);
            const hr = Math.floor(s / 3600) % 24;
            const min = Math.floor(s / 60) % 60;

            let comps = [];
            if (day > 0)
                comps.push(`${day} days`);
            if (hr > 0)
                comps.push(`${hr} hours`);
            if (min > 0)
                comps.push(`${min} mins`);

            return comps.join(", ") || fallback;
        }

        text: UPower.displayDevice.isLaptopBattery ? qsTr("Time %1: %2").arg(UPower.onBattery ? "remaining" : "until charged").arg(UPower.onBattery ? formatSeconds(UPower.displayDevice.timeToEmpty, "Calculating...") : formatSeconds(UPower.displayDevice.timeToFull, "Fully charged!")) : qsTr("Power profile: %1").arg(asusctlProc.currentProfile)
    }

    StyledRect {
        id: profiles

        property string current: {
            const p = asusctlProc.currentProfile;
            if (p === "Quiet")
                return saver.icon;
            if (p === "Performance")
                return perf.icon;
            return balance.icon;
        }

        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: saver.implicitHeight + balance.implicitHeight + perf.implicitHeight + Tokens.padding.medium * 2 + Tokens.spacing.largeIncreased * 2
        implicitHeight: Math.max(saver.implicitHeight, balance.implicitHeight, perf.implicitHeight) + Tokens.padding.small

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full

        StyledRect {
            id: indicator

            color: Colours.palette.m3primary
            radius: Tokens.rounding.full
            state: profiles.current

            states: [
                State {
                    name: saver.icon
                    Fill {
                        item: saver
                        targetItem: indicator
                    }
                },
                State {
                    name: balance.icon
                    Fill {
                        item: balance
                        targetItem: indicator
                    }
                },
                State {
                    name: perf.icon
                    Fill {
                        item: perf
                        targetItem: indicator
                    }
                }
            ]

            transitions: Transition {
                AnchorAnim {}
            }
        }

        Profile {
            id: saver

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.extraSmall

            profileName: "Quiet"
            icon: "energy_savings_leaf"
            currentProfile: profiles.current
            onSwitched: function(name) {
                root.setAsusctlProfile(name);
            }
        }

        Profile {
            id: balance

            anchors.centerIn: parent

            profileName: "Balanced"
            icon: "balance"
            currentProfile: profiles.current
            onSwitched: function(name) {
                root.setAsusctlProfile(name);
            }
        }

        Profile {
            id: perf

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.extraSmall

            profileName: "Performance"
            icon: "rocket_launch"
            currentProfile: profiles.current
            onSwitched: function(name) {
                root.setAsusctlProfile(name);
            }
        }
    }

    component Fill: AnchorChanges {
        required property Item item
        required property Item targetItem

        target: targetItem
        anchors.left: item.left
        anchors.right: item.right
        anchors.top: item.top
        anchors.bottom: item.bottom
    }

    component Profile: Item {
        required property string icon
        required property string profileName
        required property string currentProfile

        signal switched(name: string)

        implicitWidth: iconItem.implicitHeight + Tokens.padding.small
        implicitHeight: iconItem.implicitHeight + Tokens.padding.small

        StateLayer {
            radius: Tokens.rounding.full
            color: parent.currentProfile === parent.icon ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: {
                parent.switched(parent.profileName);
            }
        }

        MaterialIcon {
            id: iconItem

            anchors.centerIn: parent

            text: parent.icon
            fontStyle: Tokens.font.icon.large
            color: parent.currentProfile === text ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            fill: parent.currentProfile === text ? 1 : 0

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
