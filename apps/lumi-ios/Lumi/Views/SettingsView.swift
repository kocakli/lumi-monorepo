import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter

    @EnvironmentObject var notificationService: NotificationService
    @State private var stealthMode = false
    @EnvironmentObject var sensitiveDays: SensitiveDaysService
    @State private var isShowingSupport = false
    @State private var showDatePicker = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LumiTheme.background
                    .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    stickyHeader

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 64) {
                            heroSection
                            privateConnectionCard
                            pairSanctuaryCard
                            preferencesSection
                            sensitiveDaysCard
                            dangerZone
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 48)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $isShowingSupport) {
                SupportView()
            }
        }
        .offset(x: dragOffset)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // Only activate from left edge + primarily horizontal movement
                    if value.startLocation.x < 25
                        && value.translation.width > 0
                        && abs(value.translation.width) > abs(value.translation.height) * 2 {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    if dragOffset > 120 {
                        router.goHome()
                    } else {
                        withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                    }
                }
        )
    }

    // MARK: - Sticky Header

    private var stickyHeader: some View {
        LumiHeader(
            leftIcon: "icon-close",
            onLeftTap: { router.goHome() },
            onRightTap: { router.navigate(to: .vault) }
        )
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.custom("NotoSerif-Regular", size: 48))
                .foregroundStyle(Color(red: 0.388, green: 0.361, blue: 0.380))

            Text("YOUR DIGITAL SANCTUARY")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundStyle(Color(red: 0.294, green: 0.271, blue: 0.286))
                .tracking(2)
                .textCase(.uppercase)
        }
    }

    // MARK: - Private Connection Card

    private var privateConnectionCard: some View {
        VStack(spacing: 32) {
            privateConnectionHeader
            privateConnectionCodeBox
            copyCodeButton
            etherealImageSection
        }
        .padding(33)
        .zenGlass(cornerRadius: 48, opacity: 0.3)
    }

    private var privateConnectionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Private Connection")
                .font(.custom("NotoSerif-Regular", size: 24))
                .foregroundStyle(Color(red: 0.388, green: 0.361, blue: 0.380))

            Text("Securely sync your presence without sharing your identity.")
                .font(.custom("PlusJakartaSans-Light", size: 14))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var privateConnectionCodeBox: some View {
        VStack(spacing: 12) {
            Text("MY PRIVATE CODE")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
                .tracking(1)
                .textCase(.uppercase)

            Text("LUMI-84X2")
                .font(.custom("NotoSerif-Regular", size: 30))
                .foregroundStyle(LumiTheme.secondary)
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var copyCodeButton: some View {
        Button(action: {
            UIPasteboard.general.string = "LUMI-84X2"
        }) {
            Text("COPY CODE")
                .font(.custom("PlusJakartaSans-Regular", size: 12))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color(red: 0.459, green: 0.427, blue: 0.451))
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.992, green: 0.949, blue: 0.973))
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }

    private var etherealImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            Image("ethereal-abstract")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 160)
                .opacity(0.8)
                .clipped()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.8),
                    Color.white.opacity(0)
                ],
                startPoint: .bottom,
                endPoint: .top
            )

            Text("Connecting minds through the beauty of shared silence.")
                .font(.custom("PlusJakartaSans-Italic", size: 11))
                .foregroundStyle(LumiTheme.secondary)
                .padding(24)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Pair Your Sanctuary Card

    private var pairSanctuaryCard: some View {
        VStack(spacing: 24) {
            pairSanctuaryHeader
            pairDeviceButton
        }
        .padding(33)
        .frame(maxWidth: .infinity, alignment: .center)
        .zenGlass(cornerRadius: 48, opacity: 0.3)
    }

    private var pairSanctuaryHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.992, green: 0.949, blue: 0.973).opacity(0.5))
                    .frame(width: 56, height: 56)

                Image("icon-link")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundStyle(Color(red: 0.388, green: 0.361, blue: 0.380))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Pair Your Sanctuary")
                    .font(.custom("NotoSerif-Regular", size: 24))
                    .foregroundStyle(Color(red: 0.388, green: 0.361, blue: 0.380))

                Text("Link another device to your mindful space.")
                    .font(.custom("PlusJakartaSans-Light", size: 14))
                    .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pairDeviceButton: some View {
        NavigationLink(destination: ConnectionCodeView()) {
            Text("PAIR DEVICE")
                .font(.custom("PlusJakartaSans-Regular", size: 12))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color(red: 0.102, green: 0.110, blue: 0.102))
        }
        .padding(.horizontal, 33)
        .padding(.vertical, 17)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: LumiTheme.cardShadow, radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Preferences")
                .font(.custom("NotoSerif-Regular", size: 24))
                .foregroundStyle(Color(red: 0.388, green: 0.361, blue: 0.380))
                .padding(.horizontal, 16)

            preferencesCard
        }
    }

    private var preferencesCard: some View {
        VStack(spacing: 8) {
            notificationsRow
            stealthModeRow
        }
        .padding(17)
        .zenGlass(cornerRadius: 48, opacity: 0.3)
    }

    private var notificationsRow: some View {
        NavigationLink(destination: NotificationSettingsView()) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LumiTheme.primaryContainer)
                        .frame(width: 48, height: 48)

                    Image("icon-bell")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(LumiTheme.onSurface)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications")
                        .font(.custom("PlusJakartaSans-Regular", size: 14))
                        .fontWeight(.medium)
                        .foregroundStyle(LumiTheme.onSurface)

                    Text("Gentle reminders and soft pings")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400).opacity(0.7))
                }

                Spacer()

                Text(notificationService.frequency == 0 ? "Off" : "\(notificationService.frequency)/day")
                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                    .foregroundStyle(LumiTheme.mutedText)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(LumiTheme.mutedText.opacity(0.5))
            }
        }
        .padding(24)
    }

    private var stealthModeRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LumiTheme.primaryContainer)
                    .frame(width: 48, height: 48)

                Image("icon-eye-slash")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LumiTheme.onSurface)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Stealth Mode")
                    .font(.custom("PlusJakartaSans-Regular", size: 14))
                    .fontWeight(.medium)
                    .foregroundStyle(LumiTheme.onSurface)

                Text("Browse without leaving a trace")
                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                    .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400).opacity(0.7))
            }

            Spacer()

            Toggle("", isOn: $stealthMode)
                .tint(LumiTheme.secondary)
                .labelsHidden()
        }
        .padding(24)
    }

    // MARK: - Sensitive Days Mode Card

    private var sensitiveDaysCard: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative blur circle
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 256, height: 256)
                .blur(radius: 32)
                .offset(x: 80, y: -60)

            sensitiveDaysContent
        }
        .padding(33)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.992, green: 0.949, blue: 0.973),
                            Color(red: 0.988, green: 0.906, blue: 0.953)
                        ],
                        startPoint: UnitPoint(x: 0.3, y: 0),
                        endPoint: UnitPoint(x: 0.7, y: 1)
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: LumiTheme.cardShadow, radius: 25, x: 0, y: 20)
        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
    }

    private var sensitiveDaysContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Badge
            sensitiveDaysBadge

            // Title
            Text("Sensitive Days Mode")
                .font(.custom("NotoSerif-Regular", size: 30))
                .foregroundStyle(LumiTheme.onSurface)
                .padding(.top, 44)

            // Description
            Text("Adjust the kind of messages you receive during sensitive times. We'll send gentler, more nurturing words.")
                .font(.custom("PlusJakartaSans-Regular", size: 14))
                .foregroundStyle(Color(red: 0.341, green: 0.325, blue: 0.306))
                .lineSpacing(8.75)
                .padding(.top, 16)

            // Bottom row
            sensitiveDaysToggleRow
                .padding(.top, 24)

            // Configuration panel — appears when enabled
            if sensitiveDays.isEnabled {
                sensitiveDaysConfig
                    .padding(.top, 28)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: sensitiveDays.isEnabled)
    }

    private var sensitiveDaysBadge: some View {
        HStack(spacing: 8) {
            Image("icon-heart-care")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundStyle(Color(red: 0.925, green: 0.286, blue: 0.600))

            Text("SPECIAL CARE")
                .font(.custom("PlusJakartaSans-SemiBold", size: 10))
                .foregroundStyle(Color(red: 0.925, green: 0.286, blue: 0.600))
                .tracking(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.5))
        )
    }

    private var sensitiveDaysToggleRow: some View {
        HStack {
            Text(sensitiveDays.isEnabled ? "ENABLED" : "DISABLED")
                .font(.custom("PlusJakartaSans-Regular", size: 12))
                .tracking(1.2)
                .foregroundStyle(Color(red: 0.957, green: 0.447, blue: 0.714))

            Spacer()

            // Custom toggle
            sensitiveDaysCustomToggle
        }
    }

    private var sensitiveDaysCustomToggle: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                sensitiveDays.isEnabled.toggle()
            }
        }) {
            ZStack(alignment: sensitiveDays.isEnabled ? .trailing : .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                Color(red: 0.925, green: 0.286, blue: 0.600).opacity(0.5),
                                lineWidth: 1
                            )
                    )
                    .frame(width: 80, height: 40)

                Circle()
                    .fill(
                        sensitiveDays.isEnabled
                            ? Color(red: 0.925, green: 0.286, blue: 0.600)
                            : Color(red: 0.800, green: 0.780, blue: 0.770)
                    )
                    .frame(width: 32, height: 32)
                    .padding(4)
            }
        }
    }

    // MARK: - Sensitive Days Configuration Panel

    private let sensitivePink = Color(red: 0.925, green: 0.286, blue: 0.600)

    private var sensitiveDaysConfig: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Separator
            Rectangle()
                .fill(sensitivePink.opacity(0.15))
                .frame(height: 1)

            // Question
            Text("When do you usually feel more sensitive?")
                .font(.custom("NotoSerif-Regular", size: 16))
                .foregroundStyle(LumiTheme.onSurface)
                .fixedSize(horizontal: false, vertical: true)

            Text("Lumi will send extra gentle messages during these days.")
                .font(.custom("PlusJakartaSans-Regular", size: 12))
                .foregroundStyle(LumiTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            // Last sensitive period date picker
            VStack(alignment: .leading, spacing: 8) {
                Text("LAST SENSITIVE PERIOD")
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .tracking(1.2)
                    .foregroundStyle(sensitivePink.opacity(0.7))

                Button {
                    showDatePicker.toggle()
                } label: {
                    Text(formatDate(sensitiveDays.isConfigured ? sensitiveDays.lastStartDate : Date()))
                        .font(.custom("NotoSerif-Regular", size: 16))
                        .foregroundStyle(sensitivePink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                }

                if showDatePicker {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { sensitiveDays.isConfigured ? sensitiveDays.lastStartDate : Date() },
                            set: {
                                sensitiveDays.lastStartDate = $0
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showDatePicker = false
                                }
                            }
                        ),
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(sensitivePink)
                    .labelsHidden()
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: LumiTheme.radiusMedium, style: .continuous)
                            .fill(Color.white.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: LumiTheme.radiusMedium, style: .continuous)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }

            // Duration slider (3-10 days) — same style as cycle length
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("DURATION")
                        .font(.custom("PlusJakartaSans-Regular", size: 10))
                        .tracking(1.2)
                        .foregroundStyle(sensitivePink.opacity(0.7))

                    Spacer()

                    Text("\(sensitiveDays.duration) days")
                        .font(.custom("PlusJakartaSans-Regular", size: 13))
                        .foregroundStyle(LumiTheme.onSurfaceVariant)
                }

                Slider(
                    value: Binding(
                        get: { Double(sensitiveDays.duration) },
                        set: { sensitiveDays.duration = Int($0) }
                    ),
                    in: 3...10,
                    step: 1
                )
                .tint(sensitivePink)

                Text("How many days does your sensitive period last?")
                    .font(.custom("PlusJakartaSans-Regular", size: 11))
                    .foregroundStyle(LumiTheme.mutedText.opacity(0.7))
            }

            // Cycle length slider (21-40 days)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CYCLE LENGTH")
                        .font(.custom("PlusJakartaSans-Regular", size: 10))
                        .tracking(1.2)
                        .foregroundStyle(sensitivePink.opacity(0.7))

                    Spacer()

                    Text("\(sensitiveDays.cycleLength) days")
                        .font(.custom("PlusJakartaSans-Regular", size: 13))
                        .foregroundStyle(LumiTheme.onSurfaceVariant)
                }

                Slider(
                    value: Binding(
                        get: { Double(sensitiveDays.cycleLength) },
                        set: { sensitiveDays.cycleLength = Int($0) }
                    ),
                    in: 21...40,
                    step: 1
                )
                .tint(sensitivePink)

                Text("How often does this cycle repeat?")
                    .font(.custom("PlusJakartaSans-Regular", size: 11))
                    .foregroundStyle(LumiTheme.mutedText.opacity(0.7))
            }

            // Next period preview
            if sensitiveDays.isConfigured {
                nextPeriodPreview
            }
        }
    }

    private var nextPeriodPreview: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(sensitivePink.opacity(0.15))
                .frame(height: 1)

            HStack(spacing: 0) {
                if sensitiveDays.isSensitiveToday {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(sensitivePink)
                        .padding(.trailing, 6)

                    Text("Gentle mode is active now")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .foregroundStyle(sensitivePink)
                } else {
                    Text("Next: ")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .foregroundStyle(LumiTheme.mutedText)

                    Text(formatDateRange(sensitiveDays.nextPeriodStart, sensitiveDays.nextPeriodEnd))
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .fontWeight(.medium)
                        .foregroundStyle(sensitivePink.opacity(0.8))

                    if sensitiveDays.daysUntilNextPeriod > 0 {
                        Text(" (\(sensitiveDays.daysUntilNextPeriod)d)")
                            .font(.custom("PlusJakartaSans-Regular", size: 11))
                            .foregroundStyle(LumiTheme.mutedText.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM d, yyyy"
        return fmt.string(from: date)
    }

    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: start)) – \(fmt.string(from: end))"
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(spacing: 24) {
            Button(action: {}) {
                Text("DEACTIVATE MY ACCOUNT")
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(red: 0.729, green: 0.102, blue: 0.102))
            }

            Text("Lumi Version 2.4.0 \u{2014} Made with intention for mindful souls.")
                .font(.custom("PlusJakartaSans-Light", size: 10))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400).opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.bottom, 96)
    }
}

// MARK: - Support View

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var issueText = ""
    @State private var hasAttachedImage = false

    var body: some View {
        NavigationStack {
            ZStack {
                LumiTheme.background
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    Text("How can we\nhelp you?")
                        .font(.custom("NotoSerif-Regular", size: 28))
                        .foregroundStyle(LumiTheme.onSurface)
                        .lineSpacing(4)
                        .padding(.top, 24)

                    TextEditor(text: $issueText)
                        .font(.custom("PlusJakartaSans-Light", size: 16))
                        .foregroundStyle(LumiTheme.onSurface)
                        .frame(height: 150)
                        .padding(16)
                        .scrollContentBackground(.hidden)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .shadow(color: LumiTheme.cardShadow, radius: 10, x: 0, y: 4)

                    Button(action: { hasAttachedImage.toggle() }) {
                        HStack(spacing: 12) {
                            Image(systemName: hasAttachedImage ? "checkmark.circle.fill" : "photo")
                                .foregroundStyle(
                                    hasAttachedImage ? LumiTheme.secondary : LumiTheme.primary
                                )
                            Text(hasAttachedImage ? "Screenshot attached" : "Attach a screenshot")
                                .font(.custom("PlusJakartaSans-Regular", size: 14))
                                .foregroundStyle(LumiTheme.onSurface)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        Text("SEND")
                            .font(.custom("PlusJakartaSans-Regular", size: 13))
                            .fontWeight(.medium)
                            .tracking(2)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 9999, style: .continuous)
                                    .fill(LumiTheme.primary)
                            )
                    }
                }
                .padding(.horizontal, 28)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(LumiTheme.primary)
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
