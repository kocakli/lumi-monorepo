import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Bildirim Ayarları
    @State private var notificationsEnabled = true
    @State private var startTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var endTime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    
    // Döngü / Hassas Günler
    @State private var sensitiveDaysEnabled = false
    @State private var cycleDayInfo = "Şu an belirtilmedi"
    
    // Destek / İletişim
    @State private var isShowingSupport = false
    
    // Kısa Kod (Allowlist)
    @State private var isShowingConnectionCode = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.98, green: 0.98, blue: 0.96)
                    .ignoresSafeArea()
                
                List {
                    // 1. Profil ve Bağlantı (Kısa Kod)
                    Section {
                        Button(action: {
                            isShowingConnectionCode.toggle()
                        }) {
                            HStack {
                                Text("Özel Bağlantı Kodum")
                                    .foregroundColor(.black.opacity(0.8))
                                Spacer()
                                Text("LUMI-84X2")
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    } header: {
                        Text("Bana Özel")
                    }
                    .listRowBackground(Color.white)
                    
                    // 2. Bildirim Tercihleri
                    Section {
                        Toggle("Günlük İyi Hisler", isOn: $notificationsEnabled)
                            .tint(.black)
                        
                        if notificationsEnabled {
                            DatePicker("Başlangıç", selection: $startTime, displayedComponents: .hourAndMinute)
                            DatePicker("Bitiş", selection: $endTime, displayedComponents: .hourAndMinute)
                        }
                    } header: {
                        Text("Zamanlama")
                    }
                    .listRowBackground(Color.white)
                    
                    // 3. Hassas Günler (Döngü Modu)
                    Section {
                        Toggle("Hassas Dönem Modu", isOn: $sensitiveDaysEnabled)
                            .tint(.pink.opacity(0.5))
                        
                        if sensitiveDaysEnabled {
                            HStack {
                                Text("Döngü Takvimi")
                                Spacer()
                                Text(cycleDayInfo)
                                    .foregroundColor(.gray)
                            }
                            Text("Bu mod açıkken, sana daha sık ve daha sarıp sarmalayan, huzur verici mesajlar ulaştıracağız.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                    } header: {
                        Text("Bana İyi Bak")
                    } footer: {
                        Text("Gizliliğinize saygı duyuyoruz. Bu veri sadece sana uygun anları seçmek için cihazında tutulur.")
                    }
                    .listRowBackground(Color.white)
                    
                    // 4. Destek ve İletişim
                    Section {
                        Button(action: {
                            isShowingSupport.toggle()
                        }) {
                            Text("Bize Ulaş / Hata Bildir")
                                .foregroundColor(.black.opacity(0.8))
                        }
                        
                        Button(action: {
                            // Rate app
                        }) {
                            Text("Uygulamayı Değerlendir")
                                .foregroundColor(.black.opacity(0.8))
                        }
                    } header: {
                        Text("Destek")
                    }
                    .listRowBackground(Color.white)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bitti") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
            .sheet(isPresented: $isShowingSupport) {
                SupportView()
            }
            .sheet(isPresented: $isShowingConnectionCode) {
                ConnectionCodeView()
            }
        }
    }
}

// Destek Ekranı (Ekran Görüntüsü Yüklemeli)
struct SupportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var issueText = ""
    @State private var hasAttachedImage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.98, green: 0.98, blue: 0.96).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Nasıl yardımcı olabiliriz?")
                        .font(.custom("PlayfairDisplay-Regular", size: 24))
                        .padding(.top, 20)
                    
                    TextEditor(text: $issueText)
                        .frame(height: 150)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    
                    Button(action: {
                        hasAttachedImage.toggle()
                    }) {
                        HStack {
                            Image(systemName: hasAttachedImage ? "checkmark.circle.fill" : "photo")
                                .foregroundColor(hasAttachedImage ? .green : .black.opacity(0.6))
                            Text(hasAttachedImage ? "Ekran görüntüsü eklendi" : "Ekran görüntüsü ekle")
                                .foregroundColor(.black.opacity(0.8))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Gönder
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Gönder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.black)
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
