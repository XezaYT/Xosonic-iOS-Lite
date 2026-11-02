import SwiftUI

@main
struct XosonicLiteApp: App {
    init() {
        // Initialize background audio session and remote command center
        _ = AudioPlayerService.shared
        _ = RollingCacheManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
