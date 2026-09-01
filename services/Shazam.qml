pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Caelestia
import Caelestia.Config
import qs.services

Singleton {
    id: root

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.identity === "Shazam") ?? null
    readonly property bool isAvailable: player !== null
    readonly property bool isListening: player?.playbackState === MprisPlaybackState.Playing
    readonly property string status: !isAvailable ? "offline" : (isListening ? (hasSong ? "found" : "ambient") : "paused")

    readonly property bool hasSong: (player?.trackTitle ?? "").length > 0 && (player?.trackTitle ?? "") !== "Shazam Active"
    readonly property string title: hasSong ? (player?.trackTitle ?? "") : ""
    readonly property string artist: hasSong ? (player?.trackArtist ?? "") : ""
    readonly property string album: hasSong ? (player?.metadata["xesam:album"] ?? "") : ""
    readonly property string genre: hasSong ? (player?.metadata["xesam:genre"] ?? "") : ""
    readonly property string artUrl: hasSong ? (player?.trackArtUrl ?? "") : ""
    readonly property string previewUrl: hasSong ? (player?.metadata["shazam:previewUrl"] ?? "") : ""
    readonly property string isrc: hasSong ? (player?.metadata["shazam:isrc"] ?? "") : ""

    property list<var> history: []
    property bool isDownloading: false
    property string downloadStatus: ""

    function toggle(): void {
        if (player) {
            player.togglePlaying();
        } else {
            // If daemon is not started, launch it
            launchProc.running = true;
        }
    }

    function downloadCurrent(): void {
        if (!hasSong || isDownloading) return;
        downloadTrack(title, artist);
    }

    function downloadTrack(t: string, a: string): void {
        if (isDownloading) return;
        isDownloading = true;
        downloadStatus = "downloading";
        downloadProc.command = ["shazam-daemon", "--download", t, a];
        downloadProc.running = true;
    }

    function playPreview(): void {
        if (!previewUrl) return;
        previewProc.command = ["mpv", "--no-video", "--volume=80", previewUrl];
        previewProc.running = true;
    }

    function reloadHistory(): void {
        historyProc.running = true;
    }

    Process {
        id: launchProc
        command: ["shazam-daemon"]
    }

    Process {
        id: previewProc
    }

    Process {
        id: downloadProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.isDownloading = false;
                if (text.includes("Saved to:")) {
                    root.downloadStatus = "done";
                    Notifs.toast("Shazam", `✅ Downloaded: ${root.title}\nSaved in ~/Music/ShazamLive`, "audio-x-generic");
                } else {
                    root.downloadStatus = "error";
                    Notifs.toast("Shazam", `❌ Download failed`, "dialog-error");
                }
            }
        }
    }

    Process {
        id: historyProc
        command: ["sh", "-c", "touch ~/.local/share/shazam_history.jsonl && tail -n 10 ~/.local/share/shazam_history.jsonl | tac"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let lines = text.trim().split('\n').filter(l => l.length > 0);
                    root.history = lines.map(JSON.parse);
                } catch(e) {
                    root.history = [];
                }
            }
        }
    }

    // Refresh history when track changes
    onTitleChanged: {
        if (hasSong) {
            reloadHistory();
        }
    }
}
