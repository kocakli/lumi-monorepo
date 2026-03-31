import SwiftUI

struct WriteMessageView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var messageText: String = ""
    @State private var selectedMood: String = "Rastgele"
    
    private let characterLimit = 200
    let moods = ["Rastgele", "Eğlenceli", "Huzurlu", "Motive Edici", "Romantik"]
    
    var body: some View {
        ZStack {
            // Arka Plan (Yarı saydam, buzlu cam efekti için zemin)
            Color(red: 0.98, green: 0.98, blue: 0.96)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Header (Kapatma Butonu ve Başlık)
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    Spacer()
                    
                    // Mood Seçici
                    Menu {
                        ForEach(moods, id: \.self) { mood in
                            Button(mood) {
                                selectedMood = mood
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedMood)
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(16)
                        .foregroundColor(.black.opacity(0.8))
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Mesaj Giriş Alanı
                TextEditor(text: $messageText)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundColor(.black.opacity(0.8))
                    .frame(height: 200)
                    .scrollContentBackground(.hidden) // TextEditor'ün default arka planını kaldırır
                    .background(Color.clear)
                    .overlay(
                        VStack {
                            if messageText.isEmpty {
                                HStack {
                                    Text("Birini gülümsetecek bir şey yaz...")
                                        .font(.system(size: 24, weight: .regular, design: .serif))
                                        .foregroundColor(Color.black.opacity(0.3))
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                    )
                
                // Karakter Sayacı ve Gönder Butonu
                HStack {
                    Text("\(messageText.count)/\(characterLimit)")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(messageText.count > characterLimit ? .red : .black.opacity(0.4))
                    
                    Spacer()
                    
                    Button(action: {
                        // Gönderme işlemi burada tetiklenecek
                        print("Mesaj Gönderildi: \(messageText) - Mod: \(selectedMood)")
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Gönder")
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(messageText.isEmpty || messageText.count > characterLimit ? Color.black.opacity(0.1) : Color.black)
                            .foregroundColor(messageText.isEmpty || messageText.count > characterLimit ? .black.opacity(0.4) : .white)
                            .cornerRadius(20)
                    }
                    .disabled(messageText.isEmpty || messageText.count > characterLimit)
                }
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 30)
        }
    }
}

struct WriteMessageView_Previews: PreviewProvider {
    static var previews: some View {
        WriteMessageView()
    }
}
