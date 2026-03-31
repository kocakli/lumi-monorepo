import SwiftUI

struct ContentView: View {
    @State private var isShowingWriteMessage = false
    @State private var isShowingReceiveMessage = false
    @State private var isShowingVault = false
    @State private var isShowingSettings = false
    
    var body: some View {
        ZStack {
            // Arka Plan (Japon Minimalizmi)
            Color(red: 0.98, green: 0.98, blue: 0.96)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header (Ayarlar ve Kasa Butonu)
                HStack {
                    Button(action: {
                        isShowingSettings.toggle()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    Spacer()
                    Button(action: {
                        isShowingVault.toggle()
                    }) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                .fullScreenCover(isPresented: $isShowingVault) {
                    VaultView()
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                }
                
                Text("Lumi")
                    .font(.custom("PlayfairDisplay-Regular", size: 42, relativeTo: .largeTitle))
                    .foregroundColor(Color.black.opacity(0.8))
                    .kerning(4)
                
                Text("sadece iyi hisler.")
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(Color.gray)
                
                Spacer()
                
                // Ana Butonlar
                VStack(spacing: 20) {
                    Button(action: {
                        isShowingWriteMessage.toggle()
                    }) {
                        Text("Güzel Bir Şey Söyle")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .fullScreenCover(isPresented: $isShowingWriteMessage) {
                        WriteMessageView()
                    }
                    
                    Button(action: {
                        isShowingReceiveMessage.toggle()
                    }) {
                        Text("Bir Mesaj Al")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 40)
                    .fullScreenCover(isPresented: $isShowingReceiveMessage) {
                        ReceiveMessageView() // Mood selection can be integrated inside
                    }
                }
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}