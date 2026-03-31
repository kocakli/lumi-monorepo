# Lumi - Genel Özet ve Yol Haritası

## 1. Proje Nedir?
**Lumi**, insanların birbirlerine tamamen anonim ve rastgele şekilde pozitif mesajlar gönderip alabildiği, dijital bir "şişe içinde mektup" uygulamasıdır. "Sadece iyi hisler" mottosuyla yola çıkan uygulama, karmaşadan uzak, Japon minimalizmi esintileri taşıyan zarif bir kullanıcı arayüzüne sahiptir.

## 2. Monorepo İçeriği (Ne Nerede?)

Bu GitHub reposu, Lumi uygulamasının tüm parçalarını tek bir yerde toplamak için "Monorepo" mimarisiyle kurulmuştur:

- **`apps/lumi-ios/`**: Uygulamanın SwiftUI ile yazılmış ana iOS kodlarını ve Kilit Ekranı / Ana Ekran Widget'larını barındırır. (Tüm tasarım buradadır).
- **`backend/functions/`**: Firebase Cloud Functions kodlarını içerir. TypeScript ile yazılmış bu bölümde, yapay zeka (OpenAI) entegrasyonlu pozitiflik filtresi ve gölge ban (shadowban) güvenlik sistemleri yer alır.
- **`docs/`**: Uygulamanın Ürün Gereksinim Dokümanı (PRD) ve Adım Adım Proje Planı dosyalarını barındırır.
- **`packages/`**: İlerleyen aşamalarda eklenecek ortak tasarım bileşenleri (Shared UI) ve ana mantık sınıfları (Core Logic) için ayrılmış klasördür.

## 3. Temel Özellikler
- **Kayıtsız Onboarding:** Kullanıcılardan e-posta veya telefon numarası istenmez. Arka planda cihaz kimliği (UUID) ile anonim giriş yapılır.
- **AI Moderasyonu:** Gönderilen her mesaj yapay zeka tarafından saniyeler içinde denetlenir. Sadece pozitif mesajlar havuza düşer.
- **Lumi Kutusu (Vault):** Kullanıcıların kendilerini iyi hissettiren mesajları sakladığı arşiv alanı.
- **Hassas Günler Modu:** Kullanıcının, özellikle desteğe ihtiyaç duyduğu dönemleri işaretleyip, sistemden daha yoğun pozitif mesajlar alabildiği özel mod.
- **Özel Bağlantı Kodu:** Kullanıcıların "LUMI-84X2" gibi kodlarını eşleştirerek birbirleriyle anonim ama karşılıklı mesajlaşabilmeleri.
- **WidgetKit Desteği:** iOS kilit ekranı ve ana ekranında gün içinde sürpriz mesajlar gösteren zarif widgetlar.

## 4. Geliştirici Belgeleri
Daha detaylı bilgi, teknoloji yığını (Tech Stack) ve sıradaki görevler (Task List) için `docs/` klasöründeki şu dosyalara göz atın:
1. `lumi_prd_tech_stack.md`: Ürün konsepti ve teknoloji mimarisi.
2. `lumi_project_plan.md`: Adım adım yapılacaklar listesi (Faz 1 - Faz 5).

---
*Lumi - Sadece iyi hisler. ✨*