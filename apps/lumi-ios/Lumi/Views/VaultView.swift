import SwiftUI

struct VaultView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Mock Data: Kasaya kaydedilmiş mesajlar
    @State private var savedMessages = [
        "Bugün belki her şey plana uygun gitmedi ama nefes alıyorsun ve yeniden başlamak için her zaman bir şansın var. Gülümsemeyi unutma.",
        "Senin o içindeki ışık, bugün birilerine umut oldu. Kendine iyi bak.",
        "Sadece dur ve bir derin nefes al. Her şeyin üstesinden gelebilirsin."
    ]
    
    var body: some View {
        ZStack {
            // Arka Plan
            Color(red: 0.98, green: 0.98, blue: 0.96)
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                // Header: Geri Dönüş ve Başlık
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("Lumi Kutusu")
                        .font(.custom("PlayfairDisplay-Regular", size: 20))
                        .foregroundColor(.black.opacity(0.8))
                        .kerning(1.5)
                    
                    Spacer()
                    
                    // Başlığı ortalamak için gizli placeholder
                    Image(systemName: "chevron.left")
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // Kaydedilen Mesajlar Listesi
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        ForEach(savedMessages, id: \.self) { message in
                            VaultMessageCard(message: message)
                        }
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

// Minimalist Kasa Kartı Komponenti
struct VaultMessageCard: View {
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(message)
                .font(.system(size: 18, weight: .light, design: .serif))
                .lineSpacing(8)
                .foregroundColor(Color.black.opacity(0.85))
            
            HStack {
                Text("Bilinmeyen birinden")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.black.opacity(0.4))
                
                Spacer()
                
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.black.opacity(0.3))
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 30)
    }
}

struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        VaultView()
    }
}
