# Xosonic Lite for iOS (iPhone 8+ Edition)

<p align="center">
  <strong>Ultra-lightweight, battery-efficient YouTube Music player for iOS.</strong><br>
  Specially engineered by <strong>XrLabs</strong> for storage and memory-constrained devices (iPhone 8+, iPhone X, iOS 15–16.7).
</p>

---

## ⚡ Highlights

- **3-Song FIFO Rolling Cache**: Keeps at most 3 songs in local storage (`Library/Caches/XosonicSongCache/`). When a 4th song starts caching, the oldest is immediately deleted so your iPhone storage never fills up.
- **Native AVPlayer & Background Audio**: Full background playback with Apple Lock Screen & Control Center media controls (`MPNowPlayingInfoCenter` & `MPRemoteCommandCenter`).
- **Headphone Disconnect Auto-Pause**: Pauses playback when AirPods or wired Lightning EarPods disconnect.
- **Hardware-Optimized for A11 Bionic**: Heavy GPU blur shaders and looping video canvases are suppressed to eliminate overheating and frame drops.
- **Zero-Tracking Privacy**: No third-party analytics or invasive telemetry. Only your local play history is kept on device.
- **Ultra-Small Binary**: ~12 MB lightweight bundle with low RAM footprint (~30 MB).

---

## 📱 Sideloading on iPhone 8+ (100% Free)

You do **not** need a paid Apple Developer account to install Xosonic Lite.

### Method 1: TrollStore (Recommended for iOS 15.0 – 16.6.1)
*Permanent installation, never revokes, no 7-day re-signing!*
1. Download `Xosonic-Lite-iOS.ipa` from [GitHub Actions Artifacts](https://github.com/XezaYT/Xosonic-iOS-Lite/actions) or Releases.
2. Share the file to **TrollStore** on your iPhone.
3. Tap **Install**.

### Method 2: AltStore / Sideloadly (iOS 15.0 – 16.7.x)
1. Install [AltStore](https://altstore.io/) or [Sideloadly](https://sideloadly.io/) on your PC or Mac.
2. Connect your iPhone 8+ with a Lightning cable.
3. Drag and drop `Xosonic-Lite-iOS.ipa` and sign in with any free Apple ID.

---

## 🛠 Project Architecture

```text
XosonicLite/
├── App/
│   └── XosonicLiteApp.swift        # App entry point & background audio init
├── Models/
│   └── Track.swift                 # Song data model & formatting
├── Services/
│   ├── AudioPlayerService.swift    # AVPlayer, Lock Screen controls, headphone events
│   ├── RollingCacheManager.swift   # Strict 3-song rolling FIFO disk cache
│   ├── MusicStreamResolver.swift   # Audio stream search & resolution
│   └── HistoryManager.swift        # Local zero-tracking playback history
├── Views/
│   ├── ContentView.swift           # Tab navigation & persistent mini-player
│   ├── NowPlayingView.swift        # Fullscreen playback UI with cache badge
│   ├── MiniPlayerView.swift        # Bottom scrubber & quick controls
│   ├── SearchView.swift            # Fast music search
│   ├── HistoryView.swift           # Local history view
│   └── SettingsView.swift          # Live rolling cache monitor & hardware stats
└── Resources/
    └── Info.plist                  # Background audio modes & network security
```

---

## 👥 Credits & Attribution

- **Studio**: [XrLabs](https://github.com/XezaYT)
- **Lead Creator**: `beatrix.sql`
- **Upstream Project**: Inspired by and based on [SimpMusic](https://github.com/maxrave-dev/SimpMusic) by `maxrave-dev`.
- **License**: GNU General Public License v3.0 (GPL-3.0).
