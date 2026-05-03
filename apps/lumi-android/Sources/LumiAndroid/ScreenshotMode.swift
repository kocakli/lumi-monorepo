import Foundation

/// iOS uses ScreenshotMode (DEBUG-only launch arg `-LumiScreenshotMode`) to
/// drive the App Store screenshot pipeline by injecting fixed localized
/// sample data and skipping live Firebase calls. Android doesn't need this:
/// Play Store screenshots are produced from real builds via fastlane
/// metadata, and Skip's release builds strip DEBUG anyway.
///
/// This stub keeps source parity with the iOS port — call sites can read
/// `ScreenshotMode.isEnabled` (always false on Android) and the sample-data
/// branches simply never execute. Sample property accessors return empty
/// values so the compiler stays happy if any caller somehow reaches them.
enum ScreenshotMode {
    static var isEnabled: Bool { false }
    static var screen: String { "home" }
    static var language: String { "en" }
    static var writeDraft: String { "" }
    static var sampleFeed: [LumiMessage] { [] }
    static var vaultMoments: [VaultMoment] { [] }
    static var pairs: [PairedUser] { [] }
    static var incomingRequests: [PairRequest] { [] }
    static var shareMessage: String { "" }
    static var shareMood: String { "" }
}
