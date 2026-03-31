import SwiftUI

struct ShareMessageView: View {
    @Environment(\.presentationMode) var presentationMode
    let message: String
    let mood: String
    
    // Ekran görüntüsü alınacak alan
    var captureArea: some View {
        ZStack {
            // Arka Plan
            Color(red: 0.98, green: 0.98, blue: 0.96)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Mood Rozeti
                Text(mood)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                
                // Mesaj
                Text(message)
                    .font(.custom("PlayfairDisplay-Regular", size: 32))
                    .lineSpacing(10)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.black.opacity(0.85))
                    .padding(.horizontal, 40)
                
                // Uygulama İmzası (Logo/İsim)
                VStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .light))
                    Text("Lumi")
                        .font(.system(size: 12, weight: .light, design: .serif))
                        .kerning(3)
                }
                .foregroundColor(.black.opacity(0.4))
                .padding(.top, 40)
            }
            .padding(.vertical, 80)
        }
        .frame(width: 350, height: 450)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.05).ignoresSafeArea() // Arka plan (Karartılmış)
                
                VStack(spacing: 40) {
                    captureArea
                    
                    Button(action: {
                        // Burada SwiftUI 'ImageRenderer' veya UIGraphicsImageRenderer tetiklenerek 'captureArea' fotoğrafa çevrilip Paylaşım (UIActivityViewController) menüsüne atılacak.
                        print("Fotoğraf Oluşturuldu ve Paylaşıldı")
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Instagram / Sosyal Medya'da Paylaş")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                    }
                }
            }
            .navigationTitle("Paylaş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.black)
                }
            }
        }
    }
}
