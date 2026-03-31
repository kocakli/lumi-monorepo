# Lumi - Ürün Gereksinim Dokümanı (PRD) & Tech Stack

## 1. Ürün Vizyonu ve Konsept
**Uygulama Adı:** Lumi
**Konsept:** İnsanların rastgele, tamamen anonim ve sadece pozitif mesajlar gönderip alabildiği, dijital bir "şişe içinde mektup" deneyimi.
**Hedef Kitle:** Başta kadınlar olmak üzere, gün içinde küçük mutluluklara, zarif sürprizlere ve dijital bir "güvenli alana" ihtiyaç duyan herkes.
**Tasarım Dili:** Aydınlık, ferah, Japon minimalizmi (Zen tarzı). Geniş boşluklar (whitespace), kırık beyaz/krem arka planlar, ince ve zarif serif fontlar. Karmaşadan uzak, nefes alan bir arayüz.

## 2. Temel Özellikler (Core Features)

### 2.1. Zahmetsiz Onboarding (Kayıt Yok)
- E-posta, şifre veya telefon numarası istenmez.
- Uygulama indirildiği an, arka planda cihaza özel bir anonim ID (UUID) atanır (Keychain/Keystore üzerinden).
- Anında kullanıma hazır: "Kim olduğunu bilmeden birini gülümset."

### 2.2. Rastgele Mesajlaşma (Gönder/Al)
- İki ana eylem: "Güzel Bir Şey Söyle" ve "Bir Mesaj Al"
- Gönderilen mesajlar havuza düşer ve o an mesaj almak isteyen rastgele bir kullanıcıya iletilir.

### 2.3. Yapay Zeka Destekli Moderasyon & Güvenlik
- **Pozitiflik Filtresi:** Gönderilmeden önce mesajlar AI tarafından saniyeler içinde taranır. Sadece pozitif, nazik ve iyi hissettiren mesajlar onaylanır.
- **Trol Koruması (Gölge Ban / Shadowbanning):** Spam yapan veya filtreyi aşmaya çalışan cihazlar sessizce banlanır. Mesajı "Gönderildi" görünür ama havuza düşmez.
- **Strike Sistemi:** 3 kural ihlalinde cihaz kalıcı olarak kara listeye alınır.
- **Hız Sınırı (Rate Limit):** Spam'i önlemek ve mesajların değerini korumak için arka arkaya gönderimlere süre sınırı konur.

### 2.4. Geri Bildirim Döngüsü (Dopamin Etkisi)
- Mesaj karşı tarafa ulaştığında gönderene bildirim: *"Mesajın birine ulaştı 🕊️"*
- Karşı taraf mesajı beğenip kaydettiğinde: *"Birinin gününü güzelleştirdin! Mesajını sakladılar 🤍"*

### 2.5. Lumi Kutusu (Kasa / Vault)
- Kullanıcıların aldıkları ve en çok sevdikleri mesajları saklayabilecekleri kişisel bir arşiv.
- Kötü hissedilen anlarda açıp okunacak bir "iyi hissetme" köşesi.

### 2.7. Gelişmiş Bildirim ve Döngü Ayarları
- Kullanıcılar bildirim almak istedikleri özel saatleri belirleyebilir.
- **Hassas Günler (Döngü) Modu:** Özellikle kadın kullanıcıların adet döngüleri gibi daha hassas oldukları dönemleri işaretleyebildiği ve bu günlerde ekstra moral/destek bildirimleri alabilecekleri özel bir mod.

### 2.8. Mood (Mod) ve Kategori Sistemi
- Gönderilen ve alınan mesajlar ruh hallerine (Eğlenceli, Romantik, Motive Edici, Huzurlu vb.) göre kategorize edilir.
- Kullanıcı "Şu an x modunda mesajlar almak istiyorum" diyerek filtreleme yapabilir.

### 2.9. Özel Bağ (Allowlist / Kısa Kod)
- Her kullanıcının rastgele üretilmiş kısa bir kodu (örn: `LUMI-84X2`) olur.
- Sadece karşılıklı kod eşleşmesi (Mutual Match) sağlandığında iki kişi birbirine direkt (yine anonim ama spesifik) mesaj atabilir. Tek taraflı kod bilmek işe yaramaz.

### 2.10. Paylaşım (Share) ve Destek (Support)
- **Zarif Paylaşım:** Kullanıcı bir mesajı Instagram/Twitter'da paylaşmak istediğinde, uygulamanın zarif tasarım dilini yansıtan (altında ufak bir Lumi logosu olan) otomatik bir ekran görüntüsü/kart oluşturulur.
- **Destek Ekranı:** Kullanıcıların kolayca hata bildirimi yapabileceği ve ekran görüntüsü ekleyebileceği basit iletişim arayüzü.

---

## 3. Tech Stack (Teknoloji Yığını) Önerisi

Hem iOS hem Android'de kusursuz, pürüzsüz ve animasyonları zarif bir deneyim sunmak için önerilen yapı:

### Frontend (Mobil Uygulama)
- **Framework:** **Swift & SwiftUI** (Native Apple hissiyatı, cam kırığı efektleri, pürüzsüz animasyonlar ve üst düzey zarafet için).
- **Cross-Platform Stratejisi:** Android tarafı için **Skip (skip.tools)** veya benzeri bir Swift-to-Kotlin transpiler kullanılarak aynı SwiftUI kodundan native Android uygulaması derlenecek.
- **Tasarım / UI:** Apple'ın kendi tasarım dili (Typography, Blur efektleri), cihazın kendi font ailelerinden (iOS'ta San Francisco/New York) veya özel zarif Google fontlarından (örn. Playfair Display, Lora) yararlanma.

### Backend & Veritabanı
- **Platform:** **Firebase** (Swift SDK'sı çok güçlü, hızlı çıkış ve ölçeklenebilirlik için ideal).
- **Kimlik Doğrulama:** Firebase Anonymous Authentication (Cihaz UUID'si ile).
- **Veritabanı:** Cloud Firestore (Mesaj havuzu, kullanıcı kasaları ve bekleme kuyrukları için hızlı NoSQL).
- **Sunucusuz Fonksiyonlar (Serverless):** Firebase Cloud Functions veya AWS Lambda (Mesaj gönderildiği an AI filtresini tetiklemek için).

### Yapay Zeka Filtresi (Moderasyon)
- **API:** **OpenAI API** (GPT-4o-mini veya özel eğitilmiş hafif bir model). 
- **Prompt Mantığı:** Sisteme özel bir "System Prompt" yazılarak mesajın sadece nefret/argo içermemesini değil, aynı zamanda *pozitif ve iyi niyetli* olup olmadığını analiz etmesi sağlanır.

### Widget Geliştirme
- **iOS & Android:** **Swift / WidgetKit**. Ana uygulama SwiftUI ile yazıldığı için widget entegrasyonu kusursuz olacak. Skip.tools sayesinde widget tarafı da Android'e sorunsuz aktarılacak.

### Analitik ve Güvenlik
- **Güvenli Depolama:** iOS Keychain & Android Keystore (Cihazın ban durumunu silinmelere karşı korumak için).
- **Analitik:** Mixpanel veya Firebase Analytics (Kullanıcı verisi tutmadan, sadece buton tıklama ve etkileşim oranlarını ölçmek için anonim event takibi).
