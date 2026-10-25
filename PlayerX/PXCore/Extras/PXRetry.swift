import Foundation
enum PXRetry {
    static func run<T>(attempts: Int = 3, operation: () async throws -> T) async throws -> T {
        var lastError: Error?
        for attempt in 0..<max(1, attempts) {
            do { return try await operation() }
            catch {
                lastError = error
                if attempt + 1 < attempts {
                    try? await Task.sleep(nanoseconds: UInt64(300_000_000 * (attempt + 1)))
                }
            }
        }
        throw lastError ?? PXHTTPError.transport("请求失败")
    }
}
