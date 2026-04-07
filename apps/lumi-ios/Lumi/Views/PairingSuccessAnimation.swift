import SwiftUI

// MARK: - Pairing Success Animation ("Zen Garden Bond")
// Full-screen overlay celebrating a successful user pairing.
// Pure SwiftUI — four-phase choreography: orbit, merge, blossom burst, fade out.

struct PairingSuccessAnimation: View {
    @Binding var isPresented: Bool

    // MARK: - Animation State

    @State private var phase: Int = 0

    // Phase 1: Orbiting circles
    @State private var orbitAngle: Double = 0

    // Phase 2: Merging
    @State private var orbitRadius: CGFloat = 100
    @State private var mergeScale: CGFloat = 1.0
    @State private var pulseScale: CGFloat = 0.0
    @State private var pulseOpacity: Double = 0.0

    // Phase 3: Blossom burst + text
    @State private var petalOffsets: [CGSize] = Array(repeating: .zero, count: 15)
    @State private var petalOpacities: [Double] = Array(repeating: 0.0, count: 15)
    @State private var textOpacity: Double = 0.0

    // Phase 4: Fade out
    @State private var overlayOpacity: Double = 1.0

    // Pre-computed petal data for deterministic randomness
    private let petalData: [PetalInfo] = (0..<15).map { _ in
        PetalInfo(
            targetX: CGFloat.random(in: -160...160),
            targetY: CGFloat.random(in: -200...200),
            baseOpacity: Double.random(in: 0.3...0.8),
            size: CGFloat.random(in: 6...10),
            delay: Double.random(in: 0...0.15)
        )
    }

    var body: some View {
        ZStack {
            backdrop
            orbitingCircles
            mergePulse
            blossomPetals
            pairedText
        }
        .opacity(overlayOpacity)
        .ignoresSafeArea()
        .onAppear(perform: beginAnimation)
        .allowsHitTesting(false)
    }

    // MARK: - Background

    private var backdrop: some View {
        Color.black.opacity(0.4)
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
    }

    // MARK: - Phase 1 & 2: Orbiting / Merging Circles

    private var orbitingCircles: some View {
        ZStack {
            singleOrb(angleDelta: 0)
            singleOrb(angleDelta: .pi)
        }
        .scaleEffect(mergeScale)
    }

    private func singleOrb(angleDelta: Double) -> some View {
        let radians = Angle.radians(orbitAngle + angleDelta)
        let x = cos(radians.radians) * Double(orbitRadius)
        let y = sin(radians.radians) * Double(orbitRadius)

        return Circle()
            .fill(LumiTheme.primaryContainer.opacity(0.6))
            .frame(width: 60, height: 60)
            .blur(radius: 8)
            .offset(x: x, y: y)
    }

    // MARK: - Phase 2: Radial Pulse

    private var mergePulse: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        LumiTheme.sparklePink.opacity(0.3),
                        LumiTheme.sparklePink.opacity(0.0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 140
                )
            )
            .frame(width: 280, height: 280)
            .scaleEffect(pulseScale)
            .opacity(pulseOpacity)
    }

    // MARK: - Phase 3: Cherry Blossom Petals

    private var blossomPetals: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { index in
                let info = petalData[index]
                Circle()
                    .fill(LumiTheme.sparklePink)
                    .frame(width: info.size, height: info.size)
                    .opacity(petalOpacities[index])
                    .offset(petalOffsets[index])
            }
        }
    }

    // MARK: - Phase 3: Text Reveal

    private var pairedText: some View {
        VStack(spacing: 12) {
            Text("pair.success.title")
                .font(.custom("NotoSerif-Regular", size: 28))
                .foregroundStyle(LumiTheme.onSurface)

            Text("pair.success.subtitle")
                .font(.custom("PlusJakartaSans-Regular", size: 12))
                .foregroundStyle(LumiTheme.onSurfaceVariant)
                .tracking(2)
        }
        .opacity(textOpacity)
    }

    // MARK: - Animation Choreography

    private func beginAnimation() {
        // Phase 1: Orbit (0s - 1s)
        startOrbit()

        // Phase 2: Merge (1s - 2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startMerge()
        }

        // Phase 3: Blossom burst + text (2s - 3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            startBlossomBurst()
        }

        // Phase 4: Fade out (3s - 3.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            startFadeOut()
        }

        // Dismiss overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            isPresented = false
        }
    }

    // MARK: Phase 1 — Two circles orbiting each other

    private func startOrbit() {
        phase = 1
        withAnimation(
            .linear(duration: 1.0)
                .repeatCount(1, autoreverses: false)
        ) {
            orbitAngle = .pi * 2
        }
    }

    // MARK: Phase 2 — Circles converge and merge

    private func startMerge() {
        phase = 2

        // Collapse orbit radius to zero
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            orbitRadius = 0
        }

        // Scale up the merged orb
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            mergeScale = 1.5
        }

        // Expand the radial pulse
        withAnimation(.easeOut(duration: 0.8)) {
            pulseScale = 1.0
            pulseOpacity = 1.0
        }

        // Fade pulse toward end of phase
        withAnimation(.easeIn(duration: 0.4).delay(0.6)) {
            pulseOpacity = 0.0
        }
    }

    // MARK: Phase 3 — Petals scatter outward, text fades in

    private func startBlossomBurst() {
        phase = 3

        // Shrink the merged orb away
        withAnimation(.easeOut(duration: 0.3)) {
            mergeScale = 0.0
        }

        // Scatter petals outward with staggered timing
        for index in 0..<15 {
            let info = petalData[index]

            // Appear instantly at center
            petalOpacities[index] = info.baseOpacity

            // Animate outward and fade
            withAnimation(
                .spring(response: 0.7, dampingFraction: 0.65)
                    .delay(info.delay)
            ) {
                petalOffsets[index] = CGSize(width: info.targetX, height: info.targetY)
            }

            // Fade out each petal
            withAnimation(
                .easeOut(duration: 0.5)
                    .delay(0.4 + info.delay)
            ) {
                petalOpacities[index] = 0.0
            }
        }

        // Text reveal with gentle spring
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            textOpacity = 1.0
        }
    }

    // MARK: Phase 4 — Everything fades out

    private func startFadeOut() {
        phase = 4
        withAnimation(.easeOut(duration: 0.5)) {
            overlayOpacity = 0.0
        }
    }
}

// MARK: - Petal Data Model

private struct PetalInfo {
    let targetX: CGFloat
    let targetY: CGFloat
    let baseOpacity: Double
    let size: CGFloat
    let delay: Double
}

// MARK: - Preview

struct PairingSuccessAnimation_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AuroraBackground()
            PairingSuccessAnimation(isPresented: .constant(true))
        }
    }
}
