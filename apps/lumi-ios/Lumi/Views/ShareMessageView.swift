import SwiftUI

struct ShareMessageView: View {
    @Environment(\.dismiss) private var dismiss
    let message: String
    let mood: String

    @State private var renderedImage: UIImage?

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.957, green: 0.953, blue: 0.945) // surfaceLow
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Preview card
                    if let image = renderedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                            .shadow(color: Color.black.opacity(0.08), radius: 40, x: 0, y: 20)
                    }

                    shareButton
                        .padding(.horizontal, 44)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color(red: 0.388, green: 0.361, blue: 0.380))
                    }
                }
            }
            .onAppear { renderImage() }
        }
    }

    private var shareButton: some View {
        Button(action: shareImage) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .light))
                Text("SHARE")
                    .font(.custom("PlusJakartaSans-Regular", size: 13))
                    .fontWeight(.medium)
                    .kerning(2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 9999, style: .continuous)
                    .fill(Color(red: 0.388, green: 0.361, blue: 0.380))
            )
        }
    }

    // MARK: - Render

    private func renderImage() {
        let card = ShareCardRenderable(message: message, mood: mood)
            .frame(width: 350, height: 450)

        // Use UIHostingController for reliable rendering (ImageRenderer has gradient bugs)
        let hosting = UIHostingController(rootView: card)
        hosting.view.bounds = CGRect(x: 0, y: 0, width: 350, height: 450)
        hosting.view.backgroundColor = .clear
        hosting.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        let uiRenderer = UIGraphicsImageRenderer(size: CGSize(width: 350, height: 450), format: format)
        renderedImage = uiRenderer.image { ctx in
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }
    }

    // MARK: - Share

    private func shareImage() {
        guard let image = renderedImage else { return }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController { topVC = presented }
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
    }

}

// MARK: - Renderable Share Card (no environment dependencies)

private struct ShareCardRenderable: View {
    let message: String
    let mood: String

    var body: some View {
        ZStack {
            // Solid colors only - no material/environment needed for ImageRenderer
            Color(red: 0.98, green: 0.976, blue: 0.965) // #FAF9F6

            // Pink radial
            RadialGradient(
                colors: [
                    Color(red: 0.992, green: 0.949, blue: 0.973).opacity(0.6),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3, y: 0.2),
                startRadius: 0,
                endRadius: 200
            )

            // Peach radial
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.859, blue: 0.800).opacity(0.4),
                    Color.clear
                ],
                center: UnitPoint(x: 0.7, y: 0.8),
                startRadius: 0,
                endRadius: 200
            )

            VStack(spacing: 28) {
                // Mood pill
                Text(mood.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(red: 0.294, green: 0.271, blue: 0.286))
                    .kerning(2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.6))
                    )

                // Message text
                Text("\u{201C}\(message)\u{201D}")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .lineSpacing(10)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(red: 0.161, green: 0.145, blue: 0.141))
                    .padding(.horizontal, 28)

                // Divider + Lumi signature
                HStack(spacing: 8) {
                    Rectangle().fill(Color(red: 0.992, green: 0.776, blue: 0.678).opacity(0.6)).frame(width: 16, height: 1)
                    Text("Lumi")
                        .font(.system(size: 13, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.7))
                        .kerning(1.8)
                    Rectangle().fill(Color(red: 0.992, green: 0.776, blue: 0.678).opacity(0.6)).frame(width: 16, height: 1)
                }
                .padding(.top, 16)
            }
            .padding(.vertical, 60)
        }
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
    }
}
