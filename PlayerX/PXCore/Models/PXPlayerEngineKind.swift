import Foundation

/// 三种播放内核。Pillarbox 是默认；Erika 是内置 FFmpeg/libass 的高阶内核；
/// Native 是系统 AVPlayer 直连，体积最小、兼容性最好。
enum PXPlayerEngineKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case pillarbox
    case erika
    case native

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pillarbox: "Pillarbox"
        case .erika: "Erika"
        case .native: "原生 AVPlayer"
        }
    }

    var summary: String {
        switch self {
        case .pillarbox: "SRG SSR · 系统播放队列 · 画中画 / AirPlay"
        case .erika: "Rust · FFmpeg · libass · Metal"
        case .native: "Apple AVFoundation · 零额外依赖"
        }
    }

    var symbol: String {
        switch self {
        case .pillarbox: "circle.grid.cross.fill"
        case .erika: "bolt.fill"
        case .native: "apple.logo"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .pillarbox:
            #if os(iOS) || os(tvOS) || os(macOS)
            true
            #else
            false
            #endif
        case .erika:
            #if (os(iOS) || os(macOS)) && canImport(ErikaKit)
            true
            #else
            false
            #endif
        case .native:
            true
            }
        }

    var unavailableReason: String? {
        if isAvailable { return nil }
        switch self {
        case .pillarbox: return "macOS 上 Pillarbox 仅提供 iOS/tvOS 播放器，请使用 Erika 或原生内核。"
        case .erika: return "当前平台没有可用的 Erika 二进制切片。"
        case .native: return nil
        }
    }

    var capabilities: Set<PXEngineCapability> {
        switch self {
        case .pillarbox:
            [.pictureInPicture, .airPlay, .systemPlaylist, .chapterNavigation, .nowPlaying]
        case .erika:
            [.ffmpeg, .libass, .externalSubtitle, .subtitleStyle, .hdr, .hardwareDecode,
             .chapterNavigation, .nowPlaying, .screenshot]
        case .native:
            [.pictureInPicture, .airPlay, .nowPlaying, .hardwareDecode, .chapterNavigation]
        }
    }

    static var defaultKind: PXPlayerEngineKind {
        #if os(macOS)
        .erika
        #else
        .pillarbox
        #endif
    }

    static var availableKinds: [PXPlayerEngineKind] {
        allCases.filter(\.isAvailable)
    }
}

enum PXEngineCapability: String, Hashable {
    case pictureInPicture
    case airPlay
    case systemPlaylist
    case ffmpeg
    case libass
    case externalSubtitle
    case subtitleStyle
    case hdr
    case hardwareDecode
    case chapterNavigation
    case nowPlaying
    case screenshot

    var title: String {
        switch self {
        case .pictureInPicture: "画中画"
        case .airPlay: "AirPlay"
        case .systemPlaylist: "系统队列"
        case .ffmpeg: "FFmpeg 软解"
        case .libass: "libass 字幕"
        case .externalSubtitle: "外挂字幕"
        case .subtitleStyle: "字幕样式"
        case .hdr: "HDR"
        case .hardwareDecode: "硬件解码"
        case .chapterNavigation: "章节导航"
        case .nowPlaying: "锁屏/控制中心"
        case .screenshot: "截图"
        }
    }
}
