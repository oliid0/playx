import Foundation

enum PXUEngineCapabilityLabel {
    static func title(_ capability: PXEngineCapability) -> String {
        switch capability {
        case .pictureInPicture: "画中画"
        case .airPlay: "AirPlay"
        case .systemPlaylist: "系统播放队列"
        case .ffmpeg: "FFmpeg"
        case .libass: "libass 字幕"
        case .externalSubtitle: "外挂字幕"
        case .subtitleStyle: "字幕样式"
        case .hdr: "HDR"
        case .hardwareDecode: "硬解"
        }
    }
}
