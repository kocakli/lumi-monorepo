# Lumi - Proje Planı ve Monorepo Mimarisi

## 1. Monorepo Yapısı (Klasörleme)

Projenin düzenli, ölçeklenebilir ve yönetilebilir olması için aşağıdaki monorepo yapısını kuracağız:

```text
lumi-monorepo/
├── apps/
│   ├── lumi-ios/           # Swift & SwiftUI (Ana uygulama ve iOS Widget'ları)
│   └── lumi-android/       # Skip.tools çıktısı veya native Android build'i
├── packages/
│   ├── shared-ui/          # Ortak tasarım token'ları, renkler, font yapılandırmaları
│   └── core-logic/         # (Opsiyonel) İş kuralları, API client'ları, modeller
├── backend/
│   ├── firebase/           # Firebase konfigürasyonları, Firestore kuralları (firestore.rules)
│   └── functions/          # Cloud Functions (TypeScript/Node.js) - AI filtresi ve moderasyon
├── docs/                   # PRD, mimari dokümanlar, API tasarımları
└── scripts/                # CI/CD, deployment ve derleme scriptleri
```

## 2. Geliştirme Fazları ve Görevler (Task List)

### Faz 1: Altyapı ve Kurulum (Foundation)
- [ ] **Task 1.1:** Monorepo klasör yapısının oluşturulması ve Git reposunun başlatılması.
- [ ] **Task 1.2:** Firebase projesinin açılması (iOS ve Android uygulamalarının kaydedilmesi).
- [ ] **Task 1.3:** Firebase Anonymous Authentication'ın aktifleştirilmesi.
- [ ] **Task 1.4:** Firestore veritabanının kurulması ve temel güvenlik kurallarının (Security Rules) yazılması.
- [ ] **Task 1.5:** iOS projesinin (SwiftUI) oluşturulması ve Firebase SDK'sının projeye entegre edilmesi.
- [ ] **Task 1.6:** Skip.tools kurulumu ve Android build'inin test edilmesi.

### Faz 2: Core Backend & Yapay Zeka (Logic)
- [ ] **Task 2.1:** Firestore koleksiyon yapılarının tasarlanması (`messages`, `users`, `vaults`).
- [ ] **Task 2.2:** Firebase Cloud Functions ortamının kurulması (TypeScript).
- [ ] **Task 2.3:** OpenAI API entegrasyonu (GPT-4o-mini). "Pozitiflik Filtresi" promptunun yazılması.
- [ ] **Task 2.4:** Mesaj gönderme fonksiyonunun (Trigger) yazılması: Mesaj havuza eklenmeden önce AI filtresinden geçecek.
- [ ] **Task 2.5:** Gölge ban (Shadowban) mantığının yazılması: Cihaz UUID'si banlıysa mesajı sessizce yut.

### Faz 3: Frontend - Kullanıcı Arayüzü (SwiftUI)
- [ ] **Task 3.1:** Tema motorunun kurulması (Japon minimalizmi: Renk paleti, tipografi, blur efektleri).
- [ ] **Task 3.2:** Splash Screen ve zahmetsiz Onboarding ekranının kodlanması (Cihaz arka planda anonim giriş yapar).
- [ ] **Task 3.3:** Ana Ekran (Home) tasarımı: "Güzel Bir Şey Söyle" ve "Bir Mesaj Al" butonları.
- [ ] **Task 3.4:** Mesaj Gönderme Ekranı: Minimalist metin giriş alanı ve gönderme animasyonu.
- [ ] **Task 3.5:** Mesaj Alma Ekranı: Havuzdan rastgele mesaj çekme ve ekranda zarifçe gösterme.
- [ ] **Task 3.6:** Lumi Kutusu (Vault) ekranı: Beğenilen mesajların listelendiği arşiv sayfası.

### Faz 4: Bildirimler, Etkileşim ve Widget
- [ ] **Task 4.1:** Beğenme (Kalp) mekanizmasının kodlanması ve mesajın sahibine push bildirim (veya in-app toast) gönderilmesi.
- [ ] **Task 4.2:** iOS WidgetKit entegrasyonu: Ana ekranda rastgele bir pozitif mesaj gösteren minimal widget'ın tasarlanması.
- [ ] **Task 4.3:** Haptic feedback (titreşim) ve ses efektlerinin (zarif, soft sesler) eklenmesi.
- [ ] **Task 4.4:** Skip.tools üzerinden Android widget/bildirim testlerinin yapılması.

### Faz 5: Test ve Yayına Hazırlık
- [ ] **Task 5.1:** AI filtresinin edge-case (zorlayıcı) küfür ve negatif mesajlarla test edilmesi.
- [ ] **Task 5.2:** TestFlight (iOS) ve Google Play Console kapalı beta dağıtımlarının yapılması.
- [ ] **Task 5.3:** App Store ve Google Play görsellerinin (minimalist tarzda) hazırlanması.
