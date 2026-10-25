import Foundation

/// 小并发闸门：首页同时拉多个站源时，最多 3 个目录请求在飞。
actor PXConcurrencyLimiter {
    private let limit: Int
    private var active = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) {
        self.limit = max(1, limit)
    }

    func acquire() async {
        if active < limit {
            active += 1
            return
        }
        await withCheckedContinuation { waiters.append($0) }
        active += 1
    }

    func release() {
        active = max(0, active - 1)
        guard !waiters.isEmpty else { return }
        let waiter = waiters.removeFirst()
        waiter.resume()
    }
}
