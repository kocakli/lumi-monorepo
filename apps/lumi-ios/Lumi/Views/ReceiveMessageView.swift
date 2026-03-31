import SwiftUI

struct ReceiveMessageView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Geçici Mock Data
    @State private var receivedMessage: String = "Bugün belki her şey plana uygun gitmedi ama nefes alıyorsun ve yeniden başlamak için her zaman bir şansın var. Gülümsemeyi unutma."
    @State private var messageMood: String = "Motive Edici"
    @State private var isVisible: Bool = false
    @State private var isSaved: Bool = false
    @State private var isShowingShare = false
    
    var body: some View {
        ZStack {
            // Derin ve ferah arka plan
            Color(red: 0.98, green: 0.98, blue: 0.96)
                .ignoresSafeArea()
            
            VStack {
                // Kapatma Butonu
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Mesajın Kendisi ve Mood
                if isVisible {
                    VStack(spacing: 20) {
                        Text(messageMood)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(16)
                            .foregroundColor(.gray)
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        
                        Text(receivedMessage)
                            .font(.custom("PlayfairDisplay-Regular", size: 28, relativeTo: .title))
                            .lineSpacing(10)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.black.opacity(0.85))
                            .padding(.horizontal, 40)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                
                // Etkileşim Butonları (Kaydet/Paylaş/Şikayet)
                if isVisible {
                    HStack(spacing: 40) {
                        // Kasa'ya Kaydet (Vault)
                        Button(action: {
                            withAnimation(.spring()) {
                                isSaved.toggle()
                            }
                        }) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(isSaved ? .black : .black.opacity(0.5))
                        }
                        
                        // Paylaş Butonu
                        Button(action: {
                            isShowingShare.toggle()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(.black.opacity(0.5))
                        }
                        
                        // Şikayet Et (Gizli/Zarif)
                        Button(action: {
                            // Şikayet mekanizması
                        }) {
                            Image(systemName: "flag")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.black.opacity(0.3))
                        }
                    }
                    .padding(.bottom, 50)
                    .transition(.opacity)
                }
            }
            .sheet(isPresented: $isShowingShare) {
                ShareMessageView(message: receivedMessage, mood: messageMood)
            }
        }
        .onAppear {
            // Ekran açıldıktan kısa süre sonra mesajın zarifçe belirmesi (Fade-in)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 1.5)) {
                    isVisible = true
                }
            }
        }
    }
}

struct ReceiveMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiveMessageView()
    }
}
