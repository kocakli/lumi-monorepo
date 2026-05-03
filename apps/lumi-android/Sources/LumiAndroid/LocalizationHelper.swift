import Foundation

extension String {
    /// Cross-platform localized string lookup.
    /// - iOS / macOS: Foundation's `String(localized:)` (resolves against
    ///   the module's xcstrings).
    /// - Skip Android: Foundation `String(localized:)` is not yet exposed
    ///   through SkipFoundation, so we fall back to the raw key. The
    ///   xcstrings are still bundled and usable through SwiftUI `Text`,
    ///   which accepts a `LocalizedStringKey` directly.
    static func L(_ key: String) -> String {
        #if os(Android)
        return key
        #else
        return String(localized: String.LocalizationValue(key))
        #endif
    }
}
