import SwiftUI

public struct MiniPlayerView: View {
    @ObservedObject var player = AudioPlayerService.shared
    @Binding var isPresentingNowPlaying: Bool

    public init(isPresentingNowPlaying: Binding<Bool>) {
        self._isPresentingNowPlaying = isPresentingNowPlaying
    }

    public var body: some View {
        if let track = player.currentTrack {
            VStack(spacing: 0) {
                // Progress line
                GeometryReader { geo in
                    let progress = player.duration > 0 ? (player.currentTime / player.duration) : 0
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 2)
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * CGFloat(progress), height: 2)
                    }
                }
                .frame(height: 2)

                HStack(spacing: 12) {
                    // Artwork
                    if let thumb = track.thumbnailUrl, let url = URL(string: thumb) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.secondary.opacity(0.2)
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        Text(track.artist)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Play/Pause button
                    Button(action: {
                        player.togglePlayPause()
                    }) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                    }

                    // Next track
                    Button(action: {
                        player.playNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isPresentingNowPlaying = true
            }
        }
    }
}
