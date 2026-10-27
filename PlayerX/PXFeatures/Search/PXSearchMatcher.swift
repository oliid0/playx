import Foundation

struct PXSearchMatch {
    var score: Int
    var normalizedTitle: String
}

enum PXSearchMatcher {
    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
        let allowed = folded.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar.value > 0x2E80
        }
        return String(String.UnicodeScalarView(allowed)).lowercased()
    }

    static func score(title: String, subtitle: String?, overview: String?, query: String) -> Int? {
        let q = normalize(query)
        guard !q.isEmpty else { return nil }
        let t = normalize(title)
        guard !t.isEmpty else { return nil }
        if t == q { return 1000 }
        if t.hasPrefix(q) { return 900 - min(t.count - q.count, 100) }
        if t.contains(q) { return 800 - min(t.count - q.count, 100) }
        let tokens = query.split(whereSeparator: \.isWhitespace).map { normalize(String($0)) }.filter { !$0.isEmpty }
        if !tokens.isEmpty, tokens.allSatisfy({ t.contains($0) }) { return 600 - min(t.count, 100) }
        let extra = normalize([subtitle, overview].compactMap { $0 }.joined(separator: " "))
        if tokens.contains(where: { extra.contains($0) }) { return 300 }
        return nil
    }
}
