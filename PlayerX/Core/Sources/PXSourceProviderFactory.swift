import Foundation

enum PXSourceProviderFactory {
    static func make(_ configuration: PXSourceConfiguration) -> ContentProvider? {
        switch configuration.kind {
        case .station:
            return nil
        case .jellyfin, .emby:
            return PXMediaServerProvider(configuration: configuration)
        case .webdav, .nas, .alist:
            return PXWebDAVProvider(configuration: configuration)
        case .maccms:
            return PXMacCMSProvider(configuration: configuration)
        }
    }
}
