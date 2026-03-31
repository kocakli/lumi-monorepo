import SwiftUI

struct ConnectionCodeView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var myCode = "LUMI-84X2"
    @State private var friendCode = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.98, green: 0.98, blue: 0.96).ignoresSafeArea()
                
                VStack(spacing: 40) {
                    VStack(spacing: 15) {
                        Text("Senin Kodun")
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .foregroundColor(.gray)
                        
                        Text(myCode)
                            .font(.system(size: 32, weight: .medium, design: .monospaced))
                            .kerning(5)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                            
                        Text("Bu kodu güvendiğin biriyle paylaş. O da senin kodunu girdiğinde karşılıklı ve anonim bağınız kurulur.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    
                    Divider().padding(.horizontal, 40)
                    
                    VStack(spacing: 15) {
                        Text("Birine Bağlan")
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .foregroundColor(.gray)
                        
                        TextField("Arkadaşının Kodu", text: $friendCode)
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            // Bağlantı İsteği
                        }) {
                            Text("Bağlantı Kur")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(friendCode.isEmpty ? Color.black.opacity(0.1) : Color.black)
                                .foregroundColor(friendCode.isEmpty ? .black.opacity(0.4) : .white)
                                .cornerRadius(12)
                        }
                        .disabled(friendCode.isEmpty)
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Özel Bağ")
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
