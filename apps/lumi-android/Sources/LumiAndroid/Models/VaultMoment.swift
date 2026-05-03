import Foundation

/// One archived "vault" entry — a quote the user pinned with the heart button
/// in the receive deck. Mirrors the model defined inline in
/// apps/lumi-ios/Lumi/Views/VaultView.swift; broken out here so VaultViewModel
/// can compile before VaultView is ported (Faz 6).
struct VaultMoment: Identifiable {
    let id: String
    let date: String
    let quote: String
    let tags: [String]
    let imageName: String?
}
