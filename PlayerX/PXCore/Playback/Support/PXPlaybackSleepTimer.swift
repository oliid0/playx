import Foundation
import Combine

@MainActor
final class PXPlaybackSleepTimer: ObservableObject {
    @Published private(set) var remaining: TimeInterval?
    private var task: Task<Void, Never>?
    var onFire: (() -> Void)?

    func start(minutes: Int) {
        cancel()
        guard minutes > 0 else { return }
        remaining = TimeInterval(minutes * 60)
        task = Task { @MainActor [weak self] in
            while let self, let value = self.remaining, value > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                self.remaining = max(0, (self.remaining ?? 0) - 1)
            }
            guard !Task.isCancelled else { return }
            self?.onFire?()
            self?.remaining = nil
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        remaining = nil
    }

    var label: String? {
        guard let remaining else { return nil }
        return PXFormat.time(remaining)
    }
}
