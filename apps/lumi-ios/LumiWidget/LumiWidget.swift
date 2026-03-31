import WidgetKit
import SwiftUI

// Widget için Veri Modeli
struct LumiEntry: TimelineEntry {
    let date: Date
    let message: String
}

// Timeline Provider (Widget'ı güncelleyen yapı)
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LumiEntry {
        LumiEntry(date: Date(), message: "Derin bir nefes al, her şey yolunda.")
    }

    func getSnapshot(in context: Context, completion: @escaping (LumiEntry) -> ()) {
        let entry = LumiEntry(date: Date(), message: "Bugün birine umut olabilirsin.")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let messages = [
            "Gülümsemeyi unutma, sana çok yakışıyor.",
            "Bugün harika şeyler olacak.",
            "Kendine nazik davran, elinden geleni yapıyorsun.",
            "Küçük bir adım bile ileriye gitmektir."
        ]
        
        var entries: [LumiEntry] = []
        let currentDate = Date()
        
        // Widget'ı her saat başı yeni bir mesajla güncelliyoruz
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let randomMessage = messages.randomElement() ?? "İyi hisset."
            let entry = LumiEntry(date: entryDate, message: randomMessage)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// Widget'ın Görünümü (UI)
struct LumiWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular, .accessoryInline:
            // Kilit Ekranı (Lock Screen) Görünümleri
            VStack(alignment: .leading) {
                if family == .accessoryRectangular {
                    Text(entry.message)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("✨ " + entry.message)
                }
            }
        default:
            // Ana Ekran (Home Screen) Görünümleri
            ZStack {
                // Zarif arka plan
                Color(red: 0.98, green: 0.98, blue: 0.96)
                
                VStack(alignment: .leading, spacing: 10) {
                    // Şık ikon / Logo temsilcisi
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: family == .systemSmall ? 12 : 16, weight: .light))
                            .foregroundColor(.black.opacity(0.4))
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Mesaj Metni
                    Text(entry.message)
                        .font(.custom("PlayfairDisplay-Regular", size: family == .systemLarge ? 28 : (family == .systemSmall ? 16 : 22)))
                        .lineSpacing(4)
                        .foregroundColor(Color.black.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.7)
                    
                    Spacer()
                    
                    // Footer
                    HStack {
                        Spacer()
                        Text("Lumi")
                            .font(.system(size: 10, weight: .light, design: .serif))
                            .foregroundColor(Color.black.opacity(0.3))
                            .kerning(2)
                    }
                }
                .padding(family == .systemLarge ? 24 : 16)
            }
        }
    }
}

// Widget'ın Kendisi
@main
struct LumiWidget: Widget {
    let kind: String = "LumiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LumiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lumi - İyi Hisler")
        .description("Gün içinde sana rastgele iyi hissettiren mesajlar getirir.")
        // Tüm boyutları ve kilit ekranı widget'larını destekler
        .supportedFamilies([
            .systemSmall, 
            .systemMedium, 
            .systemLarge,
            .accessoryRectangular, // Kilit Ekranı Dikdörtgen
            .accessoryInline       // Kilit Ekranı Satır İçi (Tarihin yanı)
        ])
    }
}

// Önizleme (Preview)
struct LumiWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LumiWidgetEntryView(entry: LumiEntry(date: Date(), message: "Derin bir nefes al, her şey yolunda."))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            LumiWidgetEntryView(entry: LumiEntry(date: Date(), message: "Bugün belki her şey plana uygun gitmedi ama nefes alıyorsun ve yeniden başlamak için şansın var."))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                
            LumiWidgetEntryView(entry: LumiEntry(date: Date(), message: "Unutma, bazen en büyük başarı sadece denemeye devam etmektir. Senin o içindeki ışık bugün birilerine umut oldu. Kendine nazik davran."))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                
            LumiWidgetEntryView(entry: LumiEntry(date: Date(), message: "Bugün harika şeyler olacak."))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        }
    }
}