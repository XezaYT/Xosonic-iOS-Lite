import Foundation

public final class MusicStreamResolver {
    public static let shared = MusicStreamResolver()

    // Default fast public endpoint (can also point to HyperX Engine)
    public var apiBaseUrl: String = "https://pipedapi.kavin.rocks"

    private init() {}

    public func searchTracks(query: String) async -> [Track] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(apiBaseUrl)/search?q=\(encoded)&filter=music_songs") else {
            return fallbackSampleTracks(query: query)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                return fallbackSampleTracks(query: query)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let items = json["items"] as? [[String: Any]] {
                var results: [Track] = []
                for item in items.prefix(20) {
                    if let id = (item["url"] as? String)?.replacingOccurrences(of: "/watch?v=", with: ""),
                       let title = item["title"] as? String,
                       let artist = item["uploaderName"] as? String {
                        let duration = Double(item["duration"] as? Int ?? 180)
                        let thumb = item["thumbnail"] as? String
                        results.append(Track(id: id, title: title, artist: artist, durationSeconds: duration, thumbnailUrl: thumb))
                    }
                }
                if !results.isEmpty { return results }
            }
        } catch {
            print("[XosonicLite] Search network error: \(error.localizedDescription)")
        }

        return fallbackSampleTracks(query: query)
    }

    public func resolveStreamUrl(for songId: String) async -> String? {
        // First check if already cached
        if let cached = RollingCacheManager.shared.localCachedFile(for: songId) {
            return cached.absoluteString
        }

        guard let url = URL(string: "\(apiBaseUrl)/streams/\(songId)") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let audioStreams = json["audioStreams"] as? [[String: Any]] {
                // Find best audio stream (m4a or webm)
                for stream in audioStreams {
                    if let streamUrl = stream["url"] as? String {
                        return streamUrl
                    }
                }
            }
        } catch {
            print("[XosonicLite] Stream resolve error: \(error.localizedDescription)")
        }

        return nil
    }

    private func fallbackSampleTracks(query: String) -> [Track] {
        return [
            Track(id: "xosonic_01", title: "\(query.capitalized) (XrLabs Mix)", artist: "beatrix.sql", durationSeconds: 198, thumbnailUrl: "https://picsum.photos/seed/x1/300/300"),
            Track(id: "xosonic_02", title: "A11 Bionic Flow", artist: "Xosonic Sound", durationSeconds: 242, thumbnailUrl: "https://picsum.photos/seed/x2/300/300"),
            Track(id: "xosonic_03", title: "Low Memory Euphoria", artist: "XrLabs Core", durationSeconds: 215, thumbnailUrl: "https://picsum.photos/seed/x3/300/300"),
            Track(id: "xosonic_04", title: "Rolling Cache Odyssey", artist: "beatrix.sql", durationSeconds: 180, thumbnailUrl: "https://picsum.photos/seed/x4/300/300")
        ]
    }
}
