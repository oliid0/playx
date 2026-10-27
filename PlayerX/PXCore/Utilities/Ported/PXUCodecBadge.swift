import Foundation

enum PXUCodecBadge {
    static func video(_ codec: String?) -> String {
        guard let codec, !codec.isEmpty else { return "—" }
        let value = codec.lowercased()
        if value.contains("hevc") || value.contains("h265") { return "HEVC" }
        if value.contains("avc") || value.contains("h264") { return "H.264" }
        if value.contains("av1") { return "AV1" }
        return codec.uppercased()
    }
    static func audio(_ codec: String?) -> String {
        guard let codec, !codec.isEmpty else { return "—" }
        let value = codec.lowercased()
        if value.contains("eac3") { return "E-AC3" }
        if value.contains("ac3") { return "AC3" }
        if value.contains("aac") { return "AAC" }
        if value.contains("flac") { return "FLAC" }
        return codec.uppercased()
    }
}
