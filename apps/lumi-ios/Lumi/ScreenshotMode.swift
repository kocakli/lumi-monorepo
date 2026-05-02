import Foundation

enum ScreenshotMode {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LumiScreenshotMode")
        #else
        false
        #endif
    }

    static var screen: String {
        value(after: "-LumiScreen") ?? "home"
    }

    static var language: String {
        if let explicit = value(after: "-LumiLanguage") {
            return normalizedLanguage(explicit)
        }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return normalizedLanguage(preferred)
    }

    static var writeDraft: String {
        localized(
            en: "You made today softer just by being here.",
            tr: "Bugünü, burada olman bile daha yumuşak yaptı.",
            es: "Hiciste que hoy se sintiera más suave.",
            fr: "Ta présence rend déjà cette journée plus douce.",
            de: "Allein deine Nähe macht diesen Tag sanfter.",
            ja: "ここにいてくれるだけで、今日はやさしくなる。",
            it: "Hai reso oggi più dolce solo essendo qui.",
            ko: "여기 있어 주는 것만으로 오늘이 더 부드러워졌어요.",
            ptBR: "Você deixou o dia mais leve só por estar aqui.",
            zhHans: "只要你在这里，今天就变得更温柔。"
        )
    }

    static var sampleFeed: [LumiMessage] {
        [
            LumiMessage(
                id: "screenshot-feed-1",
                text: localized(
                    en: "You are not behind. You are becoming, quietly and beautifully.",
                    tr: "Geride değilsin. Sessizce ve güzelce dönüşüyorsun.",
                    es: "No vas tarde. Estás floreciendo en silencio.",
                    fr: "Tu n'es pas en retard. Tu deviens, doucement.",
                    de: "Du bist nicht zu spät. Du wirst, ganz leise.",
                    ja: "遅れていないよ。静かに、きれいに育っている。",
                    it: "Non sei in ritardo. Stai diventando, in silenzio e con bellezza.",
                    ko: "뒤처진 게 아니에요. 조용하고 아름답게 성장하고 있어요.",
                    ptBR: "Você não está atrasado. Está se tornando, em silêncio e com beleza.",
                    zhHans: "你没有落后。你正在安静而美好地成长。"
                ),
                mood: localized(
                    en: "Peaceful",
                    tr: "Huzurlu",
                    es: "Calma",
                    fr: "Paisible",
                    de: "Friedlich",
                    ja: "穏やか",
                    it: "Sereno",
                    ko: "평온함",
                    ptBR: "Tranquilo",
                    zhHans: "平静"
                )
            ),
            LumiMessage(
                id: "screenshot-feed-2",
                text: localized(
                    en: "Someone will be glad you kept going today.",
                    tr: "Bugün devam ettiğin için biri sevinecek.",
                    es: "Alguien se alegrará de que sigas hoy.",
                    fr: "Quelqu'un sera heureux que tu continues aujourd'hui.",
                    de: "Jemand wird froh sein, dass du heute weitermachst.",
                    ja: "今日も進んだあなたを、誰かがうれしく思う。",
                    it: "Qualcuno sarà felice che tu abbia continuato oggi.",
                    ko: "오늘도 계속 나아간 당신을 누군가는 기뻐할 거예요.",
                    ptBR: "Alguém ficará feliz por você ter continuado hoje.",
                    zhHans: "有人会因为你今天坚持下去而感到开心。"
                ),
                mood: localized(
                    en: "Motivating",
                    tr: "Motive Eden",
                    es: "Motivadora",
                    fr: "Motivant",
                    de: "Motivierend",
                    ja: "前向き",
                    it: "Motivante",
                    ko: "응원",
                    ptBR: "Motivador",
                    zhHans: "鼓励"
                )
            )
        ]
    }

    static var vaultMoments: [VaultMoment] {
        [
            VaultMoment(
                id: "screenshot-vault-1",
                date: localized(
                    en: "APRIL 27 - MORNING",
                    tr: "27 NİSAN - SABAH",
                    es: "27 ABRIL - MAÑANA",
                    fr: "27 AVRIL - MATIN",
                    de: "27. APRIL - MORGEN",
                    ja: "4月27日 - 朝",
                    it: "27 APRILE - MATTINA",
                    ko: "4월 27일 - 아침",
                    ptBR: "27 DE ABRIL - MANHÃ",
                    zhHans: "4月27日 - 早晨"
                ),
                quote: sampleFeed[0].text,
                tags: [sampleFeed[0].mood.uppercased()],
                imageName: nil
            ),
            VaultMoment(
                id: "screenshot-vault-2",
                date: localized(
                    en: "APRIL 25 - EVENING",
                    tr: "25 NİSAN - AKŞAM",
                    es: "25 ABRIL - TARDE",
                    fr: "25 AVRIL - SOIR",
                    de: "25. APRIL - ABEND",
                    ja: "4月25日 - 夜",
                    it: "25 APRILE - SERA",
                    ko: "4월 25일 - 저녁",
                    ptBR: "25 DE ABRIL - NOITE",
                    zhHans: "4月25日 - 晚上"
                ),
                quote: sampleFeed[1].text,
                tags: [sampleFeed[1].mood.uppercased()],
                imageName: nil
            )
        ]
    }

    static var pairs: [PairedUser] {
        [
            PairedUser(id: "screenshot-pair-1", partnerUid: "screenshot-partner-1", nickname: "Mina"),
            PairedUser(id: "screenshot-pair-2", partnerUid: "screenshot-partner-2", nickname: "Noa")
        ]
    }

    static var incomingRequests: [PairRequest] {
        [
            PairRequest(
                id: "screenshot-request-1",
                fromUserId: "screenshot-friend",
                toUserId: "screenshot-user",
                fromUserCode: "LUMI-7284",
                status: "pending"
            )
        ]
    }

    static var shareMessage: String {
        sampleFeed[0].text
    }

    static var shareMood: String {
        sampleFeed[0].mood
    }

    @MainActor
    static func configure(router: AppRouter) {
        switch screen {
        case "receive":
            router.currentScreen = .receive
            router.showWrite = false
        case "write":
            router.currentScreen = .home
            router.showWrite = true
        case "vault":
            router.currentScreen = .vault
            router.showWrite = false
        case "settings":
            router.currentScreen = .settings
            router.showWrite = false
        case "pairs":
            router.currentScreen = .pairs
            router.showWrite = false
        default:
            router.currentScreen = .home
            router.showWrite = false
        }
    }

    private static func value(after flag: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: flag) else { return nil }
        let next = args.index(after: index)
        return next < args.endIndex ? args[next] : nil
    }

    private static func normalizedLanguage(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.hasPrefix("tr") { return "tr" }
        if lower.hasPrefix("es") { return "es" }
        if lower.hasPrefix("fr") { return "fr" }
        if lower.hasPrefix("de") { return "de" }
        if lower.hasPrefix("ja") { return "ja" }
        if lower.hasPrefix("it") { return "it" }
        if lower.hasPrefix("ko") { return "ko" }
        if lower.hasPrefix("pt") { return "pt-BR" }
        if lower.hasPrefix("zh") { return "zh-Hans" }
        return "en"
    }

    private static func localized(
        en: String,
        tr: String,
        es: String,
        fr: String,
        de: String,
        ja: String,
        it: String,
        ko: String,
        ptBR: String,
        zhHans: String
    ) -> String {
        switch language {
        case "tr": return tr
        case "es": return es
        case "fr": return fr
        case "de": return de
        case "ja": return ja
        case "it": return it
        case "ko": return ko
        case "pt-BR": return ptBR
        case "zh-Hans": return zhHans
        default: return en
        }
    }
}
