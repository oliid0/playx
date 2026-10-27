import Foundation

struct PXPlaybackChapterNavigator {
    var chapters: [PXPlaybackChapter]

    func chapter(at time: Double) -> PXPlaybackChapter? {
        chapters.last { $0.start <= time }
    }

    func next(after time: Double) -> PXPlaybackChapter? {
        chapters.first { $0.start > time + 1 }
    }

    func previous(before time: Double) -> PXPlaybackChapter? {
        chapters.last { $0.start < time - 3 }
    }

    func progress(in chapter: PXPlaybackChapter, at time: Double) -> Double {
        guard chapter.duration > 0 else { return 0 }
        return min(max((time - chapter.start) / chapter.duration, 0), 1)
    }
}
