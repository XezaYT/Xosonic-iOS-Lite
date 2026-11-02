import SwiftUI

public struct HistoryView: View {
    @ObservedObject var history = HistoryManager.shared
    @ObservedObject var player = AudioPlayerService.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if history.recentTracks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No Listening History")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Your locally played songs will appear here.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    List {
                        ForEach(history.recentTracks) { track in
                            Button(action: {
                                playTrack(track)
                            }) {
                                HStack(spacing: 14) {
                                    if let thumb = track.thumbnailUrl, let url = URL(string: thumb) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.white.opacity(0.1)
                                        }
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 48, height: 48)
                                            .overlay(Image(systemName: "music.note").foregroundColor(.white.opacity(0.4)))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(player.currentTrack?.id == track.id ? .green : .white)
                                            .lineLimit(1)
                                        Text(track.artist)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.6))
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text(track.formattedDuration)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !history.recentTracks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            history.clearHistory()
                        }
                        .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        }
    }

    private func playTrack(_ track: Track) {
        Task {
            var streamTrack = track
            if streamTrack.streamUrl == nil {
                if let stream = await MusicStreamResolver.shared.resolveStreamUrl(for: track.id) {
                    streamTrack.streamUrl = stream
                }
            }
            await MainActor.run {
                AudioPlayerService.shared.playTrack(streamTrack, in: history.recentTracks)
            }
        }
    }
}
