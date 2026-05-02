# Lumi App Store metadata — style guide

İki ayrı kontrat: (1) AI yazım kalıplarından kaçınma, (2) ASO uygunluğu. Her metin satırı ikisini de geçmeli.

## Bölüm 1 — AI tell'leri ve yasaklılar

ChatGPT/Claude'un 2024-2026 ürettiği marketing copy'sinin tipik parmak izleri. Bunları KULLANMA.

### A. Karakter / noktalama tell'leri (kategori: çok belirgin)

| Tell | Neden AI'dan belli | Yerine |
|---|---|---|
| **Em-dash `—`** (uzun tire) | OpenAI training data'sında çok ağırlıklı — özellikle bölüm başlığı `— X —` deseni | Nokta, virgül, iki nokta üst üste, ya da yeni paragraf |
| **`— Word —` başlık deseni** | "Anonymous by design" / "— ZEN GARDEN AESTHETIC —" | Düz uppercase başlık, ya da hiç başlık |
| **Smart quotes `"`** "düz olarak girilmiş" `""` ile karışık | İnsan tutarlı; AI prompt'a göre karıştırır | App Store'da düz `"` kullan, tutarlı |
| **Three-dots `…` (Unicode horizontal ellipsis)** ardarda | İnsan `...` yazar | `...` kullan veya sil |
| **Excessive `:` lists** | Her sayfada `Lumi: vetro, luce, colori` gibi colon-list | Cümle olarak yaz |

### B. Söz dizimi / cümle yapısı tell'leri (kategori: belirgin)

| Tell | Örnek | Sorun |
|---|---|---|
| **"It's not X. It's Y." kapanışı** | "Lumi is not a social network. It's a breath." | LLM'lerin antithesis fetishi — hemen göze çarpar |
| **"In a world of X, Y" açılışı** | "In a world of noise, Lumi is..." | Çok klişe |
| **"Imagine X..." açılışı** | "Imagine a place where..." | LLM template |
| **Triadic listing herşey** | "X, Y, and Z" yapısının her cümlede tekrarı | Bir kez OK, üç kez paragrafta = AI |
| **Triadic negation** | "No accounts. No profiles. No tracking." | LLM ritmi |
| **Anaphora** | "For X. For Y. For Z." (ardı ardına) | AI'ın sevdiği "şiirsel" tekrar |
| **"It's worth noting that..." / "Ultimately" / "In essence"** | Geçiş ifadeleri | LLM doldurmacısı |
| **Bullet'ların hepsi aynı gramatik yapıda** | Her bullet `Verb + a noun` pattern'i | Çok mükemmel parallel structure = AI |
| **Symmetrical sentence pairs** | "You write. You receive. You connect." | Cute ama AI imzası |

### C. Sözcük tell'leri (kategori: orta)

Aşırı sıklıkla kullanılırsa = AI:
- **sanctuary / oasis / journey / tapestry / treasure trove / kaleidoscope / myriad**
- **whispers / sussurri / susurros / Hauch** (mistik vocab fetishi)
- **delve into / dive into / embark on / leverage / unlock the power of / elevate / seamlessly / effortlessly**
- **crafted with care / thoughtfully designed / tailored to / designed to**
- **bottle in the sea** (anonymous message için AI'ın sevdiği metafor)
- **Capitalized concept-phrases** ("Mindful Engagement", "Anonymous By Design") — markaya değer Concept-Phrasing dışında kullanma

### D. AI/İçerik moderasyon mention'u

- "Filtered by AI" / "AI-moderated" / "intelligence artificielle" / "IA bienveillante" / "KI" — **kaldır**.
- "Carefully reviewed" / "moderated for kindness" / "filtered before reaching you" tercih et.
- AI bilgisi gerekiyorsa privacy policy'de açıkla, marketing copy değil.

### E. Çoklu-dilde aynı template tell'i

5 Romance/Germanic dilin **birebir aynı yapıdan dönmesi** tek başına AI imzası. Çözüm: her dilin descriptionu **kendi başına** yazılmış gibi davranmalı — paragraf sırası farklı olabilir, hangi feature'a vurgu yapacağı farklı olabilir, tonalite o dilin marketing kültürüne uymalı.

- DE: daha pragmatik, daha az duygusal
- FR: literary, ama clichési kabul ediliyor
- IT: warmer, lyrical
- ES: warm, friendly
- EN-US: casual, lower-case başlıklar OK
- TR: doğrudan, `sen` formu, lyrical
- JA: 静かな (quiet) ton, `・` punctuation, indirect
- KO: 친근한 (familiar), softer
- ZH-Hans: 中文式 metaphor (树洞/漂流瓶), 互联网 slang OK
- PT-BR: warm, friendly, `cantinho` gibi diminutive

---

## Bölüm 2 — ASO en iyi pratikler (Apple App Store)

Apple'ın resmi ranking sinyalleri ([WWDC sessions](https://developer.apple.com/app-store/optimization/) + 2024 community konsensüsü):

### Indekslenen alanlar (ranking için)
1. **App Name** (30 karakter)
2. **Subtitle** (30 karakter)
3. **Keywords field** (100 karakter, locale başına)
4. **In-app purchase isimleri** (kullanmıyoruz)

### İndekslenmeyen alanlar (sadece conversion için)
1. **Description** (4000 karakter)
2. **Promotional Text** (170 karakter)
3. **What's New** (4000 karakter)

> Bu Lumi için kritik: Description rewrite edilirken keyword stuffing'e gerek yok. Yapacağımız iş **conversion** odaklı — kullanıcı App Store sayfasına gelince ikna olsun, indir.

### Apple'ın bilinen kuralları

| Kural | Detay |
|---|---|
| **Keywords field pluralleri** | "letter" yazınca "letters" da hit eder. **Pluralleri yazma**, yer harcar |
| **App Name kelimelerini keywords'e tekrar koyma** | "Lumi" name'deyse keywords'te "Lumi" yer israfı |
| **Subtitle kelimelerini de tekrar koyma** | Subtitle'daki kelimeler ranking'e sayar |
| **Virgül arasında boşluk yok** | `kindness,anonymous,calm` — boşluk her yerde 1 char yer (100/100) |
| **Marka/competitor names yasak** | Apple kabul etmez |
| **Özel karakter (`&`, `!`) keyword'de yer harcar** | Sade tut |
| **Lokalizasyon başına 100 karakter** | Her dil ayrı 100 char |

### Description'da conversion best practices
- **İlk 252 karakter (above fold)** kullanıcının "more" tıklamadan gördüğü kısım — buraya en güçlü hook + value prop
- **Uzunluk önemli**: 1500-2500 char arası → engagement / conversion için iyi (boş gözükmez, dolu gözükmez)
- **Sosyal proof**, eğer varsa, üst kısımda (Lumi'de yok, atla)
- **Feature bullet listesi** mantıklı, ama her bullet 1-2 cümle
- **Net call to action** sona doğru ("Send a message into the light. Let it find someone who needs it." gibi)
- **Spec/teknik detay yok** — Privacy/Aesthetic ana mesaj olarak iyi, ama 3 paragraf değil

### Promotional Text (170 char) tactical
- **App review olmadan değiştirilebilir** — promo, holiday, A/B test için bonus
- Mevcut Lumi'ler iyi kullanılmış
- Build 14 release'inde "+ Apple Watch" anonsu için ideal

### What's New (her version'a 4000 char)
- Şu an boş — Build 14 için doldurulması lazım
- Watch ve içerik update'leri vurgu

---

## Bölüm 3 — Lumi'ye özel kararlar

### Marka voice — koru
- Sıcak, yumuşak, niyetli
- Brand metafor: **rüzgardaki mektuplar / letters in the wind** — bu zaten brand name, koru
- **"Quiet"** kelimesi brand voice'un parçası — yasaklamayalım, ama dilimleyerek kullan (bir paragrafta 1)
- **"Garden"** brand voice'un parçası (Japon estetiği bağlamında) — koru, ama "secret garden of kindness" gibi cliché format değil

### Watch desteği — yeni değer önerisi
v14 release ile Apple Watch app + complication geliyor. Tüm 10 dilin description'ında **Watch mention'ı** ekleyelim. Bu hem ASO hem conversion kazancı:
- Yeni keyword: "watch" (en'de), "saat" (tr'de), etc. — keyword field'a eklenmeli
- Description'da kısa bir paragraf veya feature satırı

### Length hedefleri
| Locale | Mevcut desc length | Yeni desc length hedefi |
|---|---|---|
| EN-US | ~1500 | 1400-1700 |
| FR-FR | ~1700 | 1500-1800 |
| IT | ~1700 | 1500-1800 |
| DE-DE | ~1700 | 1500-1800 |
| ES-ES | ~1700 | 1500-1800 |
| TR | ~1900 | 1800-2000 (mevcut güzel) |
| JA | ~900 | 900-1100 (Japonca'da öz daha değerli) |
| KO | ~1100 | 1100-1300 |
| ZH-Hans | ~1400 | 1400-1600 |
| PT-BR | ~1900 | 1700-1900 |

### İlk paragraf (above fold, ~250 char)
Her dilin ilk 250 char'ı **immediate hook + value prop + emotional payoff** içermeli, AI cliché'siz. Şu üç soruya cevap:
1. Bu nedir? (anonim mektup uygulaması)
2. Neden umurumda olsun? (sıcak/güvenli alan)
3. Şu an ne yapabilirim? (aç ve oku/yaz)

### Kapanış
"It's not X, it's Y" / "It's a breath" KAPATMA YASAK. Her dilin kendi imzası olsun:
- Concrete bir cümle
- Markanın bir feature'ına bağlı
- Tek satır, kısa

### Keyword stratejisi
Mevcut keyword field'ları **yeniden değerlendireceğim** — fakat AGRESİF değiştirmeyeceğim çünkü:
- Mevcut field'lar çok iyi optimize edilmiş (locale-specific, pluralsiz, kısa)
- Sadece **Watch** keyword'lerini ekleyeceğim
- Eğer 100 char limit'i aşıyorsa eski keyword'lerden bir-iki seyrek aranan'ı atacağız

Watch için her dilde:
- en: `watch`
- tr: `saat`
- ja: `ウォッチ`
- ko: `워치`
- zh-Hans: `手表`
- de: `uhr`
- fr: `montre`
- es: `reloj`
- it: `orologio`
- pt-BR: `relógio`
