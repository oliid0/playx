import Foundation

struct PXPlayerSeekPolicy {
    var duration: Double
    var forwardSkip: Double
    var backwardSkip: Double

    func clamp(_ target: Double) -> Double {
        min(max(target, 0), max(0, duration - 0.2))
    }

    func skip(forward: Bool, from time: Double) -> Double {
        clamp(time + (forward ? forwardSkip : -backwardSkip))
    }

    /// 横滑距离换算：全屏宽度约对应 10 分钟，短视频至少 60 秒。
    func dragTarget(start: Double, translation: CGFloat, width: CGFloat) -> Double {
        guard width > 1 else { return clamp(start) }
        let range = min(max(duration, 60), 600)
        return clamp(start + Double(translation / width) * range)
    }
}
