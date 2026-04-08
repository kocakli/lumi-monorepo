import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService

    @EnvironmentObject var notificationService: NotificationService
    @State private var stealthMode = false
    @EnvironmentObject var sensitiveDays: SensitiveDaysService
    @State private var isShowingSupport = false
    @State private var showDatePicker = false
    @State private var dragOffset: CGFloat = 0
    @StateObject private var pairingVM = PairingViewModel()

    @State private var showDeactivateConfirm = false
    @State private var isDeactivating = false
    @State private var deactivateError: String?

    /// Version string built from the app bundle. Falls back to "—" if Info.plist
    /// is missing the keys (should never happen in a real build).
    private var appVersionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "Lumi Version \(short) (\(build)) \u{2014} Made with intention for mindful souls."
    }

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
                            yourPairsCard
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
            Text("settings.title")
                .font(.custom("NotoSerif-Regular", size: 48))
                .foregroundStyle(Color(red: 0.388, green: 0.361, blue: 0.380))

            Text("settings.subtitle")
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
            Text("settings.private_connection")
                .font(.custom("NotoSerif-Regular", size: 24))
                .foregroundStyle(Color(red: 0.388, green: 0.361, blue: 0.380))

            Text("settings.private_connection.description")
                .font(.custom("PlusJakartaSans-Light", size: 14))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var privateConnectionCodeBox: some View {
        VStack(spacing: 12) {
            Text("settings.my_code")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
                .tracking(1)
                .textCase(.uppercase)

            Text(pairingVM.myCode.isEmpty ? String(localized: "common.loading") : pairingVM.myCode)
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
            UIPasteboard.general.string = pairingVM.myCode
        }) {
            Text("settings.copy_code")
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
                Text("settings.pair_sanctuary")
                    .font(.custom("NotoSerif-Regular", size: 24))
                    .foregroundStyle(Color(red: 0.388, green: 0.361, blue: 0.380))

                Text("settings.pair_sanctuary.description")
                    .font(.custom("PlusJakartaSans-Light", size: 14))
                    .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pairDeviceButton: some View {
        NavigationLink(destination: ConnectionCodeView()) {
            Text("settings.pair_device")
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

    // MARK: - Your Pairs Card

    private var yourPairsCard: some View {
        Button(action: { router.navigate(to: .pairs) }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LumiTheme.sparklePink.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(LumiTheme.sparklePink)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("settings.your_pairs")
                        .font(.custom("NotoSerif-Regular", size: 20))
                        .foregroundStyle(LumiTheme.primary)

                    Text(pairingVM.pairs.isEmpty
                         ? String(localized: "settings.no_pairs")
                         : "\(pairingVM.pairs.count) soul\(pairingVM.pairs.count == 1 ? "" : "s") connected")
                        .font(.custom("PlusJakartaSans-Regular", size: 14))
                        .foregroundStyle(LumiTheme.onSurfaceVariant)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LumiTheme.onSurfaceVariant.opacity(0.5))
            }
            .padding(24)
            .zenGlass(cornerRadius: 28, opacity: 0.3)
        }
        .buttonStyle(.plain)
        .task {
            await pairingVM.loadMyCode()
            await pairingVM.loadPairs()
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("settings.preferences")
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
                    Text("settings.pref.notifications")
                        .font(.custom("PlusJakartaSans-Regular", size: 14))
                        .fontWeight(.medium)
                        .foregroundStyle(LumiTheme.onSurface)

                    Text("settings.pref.notifications.desc")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400).opacity(0.7))
                }

                Spacer()

                Text(notificationService.frequency == 0 ? String(localized: "notif_settings.off") : "\(notificationService.frequency)\(String(localized: "notif_settings.per_day"))")
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
                Text("settings.pref.stealth")
                    .font(.custom("PlusJakartaSans-Regular", size: 14))
                    .fontWeight(.medium)
                    .foregroundStyle(LumiTheme.onSurface)

                Text("settings.pref.stealth.desc")
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
            Text("sensitive.title")
                .font(.custom("NotoSerif-Regular", size: 30))
                .foregroundStyle(LumiTheme.onSurface)
                .padding(.top, 44)

            // Description
            Text("sensitive.description")
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

            Text("sensitive.badge")
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
            Text(sensitiveDays.isEnabled ? LocalizedStringKey("sensitive.enabled") : LocalizedStringKey("sensitive.disabled"))
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
            Text("sensitive.question")
                .font(.custom("NotoSerif-Regular", size: 16))
                .foregroundStyle(LumiTheme.onSurface)
                .fixedSize(horizontal: false, vertical: true)

            Text("sensitive.helper")
                .font(.custom("PlusJakartaSans-Regular", size: 12))
                .foregroundStyle(LumiTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            // Last sensitive period date picker
            VStack(alignment: .leading, spacing: 8) {
                Text("sensitive.last_period")
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
                    Text("sensitive.duration")
                        .font(.custom("PlusJakartaSans-Regular", size: 10))
                        .tracking(1.2)
                        .foregroundStyle(sensitivePink.opacity(0.7))

                    Spacer()

                    Text("\(sensitiveDays.duration) \(String(localized: "sensitive.days_unit"))")
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

                Text("sensitive.duration_desc")
                    .font(.custom("PlusJakartaSans-Regular", size: 11))
                    .foregroundStyle(LumiTheme.mutedText.opacity(0.7))
            }

            // Cycle length slider (21-40 days)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("sensitive.cycle_length")
                        .font(.custom("PlusJakartaSans-Regular", size: 10))
                        .tracking(1.2)
                        .foregroundStyle(sensitivePink.opacity(0.7))

                    Spacer()

                    Text("\(sensitiveDays.cycleLength) \(String(localized: "sensitive.days_unit"))")
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

                Text("sensitive.cycle_desc")
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

                    Text("sensitive.active_now")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .foregroundStyle(sensitivePink)
                } else {
                    Text("\(String(localized: "sensitive.next_label")) ")
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
            Button(action: { showDeactivateConfirm = true }) {
                HStack(spacing: 8) {
                    if isDeactivating {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(Color(red: 0.729, green: 0.102, blue: 0.102))
                    }
                    Text("settings.deactivate")
                        .font(.custom("PlusJakartaSans-Regular", size: 10))
                        .tracking(3)
                        .textCase(.uppercase)
                        .foregroundStyle(Color(red: 0.729, green: 0.102, blue: 0.102))
                }
            }
            .disabled(isDeactivating)

            Text(appVersionString)
                .font(.custom("PlusJakartaSans-Light", size: 10))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400).opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.bottom, 96)
        .confirmationDialog(
            Text(verbatim: "Deactivate your account?"),
            isPresented: $showDeactivateConfirm,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                Task { await performDeactivation() }
            } label: {
                Text(verbatim: "Deactivate")
            }
            Button("common.cancel", role: .cancel) { }
        } message: {
            Text(verbatim: "This will permanently erase your vault, pairs, notifications and personal data. Messages you sent to the community stay but are anonymized. This cannot be undone.")
        }
        .alert(
            Text(verbatim: "Couldn’t deactivate"),
            isPresented: Binding(
                get: { deactivateError != nil },
                set: { if !$0 { deactivateError = nil } }
            )
        ) {
            Button(role: .cancel) { deactivateError = nil } label: {
                Text(verbatim: "OK")
            }
        } message: {
            Text(deactivateError ?? "")
        }
    }

    @MainActor
    private func performDeactivation() async {
        isDeactivating = true
        defer { isDeactivating = false }

        do {
            try await CloudFunctionService.shared.deleteAccount()
        } catch {
            deactivateError = error.localizedDescription
            return
        }

        // Clear any local per-user state that would otherwise carry over to
        // the new anonymous user spun up below.
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasReceivedFirstMessage")
        defaults.removeObject(forKey: "hasSeenSwipeOnboarding")
        defaults.removeObject(forKey: "pair_msgs_seen_v1")

        // Backend has deleted the auth user. Spin up a fresh anonymous
        // session and land the user back on home.
        await authService.resetToFreshAnonymousUser()
        router.goHome()
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
                    Text("support.title")
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
                            Text(hasAttachedImage ? LocalizedStringKey("support.attached") : LocalizedStringKey("support.attach"))
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
                        Text("support.send")
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
