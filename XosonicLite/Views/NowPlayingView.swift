import SwiftUI

public struct NowPlayingView: View {
    @ObservedObject var player = AudioPlayerService.shared
    @ObservedObject var cache = RollingCacheManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isDraggingSlider: Bool = false
    @State private var dragSliderValue: Double = 0

    public init() {}

    public var body: some View {
        ZStack {
            // Elegant dark background with soft gradient
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.12), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Top grabber & close
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("PLAYING FROM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("Xosonic Lite")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Cache status badge
                    if let track = player.currentTrack, cache.localCachedFile(for: track.id) != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("Cached (3-Song FIFO)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                    } else {
                        Color.clear.frame(width: 40, height: 20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // Large Album Art
                if let track = player.currentTrack, let thumb = track.thumbnailUrl, let url = URL(string: thumb) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(Image(systemName: "music.note").font(.system(size: 48)).foregroundColor(.white.opacity(0.3)))
                    }
                    .frame(maxWidth: 320, maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                        .frame(maxWidth: 320, maxHeight: 320)
                        .overlay(Image(systemName: "music.note").font(.system(size: 48)).foregroundColor(.white.opacity(0.3)))
                }

                Spacer()

                // Track Metadata
                if let track = player.currentTrack {
                    VStack(spacing: 6) {
                        Text(track.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)

                        Text(track.artist)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 24)
                }

                // Scrubber Slider
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { isDraggingSlider ? dragSliderValue : player.currentTime },
                            set: { dragSliderValue = $0 }
                        ),
                        in: 0...max(player.duration, 1),
                        onEditingChanged: { editing in
                            isDraggingSlider = editing
                            if !editing {
                                player.seek(to: dragSliderValue)
                            }
                        }
                    )
                    .accentColor(.white)

                    HStack {
                        Text(formatTime(isDraggingSlider ? dragSliderValue : player.currentTime))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(formatTime(player.duration))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 28)

                // Playback Controls
                HStack(spacing: 40) {
                    Button(action: { player.playPrevious() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }

                    Button(action: { player.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 68, height: 68)
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.black)
                                .offset(x: player.isPlaying ? 0 : 2)
                        }
                    }

                    Button(action: { player.playNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 12)

                Spacer()
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
