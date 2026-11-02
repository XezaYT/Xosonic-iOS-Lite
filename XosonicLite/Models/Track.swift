import Foundation

public struct Track: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let artist: String
    public let durationSeconds: Double
    public let thumbnailUrl: String?
    public var streamUrl: String?
    public let addedAt: Date

    public init(
        id: String,
        title: String,
        artist: String,
        durationSeconds: Double = 0,
        thumbnailUrl: String? = nil,
        streamUrl: String? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.durationSeconds = durationSeconds
        self.thumbnailUrl = thumbnailUrl
        self.streamUrl = streamUrl
        self.addedAt = addedAt
    }

    public var formattedDuration: String {
        let minutes = Int(durationSeconds) / 60
        let seconds = Int(durationSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    public static func sample() -> Track {
        Track(
            id: "sample_01",
            title: "Midnight Echoes",
            artist: "XrLabs Soundscapes",
            durationSeconds: 214,
            thumbnailUrl: "https://picsum.photos/seed/xosonic/300/300"
        )
    }
}
