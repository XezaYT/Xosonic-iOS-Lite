import SwiftUI

public struct ContentView: View {
    @ObservedObject var player = AudioPlayerService.shared
    @State private var isPresentingNowPlaying: Bool = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .accentColor(.white)

            // Bottom Mini Player
            if player.currentTrack != nil {
                MiniPlayerView(isPresentingNowPlaying: $isPresentingNowPlaying)
                    .padding(.bottom, 49) // Just above the TabBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isPresentingNowPlaying) {
            NowPlayingView()
        }
    }
}
