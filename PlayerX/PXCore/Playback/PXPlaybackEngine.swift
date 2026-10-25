import SwiftUI

@MainActor
protocol PXPlaybackEngine: AnyObject {
    static var kind: PXPlayerEngineKind { get }
    var kind: PXPlayerEngineKind { get }
    var snapshot: PXPlayerSnapshot { get }
    var onChange: ((PXPlayerSnapshot) -> Void)? { get set }
    var supportsExternalSubtitles: Bool { get }

    func makeSurface() -> AnyView
    func load(url: URL, headers: [String: String], startAt: Double, autoplay: Bool)
    func play()
    func pause()
    func seek(to seconds: Double)
    func setRate(_ rate: Double)
    func setVolume(_ volume: Double)
    func setMuted(_ muted: Bool)
    func stop()
    func selectAudio(_ id: String)
    func selectSubtitle(_ id: String?)
    func setSubtitleScale(_ scale: Double)
    func setBackgroundPlayback(_ active: Bool)
}

@MainActor
class PXBasePlaybackEngine: PXPlaybackEngine {
    open class var kind: PXPlayerEngineKind { .native }
    var kind: PXPlayerEngineKind { Self.kind }
    private(set) var snapshot = PXPlayerSnapshot()
    var onChange: ((PXPlayerSnapshot) -> Void)?
    var supportsExternalSubtitles: Bool { false }

    func publish(_ mutate: (inout PXPlayerSnapshot) -> Void) {
        mutate(&snapshot)
        onChange?(snapshot)
    }

    func makeSurface() -> AnyView { AnyView(Color.black) }
    func load(url: URL, headers: [String: String], startAt: Double, autoplay: Bool) {}
    func play() {}
    func pause() {}
    func seek(to seconds: Double) {}
    func setRate(_ rate: Double) {}
    func setVolume(_ volume: Double) {}
    func setMuted(_ muted: Bool) {}
    func stop() {}
    func selectAudio(_ id: String) {}
    func selectSubtitle(_ id: String?) {}
    func setSubtitleScale(_ scale: Double) {}
    func setBackgroundPlayback(_ active: Bool) {}

    func mapState(_ state: PXPlaybackState) {
        publish { $0.state = state }
    }
}
