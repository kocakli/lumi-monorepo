import Foundation
import SkipFuse
import SwiftUI
import FirebaseCore

/// A logger for the LumiAndroid module.
let logger: Logger = Logger(subsystem: "com.tease.lumi", category: "LumiAndroid")

/// The shared top-level view for the app, loaded from the platform-specific App delegates below.
/// Mirrors the structure of apps/lumi-ios/Lumi/LumiApp.swift but Android-only —
/// iOS app shell stays untouched at apps/lumi-ios/.
/* SKIP @bridge */public struct LumiAndroidRootView : View {
    // `internal` access (no `private`) — Skip's @bridge annotation requires
    // bridge-visible state to be at least internal so the Compose layer can
    // reach the StateObjects.
    @StateObject var authService = AuthService.shared
    @StateObject var router = AppRouter()
    @StateObject var sensitiveDays = SensitiveDaysService.shared
    @StateObject var notificationService = NotificationService.shared
    @StateObject var pairingVM = PairingViewModel()

    /* SKIP @bridge */public init() {
        // Configure Firebase before any @StateObject lazy-init touches Firebase
        // singletons. App.init() runs before SwiftUI initializes @StateObjects,
        // so this is the right defensive spot.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    public var body: some View {
        ZStack {
            // Active screen — overlays/sheets land on top.
            switch router.currentScreen {
            case .home, .write:
                HomeView()
            case .receive:
                // Placeholder until ReceiveMessageView lands.
                AuroraBackground().overlay(Text("Receive (todo)"))
            case .settings:
                AuroraBackground().overlay(Text("Settings (todo)"))
            case .vault:
                AuroraBackground().overlay(Text("Vault (todo)"))
            case .pairs:
                AuroraBackground().overlay(Text("Pairs (todo)"))
            }
        }
        .environmentObject(authService)
        .environmentObject(router)
        .environmentObject(sensitiveDays)
        .environmentObject(notificationService)
        .environmentObject(pairingVM)
        .task {
            logger.info("Lumi Android boot — uid=\(authService.uid ?? "?")")
            notificationService.incrementAppOpenCount()
            pairingVM.startListening()
        }
    }
}

/// Global application delegate functions.
///
/// These functions can update a shared observable object to communicate app state changes to interested views.
/* SKIP @bridge */public final class LumiAndroidAppDelegate : Sendable {
    /* SKIP @bridge */public static let shared = LumiAndroidAppDelegate()

    private init() {
    }

    /* SKIP @bridge */public func onInit() {
        logger.debug("onInit")
    }

    /* SKIP @bridge */public func onLaunch() {
        logger.debug("onLaunch")
    }

    /* SKIP @bridge */public func onResume() {
        logger.debug("onResume")
    }

    /* SKIP @bridge */public func onPause() {
        logger.debug("onPause")
    }

    /* SKIP @bridge */public func onStop() {
        logger.debug("onStop")
    }

    /* SKIP @bridge */public func onDestroy() {
        logger.debug("onDestroy")
    }

    /* SKIP @bridge */public func onLowMemory() {
        logger.debug("onLowMemory")
    }
}
