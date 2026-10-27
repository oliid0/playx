import SwiftUI

enum PXPlaybackEngineFactory {
    @MainActor
    static func make(_ kind: PXPlayerEngineKind) -> (any PXPlaybackEngine)? {
        switch kind {
        case .pillarbox:
            #if canImport(PillarboxPlayer)
            return PXPillarboxEngine()
            #elseif os(macOS)
            return PXMacPillarboxEngine()
            #else
            return PXAVPlayerEngine()
            #endif
        case .erika:
            #if canImport(ErikaKit)
            let engine = PXErikaEngine()
            return engine.isUsable ? engine : PXAVPlayerEngine()
            #else
            return PXAVPlayerEngine()
            #endif
        case .native:
            return PXAVPlayerEngine()
        }
    }

    @MainActor
    static func resolve(_ requested: PXPlayerEngineKind) -> (any PXPlaybackEngine)? {
        if let engine = make(requested) { return engine }
        if requested != .native { return PXAVPlayerEngine() }
        return nil
    }
}
