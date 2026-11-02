import Foundation

/// Strict 3-Song FIFO Rolling Cache Manager for Xosonic Lite.
/// Designed for storage-constrained devices like iPhone 8+ (64GB / low free space).
/// Ensures that at most 3 songs ever reside in the local disk cache at any moment.
public final class RollingCacheManager: ObservableObject {
    public static let shared = RollingCacheManager()

    public static let maxCachedSongs: Int = 3
    private let fileManager = FileManager.default
    private let cacheDirectoryName = "XosonicSongCache"
    private let queueKey = "xosonic_lite_cached_song_queue"

    @Published public private(set) var currentCacheCount: Int = 0
    @Published public private(set) var totalCacheSizeFormatted: String = "0.0 MB"

    private var cacheDirectory: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent(cacheDirectoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }

    private init() {
        refreshCacheStats()
    }

    /// Returns the local cached audio file URL if available
    public func localCachedFile(for songId: String) -> URL? {
        let fileUrl = cacheDirectory.appendingPathComponent("\(songId).m4a")
        if fileManager.fileExists(atPath: fileUrl.path) {
            return fileUrl
        }
        return nil
    }

    /// Stores a song stream file into the rolling cache and purges the oldest file if cache > 3
    public func saveSongToCache(songId: String, tempFileUrl: URL) -> URL? {
        let targetUrl = cacheDirectory.appendingPathComponent("\(songId).m4a")

        do {
            if fileManager.fileExists(atPath: targetUrl.path) {
                try fileManager.removeItem(at: targetUrl)
            }
            try fileManager.moveItem(at: tempFileUrl, to: targetUrl)

            // Update queue
            var queue = getQueue()
            queue.removeAll { $0 == songId }
            queue.append(songId)

            // Evict oldest (FIFO) if > 3 songs
            while queue.count > Self.maxCachedSongs {
                let oldestId = queue.removeFirst()
                let oldestUrl = cacheDirectory.appendingPathComponent("\(oldestId).m4a")
                try? fileManager.removeItem(at: oldestUrl)
                print("[XosonicLite] RollingCache evicted oldest cached song: \(oldestId)")
            }

            saveQueue(queue)
            refreshCacheStats()
            return targetUrl
        } catch {
            print("[XosonicLite] Cache save error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Manually clears all cached songs
    public func clearAllCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        saveQueue([])
        refreshCacheStats()
        print("[XosonicLite] All rolling cache cleared.")
    }

    public func refreshCacheStats() {
        let queue = getQueue()
        currentCacheCount = queue.count

        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            totalCacheSizeFormatted = "0.0 MB"
            return
        }

        var totalBytes: Int64 = 0
        for file in files {
            if let resources = try? file.resourceValues(forKeys: [.fileSizeKey]), let size = resources.fileSize {
                totalBytes += Int64(size)
            }
        }

        let mb = Double(totalBytes) / (1024 * 1024)
        totalCacheSizeFormatted = String(format: "%.1f MB", mb)
    }

    private func getQueue() -> [String] {
        UserDefaults.standard.stringArray(forKey: queueKey) ?? []
    }

    private func saveQueue(_ queue: [String]) {
        UserDefaults.standard.set(queue, forKey: queueKey)
    }
}
