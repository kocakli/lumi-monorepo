import SwiftUI

struct WriteMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = WriteMessageViewModel()
    @State private var messageText: String = ""
    @State private var selectedMood: String = "Random"
    @FocusState private var isTextFocused: Bool

    private let characterLimit = 400
    let moods = ["Random", "Playful", "Peaceful", "Motivating", "Romantic"]

    private var charactersRemaining: Int {
        characterLimit - messageText.count
    }

    private var canSend: Bool {
        !messageText.isEmpty && messageText.count <= characterLimit
    }

    var body: some View {
        VStack(spacing: 0) {
            modalHeader
            modalBody
            modalFooter
        }
        .background(LumiTheme.background)
        .onTapGesture { isTextFocused = false }
    }

    // MARK: - Modal Header

    private var modalHeader: some View {
        HStack {
            Button(action: { withAnimation(.spring(response: 0.35)) { router.showWrite = false } }) {
                Image("icon-close")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LumiTheme.primary)
            }
            .frame(width: 48, height: 48)

            Spacer()

            moodPill
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 16)
    }

    private var moodPill: some View {
        Menu {
            ForEach(moods, id: \.self) { mood in
                Button(mood) { selectedMood = mood }
            }
        } label: {
            HStack(spacing: 12) {
                Text(selectedMood == "Random" ? "SELECTING MOOD" : selectedMood.uppercased())
                    .font(.custom("Plus Jakarta Sans", size: 10))
                    .fontWeight(.medium)
                    .foregroundStyle(LumiTheme.primary)
                    .kerning(1)

                Image("icon-chevron-down")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 7, height: 4)
                    .foregroundStyle(LumiTheme.primary)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
        }
    }

    // MARK: - Modal Body

    private var modalBody: some View {
        ZStack(alignment: .top) {
            if messageText.isEmpty {
                placeholderText
            }

            TextEditor(text: $messageText)
                .font(.custom("Noto Serif Display", size: 26))
                .foregroundStyle(LumiTheme.onSurface)
                .multilineTextAlignment(.center)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isTextFocused)
                .padding(.horizontal, 12)
                .padding(.top, messageText.isEmpty ? 50 : 16)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    private var placeholderText: some View {
        VStack(spacing: 4) {
            Text("Pour your silence")
                .font(.custom("Noto Serif Display", size: 30))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))
            Text("into words...")
                .font(.custom("Noto Serif Display", size: 30))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .allowsHitTesting(false)
    }

    // MARK: - Modal Footer

    private var modalFooter: some View {
        VStack(spacing: 28) {
            characterCounter
            sendButton
        }
        .padding(.horizontal, 32)
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    private var characterCounter: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(LumiTheme.primary.opacity(0.1), lineWidth: 1)
                    .frame(width: 32, height: 32)
                Circle()
                    .fill(LumiTheme.primary)
                    .frame(width: 4, height: 4)
            }

            Text("\(charactersRemaining) CHARACTERS UNTIL GLOW")
                .font(.custom("Plus Jakarta Sans", size: 12))
                .foregroundStyle(
                    messageText.count > characterLimit
                        ? Color.red.opacity(0.6)
                        : LumiTheme.primary.opacity(0.4)
                )
                .kerning(2.4)
        }
    }

    private var sendButton: some View {
        Button(action: {
            Task {
                await viewModel.sendMessage(text: messageText, mood: selectedMood)
                if viewModel.didSend {
                    router.showMessageSent = true
                    withAnimation(.spring(response: 0.35)) { router.showWrite = false }
                }
            }
        }) {
            Text("SEND INTO THE LIGHT")
                .font(.custom("Plus Jakarta Sans", size: 14))
                .fontWeight(.semibold)
                .foregroundStyle(
                    Color(red: 0.459, green: 0.427, blue: 0.451)
                        .opacity(canSend ? 1 : 0.5)
                )
                .kerning(4.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(sendButtonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .disabled(!canSend)
    }

    private var sendButtonBackground: some View {
        ZStack {
            LumiTheme.primaryContainer
            LinearGradient(
                colors: [
                    Color(red: 0.918, green: 0.878, blue: 0.902),
                    LumiTheme.primaryContainer
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .opacity(canSend ? 0.6 : 0.4)
        }
    }
}

struct WriteMessageView_Previews: PreviewProvider {
    static var previews: some View {
        WriteMessageView()
    }
}
