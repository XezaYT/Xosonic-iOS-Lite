import SwiftUI
import UniformTypeIdentifiers

public struct SearchView: View {
    @State private var searchText: String = ""
    @State private var results: [Track] = []
    @State private var isLoading: Bool = false
    @State private var showFileImporter: Bool = false
    @ObservedObject var player = AudioPlayerService.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search songs, artists, or mixes...", text: $searchText)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .onSubmit {
                                performSearch()
                            }
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                results = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    if isLoading {
                        Spacer()
                        ProgressView("Searching streams...")
                            .foregroundColor(.white)
                            .tint(.white)
                        Spacer()
                    } else if results.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Discover Music with Xosonic Lite")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Search any track to stream with 3-song rolling cache")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    } else {
                        List(results) { track in
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
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 50, height: 50)
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
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFileImporter = true }) {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.audio, .mp3, .wav, .aiff]
            ) { result in
                switch result {
                case .success(let url):
                    AudioPlayerService.shared.playLocalAudioFile(url: url)
                case .failure(let error):
                    print("[XosonicLite] File importer error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        Task {
            let res = await MusicStreamResolver.shared.searchTracks(query: searchText)
            await MainActor.run {
                self.results = res
                self.isLoading = false
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
                AudioPlayerService.shared.playTrack(streamTrack, in: results)
            }
        }
    }
}
