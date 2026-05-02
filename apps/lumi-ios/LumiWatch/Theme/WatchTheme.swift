import SwiftUI

/// Watch-portable subset of LumiTheme. Aurora gradients and `ultraThinMaterial`
/// are deliberately absent — those rendering paths are GPU-heavy on Apple
/// Watch S6/S7-class hardware and don't translate well to a 1.5"–1.9" canvas.
enum WatchTheme {
    // Cream parchment — same as iPhone background base
    static let cream = Color(red: 0.98, green: 0.976, blue: 0.965)        // #FAF9F6

    // Warm ink — message foreground
    static let ink = Color(red: 0.161, green: 0.145, blue: 0.141)         // #292524

    // Brand peach used for the "Lumi" wordmark / accents
    static let brand = Color(red: 0.475, green: 0.314, blue: 0.239)       // #79503D

    // Dusty divider line color
    static let divider = Color(red: 0.992, green: 0.776, blue: 0.678).opacity(0.6)

    // Soft pink wash for a subtle vertical lift behind cards
    static let blush = Color(red: 0.992, green: 0.949, blue: 0.973)       // #FDF2F8

    /// Static cream-to-blush vertical gradient. Replaces aurora — single
    /// pass, no blur, no animations. Looks intentional on a small canvas.
    static let backgroundGradient = LinearGradient(
        colors: [cream, blush],
        startPoint: .top,
        endPoint: .bottom
    )

    /// NotoSerifDisplay Light at the requested size. Falls back to the
    /// system serif if the font asset is missing (e.g. preview canvas on
    /// a clean checkout before fonts are embedded).
    static func displayFont(size: CGFloat) -> Font {
        if let _ = UIFont(name: "NotoSerifDisplay-Light", size: size) {
            return .custom("NotoSerifDisplay-Light", size: size)
        }
        return .system(size: size, weight: .light, design: .serif)
    }

    /// PlusJakartaSans Regular at the requested size. Used for the small
    /// "Lumi" wordmark / metadata.
    static func bodyFont(size: CGFloat) -> Font {
        if let _ = UIFont(name: "PlusJakartaSans-Regular", size: size) {
            return .custom("PlusJakartaSans-Regular", size: size)
        }
        return .system(size: size, weight: .regular, design: .default)
    }
}
