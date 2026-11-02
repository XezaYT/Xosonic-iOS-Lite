import Foundation

public final class HistoryManager: ObservableObject {
    public static let shared = HistoryManager()
    private let historyKey = "xosonic_lite_play_history"
    private let maxHistoryItems = 100

    @Published public private(set) var recentTracks: [Track] = []

    private init() {
        loadHistory()
    }

    public func recordPlay(track: Track) {
        var updated = recentTracks.filter { $0.id != track.id }
        updated.insert(track, at: 0)
        if updated.count > maxHistoryItems {
            updated = Array(updated.prefix(maxHistoryItems))
        }
        recentTracks = updated
        saveHistory()
    }

    public func clearHistory() {
        recentTracks = []
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let tracks = try? JSONDecoder().decode([Track].self, from: data) else {
            recentTracks = []
            return
        }
        recentTracks = tracks
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(recentTracks) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}
