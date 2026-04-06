import SwiftUI
import AVKit
import FirebaseCore

@main
struct LumiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authService = AuthService.shared
    @StateObject private var router = AppRouter()
    @StateObject private var sensitiveDays = SensitiveDaysService.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    switch router.currentScreen {
                    case .home, .write:
                        ContentView()
                    case .receive:
                        ReceiveMessageView()
                    case .settings:
                        SettingsView()
                    case .vault:
                        VaultView()
                    }
                }
                .environmentObject(authService)
                .environmentObject(router)
                .environmentObject(sensitiveDays)
                .environmentObject(notificationService)
                .overlay {
                    if router.showWrite {
                        writeMessageOverlay
                    }
                }
                .overlay {
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
                }
                .overlay {
                    if notificationService.showPrePermission {
                        NotificationPermissionView()
                            .environmentObject(notificationService)
                            .zIndex(3)
                    }
                }
                .opacity(showSplash ? 0 : 1)
                .onAppear {
                    notificationService.incrementAppOpenCount()
                }

                if showSplash {
                    SplashScreen(isVisible: $showSplash)
                }
            }
        }
    }

    @ViewBuilder
    private var writeMessageOverlay: some View {
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

// MARK: - App Router

enum AppScreen {
    case home, write, receive, settings, vault
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

// MARK: - Splash Screen (Video)

struct SplashScreen: View {
    @Binding var isVisible: Bool
    @State private var player: AVPlayer?
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player {
                VideoPlayerView(player: player)
                    .ignoresSafeArea()
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .onAppear {
            guard let url = Bundle.main.url(forResource: "splash", withExtension: "mp4") else {
                isVisible = false
                return
            }

            let avPlayer = AVPlayer(url: url)
            avPlayer.isMuted = true
            self.player = avPlayer
            avPlayer.play()

            // When video ends, fade out and dismiss
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: avPlayer.currentItem,
                queue: .main
            ) { _ in
                withAnimation(.easeOut(duration: 0.4)) {
                    fadeOut = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isVisible = false
                }
            }
        }
    }
}

// UIKit AVPlayerLayer wrapper for full-screen video without controls
struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(player: player)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private class PlayerUIView: UIView {
        private let playerLayer = AVPlayerLayer()

        init(player: AVPlayer) {
            super.init(frame: .zero)
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(playerLayer)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}
