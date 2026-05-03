import SwiftUI
import Observation

/// Top-level navigation enum + observable router. Mirrors
/// apps/lumi-ios/Lumi/LumiApp.swift's AppRouter, but uses Swift's
/// `@Observable` macro (iOS 17+) instead of `ObservableObject` so the
/// type works on Skip Android — Combine isn't available there.
enum AppScreen {
    case home, write, receive, settings, vault, pairs
}

@Observable
@MainActor
final class AppRouter {
    var currentScreen: AppScreen = .home
    var showWrite = false
    var showMessageSent = false

    func navigate(to screen: AppScreen) {
        if screen == .write {
            showWrite = true
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentScreen = screen
        }
    }

    func goHome() {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentScreen = .home
        }
    }
}
