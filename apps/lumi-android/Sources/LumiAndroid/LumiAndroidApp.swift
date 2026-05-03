import Foundation
import SkipFuse
import SwiftUI
#if os(Android)
import SkipFirebaseCore
#else
import FirebaseCore
#endif

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
            // Active screen
            Group {
                switch router.currentScreen {
                case .home, .write:
                    HomeView()
                case .receive:
                    ReceiveMessageView()
                case .settings:
                    SettingsView()
                case .vault:
                    VaultView()
                case .pairs:
                    PairsListView()
                }
            }

            // Write modal overlay
            if router.showWrite {
                writeMessageOverlay
            }

            // Message-sent celebration
            if router.showMessageSent {
                MessageSentView(onDismiss: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        router.showMessageSent = false
                    }
                    router.goHome()
                })
                .transition(.opacity)
                .zIndex(2)
            }

            // Notification permission pre-prompt
            if notificationService.showPrePermission {
                NotificationPermissionView()
                    .zIndex(3)
            }

            // Pair message banner (top)
            if let pairMsg = pairingVM.inAppPairMessage {
                VStack {
                    PairMessageBanner(
                        message: pairMsg,
                        onView: {
                            pairingVM.dismissPairMessage()
                            router.navigate(to: .receive)
                        },
                        onDismiss: { pairingVM.dismissPairMessage() }
                    )
                    Spacer()
                }
                .zIndex(4)
            }

            // Pair request banner (top)
            if let request = pairingVM.inAppRequest {
                VStack {
                    PairRequestBanner(
                        code: request.fromUserCode,
                        onAccept: { Task { await pairingVM.acceptRequest(request.id) } },
                        onDecline: { Task { await pairingVM.rejectRequest(request.id) } },
                        onDismiss: { pairingVM.dismissInAppRequest() }
                    )
                    Spacer()
                }
                .zIndex(4)
            }

            // Pairing success animation
            if pairingVM.pairingSuccess {
                PairingSuccessAnimation(isPresented: $pairingVM.pairingSuccess)
                    .zIndex(5)
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

    @ViewBuilder
    var writeMessageOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35)) {
                        router.showWrite = false
                    }
                }

            WriteMessageView()
                .environmentObject(authService)
                .environmentObject(router)
                .frame(maxHeight: 580)
                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                .shadow(
                    color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.12),
                    radius: 40, x: 0, y: 20
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: router.showWrite)
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
