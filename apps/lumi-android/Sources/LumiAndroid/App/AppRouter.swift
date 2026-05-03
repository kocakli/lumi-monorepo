import SwiftUI

/// Top-level navigation enum + observable router. Mirrors
/// apps/lumi-ios/Lumi/LumiApp.swift's AppRouter — the screens are kept
/// platform-symmetric so views can be ported across without rename churn.
enum AppScreen {
    case home, write, receive, settings, vault, pairs
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var currentScreen: AppScreen = .home
    @Published var showWrite = false
    @Published var showMessageSent = false

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
