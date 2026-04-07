import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) private var dismiss

    private let accentPink = Color(red: 0.925, green: 0.286, blue: 0.600)

    var body: some View {
        ZStack {
            LumiTheme.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    heroSection
                    frequencySection
                    timeSection
                    moodSection
                    previewSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image("icon-close")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(LumiTheme.buttonText)
                }
            }
        }
        .onChange(of: notificationService.frequency) { _ in syncPrefs() }
        .onChange(of: notificationService.periodMorning) { _ in syncPrefs() }
        .onChange(of: notificationService.periodAfternoon) { _ in syncPrefs() }
        .onChange(of: notificationService.periodEvening) { _ in syncPrefs() }
        .onChange(of: notificationService.moodPlayful) { _ in syncPrefs() }
        .onChange(of: notificationService.moodPeaceful) { _ in syncPrefs() }
        .onChange(of: notificationService.moodMotivating) { _ in syncPrefs() }
        .onChange(of: notificationService.moodRomantic) { _ in syncPrefs() }
    }

    private func syncPrefs() {
        Task { await notificationService.syncPreferences() }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            Text("notif_settings.title")
                .font(.custom("NotoSerif-Regular", size: 36))
                .foregroundStyle(LumiTheme.primary)

            Text("notif_settings.subtitle")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundStyle(LumiTheme.mutedText)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Frequency

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("notif_settings.section.daily")
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .tracking(1.2)
                    .foregroundStyle(accentPink.opacity(0.7))

                Spacer()

                Text(notificationService.frequency == 0 ? String(localized: "notif_settings.off") : "\(notificationService.frequency)\(String(localized: "notif_settings.per_day"))")
                    .font(.custom("PlusJakartaSans-Regular", size: 13))
                    .foregroundStyle(LumiTheme.onSurfaceVariant)
            }

            Slider(
                value: Binding(
                    get: { Double(notificationService.frequency) },
                    set: { notificationService.frequency = Int($0) }
                ),
                in: 0...5,
                step: 1
            )
            .tint(accentPink)

            Text("notif_settings.frequency_description")
                .font(.custom("PlusJakartaSans-Regular", size: 11))
                .foregroundStyle(LumiTheme.mutedText.opacity(0.7))
        }
        .padding(24)
        .zenGlass(cornerRadius: 28, opacity: 0.3)
    }

    // MARK: - Time

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("notif_settings.section.time")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .tracking(1.2)
                .foregroundStyle(accentPink.opacity(0.7))

            HStack(spacing: 10) {
                periodPill("notif_settings.period.morning", isOn: $notificationService.periodMorning, time: "08:00")
                periodPill("notif_settings.period.afternoon", isOn: $notificationService.periodAfternoon, time: "13:00")
                periodPill("notif_settings.period.evening", isOn: $notificationService.periodEvening, time: "20:00")
            }
        }
        .padding(24)
        .zenGlass(cornerRadius: 28, opacity: 0.3)
    }

    private func periodPill(_ label: LocalizedStringKey, isOn: Binding<Bool>, time: String) -> some View {
        return Button {
            isOn.wrappedValue.toggle()
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                    .fontWeight(isOn.wrappedValue ? .semibold : .regular)
                Text(time)
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .opacity(0.6)
            }
            .foregroundStyle(isOn.wrappedValue ? .white : LumiTheme.onSurfaceVariant)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isOn.wrappedValue ? accentPink : Color.white.opacity(0.4))
            )
        }
    }

    // MARK: - Moods

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("notif_settings.section.content")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .tracking(1.2)
                .foregroundStyle(accentPink.opacity(0.7))

            VStack(spacing: 0) {
                moodToggle("mood.peaceful", description: "notif_settings.mood.peaceful.desc", isOn: $notificationService.moodPeaceful)
                moodToggle("mood.motivating", description: "notif_settings.mood.motivating.desc", isOn: $notificationService.moodMotivating)
                moodToggle("mood.playful", description: "notif_settings.mood.playful.desc", isOn: $notificationService.moodPlayful)
                moodToggle("mood.romantic", description: "notif_settings.mood.romantic.desc", isOn: $notificationService.moodRomantic)
            }
        }
        .padding(24)
        .zenGlass(cornerRadius: 28, opacity: 0.3)
    }

    private func moodToggle(_ title: LocalizedStringKey, description: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("PlusJakartaSans-Regular", size: 14))
                    .fontWeight(.medium)
                    .foregroundStyle(LumiTheme.onSurface)
                Text(description)
                    .font(.custom("PlusJakartaSans-Regular", size: 11))
                    .foregroundStyle(LumiTheme.mutedText)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(accentPink)
                .labelsHidden()
        }
        .padding(.vertical, 12)
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(spacing: 8) {
            if notificationService.frequency == 0 {
                Text("notif_settings.off_status")
                    .font(.custom("PlusJakartaSans-Regular", size: 13))
                    .foregroundStyle(LumiTheme.mutedText)
            } else {
                let moodList = notificationService.enabledMoods.joined(separator: ", ")
                Text("You'll receive ~\(notificationService.frequency) gentle message\(notificationService.frequency == 1 ? "" : "s") around \(notificationService.periodLabel), focused on \(moodList) moods.")
                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                    .foregroundStyle(LumiTheme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}
