import Foundation

actor PXAsyncCache<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]
    private let capacity: Int

    init(capacity: Int = 256) {
        self.capacity = capacity
    }

    func value(for key: Key) -> Value? {
        storage[key]
    }

    func insert(_ value: Value, for key: Key) {
        if storage.count >= capacity, let first = storage.keys.first {
            storage.removeValue(forKey: first)
        }
        storage[key] = value
    }

    func removeAll() {
        storage.removeAll()
    }
}
