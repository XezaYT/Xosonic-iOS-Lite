import SwiftUI

public struct SettingsView: View {
    @ObservedObject var cache = RollingCacheManager.shared
    @State private var showingClearAlert: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    // ROLLING CACHE SECTION
                    Section {
                        HStack {
                            Label("Cache Budget", systemImage: "internaldrive.fill")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(cache.currentCacheCount) / 3 Songs")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Label("Disk Used", systemImage: "chart.bar.fill")
                                .foregroundColor(.white)
                            Spacer()
                            Text(cache.totalCacheSizeFormatted)
                                .foregroundColor(.secondary)
                        }

                        Button(role: .destructive, action: {
                            showingClearAlert = true
                        }) {
                            Label("Purge Song Cache", systemImage: "trash.fill")
                        }
                    } header: {
                        Text("3-Song Rolling FIFO Cache")
                    } footer: {
                        Text("Xosonic Lite keeps at most 3 songs in storage. Whenever a 4th song is cached, the oldest one is automatically deleted to keep your iPhone 8+ storage lean.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    // HARDWARE PROFILE SECTION
                    Section(header: Text("Hardware Profile (iPhone 8+)")) {
                        HStack {
                            Label("Profile Mode", systemImage: "cpu.fill")
                                .foregroundColor(.white)
                            Spacer()
                            Text("Lite (A11 Bionic)")
                                .foregroundColor(.green)
                        }

                        HStack {
                            Label("Heavy Compute Shaders", systemImage: "sparkles")
                                .foregroundColor(.white)
                            Spacer()
                            Text("Disabled")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Label("Looping Video Canvases", systemImage: "video.slash.fill")
                                .foregroundColor(.white)
                            Spacer()
                            Text("Disabled")
                                .foregroundColor(.secondary)
                        }
                    }

                    // PRIVACY SECTION
                    Section(header: Text("Privacy Policy")) {
                        HStack {
                            Label("Telemetry Guard", systemImage: "shield.lefthalf.filled")
                                .foregroundColor(.white)
                            Spacer()
                            Text("Active")
                                .foregroundColor(.green)
                        }

                        HStack {
                            Label("External Tracking", systemImage: "eye.slash.fill")
                                .foregroundColor(.white)
                            Spacer()
                            Text("Zero Tracking")
                                .foregroundColor(.secondary)
                        }
                    }

                    // CREDITS SECTION
                    Section(header: Text("Credits & Attribution")) {
                        HStack {
                            Text("Studio")
                                .foregroundColor(.white)
                            Spacer()
                            Text("XrLabs")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Lead Creator")
                                .foregroundColor(.white)
                            Spacer()
                            Text("beatrix.sql")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Upstream Core")
                                .foregroundColor(.white)
                            Spacer()
                            Text("SimpMusic (maxrave-dev)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("License")
                                .foregroundColor(.white)
                            Spacer()
                            Text("GPL-3.0")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Purge Song Cache?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Purge", role: .destructive) {
                    cache.clearAllCache()
                }
            } message: {
                Text("All locally cached songs will be deleted immediately.")
            }
        }
    }
}
