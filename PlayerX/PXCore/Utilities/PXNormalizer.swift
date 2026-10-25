import Foundation

enum PXNormalizer {
    static func title(_ raw: String) -> String {
        var value = raw.lowercased()
        value = value.replacingOccurrences(of: #"[\p{P}\p{S}]"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: " ", with: "")
        value = value.replacingOccurrences(of: "第[一二三四五六七八九十0-9]+季", with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: "season[0-9]+", with: "", options: .regularExpression)
        return value
    }

    static func similarity(_ lhs: String, _ rhs: String) -> Double {
        let a = Array(title(lhs))
        let b = Array(title(rhs))
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        let setA = Set(a), setB = Set(b)
        let intersection = setA.intersection(setB).count
        let union = setA.union(setB).count
        return union > 0 ? Double(intersection) / Double(union) : 0
    }

    static func episodeNumber(from title: String) -> Int? {
        let patterns = [
            #"第\s*([0-9]+)\s*[集话話]"#,
            #"[Ee][Pp]?\s*([0-9]{1,3})"#,
            #"^\s*([0-9]{1,3})\s*$"#,
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: title) {
                return Int(title[range])
            }
        }
        return nil
    }
}
