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

    property bool isListening: player ? (player.playbackState === MprisPlaybackState.Playing) : stateActive
    property bool stateActive: false

    property string status: !stateActive && !isListening ? "paused" : (hasSong ? "found" : "ambient")

    readonly property bool hasSong: title.length > 0
    property string title: ""
    property string artist: ""
    property string album: ""
    property string genre: ""
    property string artUrl: ""
    property string previewUrl: ""

    property list<var> history: []
    property bool isDownloading: false
    property string downloadStatus: ""

    function toggle(): void {
        toggleProc.running = true;
    }

    function downloadCurrent(): void {
        if (!hasSong || isDownloading) return;
        downloadTrack(title, artist);
    }

    function downloadTrack(t: string, a: string): void {
        if (!t || isDownloading) return;
        isDownloading = true;
        downloadStatus = "downloading";
        downloadProc.command = ["shazam-daemon", "--download", t, a];
        downloadProc.running = true;
    }

    function playPreview(url: string): void {
        let streamUrl = url || previewUrl;
        if (!streamUrl) return;
        previewProc.command = ["mpv", "--no-video", "--volume=85", streamUrl];
        previewProc.running = true;
    }

    function reloadState(): void {
        stateProc.running = true;
        historyProc.running = true;
    }

    Process {
        id: toggleProc
        command: ["shazam-daemon", "--toggle"]
        onExited: root.reloadState()
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
                    Notifs.toast("Shazam", `✅ Downloaded: ${root.title}\nSaved to ~/Music/ShazamLive`, "audio-x-generic");
                } else {
                    root.downloadStatus = "error";
                    Notifs.toast("Shazam", `❌ Download failed: ${text.trim()}`, "dialog-error");
                }
            }
        }
    }

    // Read active state & current song from files synchronously
    Process {
        id: stateProc
        command: ["sh", "-c", "test -f /tmp/waybar-shazam-state && echo active || echo paused; cat /tmp/waybar-shazam-current 2>/dev/null || true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split('\n');
                let state = lines[0] ? lines[0].trim() : "paused";
                root.stateActive = (state === "active");

                if (lines.length > 1 && lines[1].includes(" - ")) {
                    let parts = lines[1].split(" - ");
                    root.title = parts[0].trim();
                    root.artist = parts.slice(1).join(" - ").trim();
                } else {
                    root.title = "";
                    root.artist = "";
                }
            }
        }
    }

    // Read full JSON history
    Process {
        id: historyProc
        command: ["sh", "-c", "touch ~/.local/share/shazam_history.jsonl && tail -n 6 ~/.local/share/shazam_history.jsonl | tac"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let lines = text.trim().split('\n').filter(l => l.length > 0);
                    let parsed = lines.map(JSON.parse);
                    root.history = parsed;

                    // Update artwork & album info from top history match if current song matches
                    if (parsed.length > 0 && root.title.length > 0) {
                        let match = parsed.find(item => item.title === root.title || item.artist === root.artist);
                        if (match) {
                            root.album = match.album || "";
                            root.genre = match.genre || "";
                            root.artUrl = match.cover_art || "";
                            root.previewUrl = match.preview_url || "";
                        }
                    }
                } catch(e) {
                    root.history = [];
                }
            }
        }
    }

    // Periodic check to keep state in sync
    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.reloadState()
    }
}
