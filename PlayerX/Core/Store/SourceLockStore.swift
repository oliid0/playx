import Foundation
import Security

/// 站源密码锁。Go 核心完全不参与这部分（调研报告确认过：上游红果鉴/真果鉴二进制的区分是编译期的,
/// 同一个上游真果鉴二进制里"哪些站源默认隐藏"纯粹是客户端 UI 过滤），纯本地逻辑。
///
/// 规则抄自 guoapp-src 的 Dart 实现：3-12 位纯数字 PIN，PBKDF2-HMAC-SHA256 120000 次迭代、
/// 32 字节输出、16 字节随机 salt；连续失败 3 次后指数退避。解锁状态只在本次 App 运行期间
/// 有效，重启要重新输入——不是漏做持久化，是照抄的原版行为。
struct SourceLockRecord: Codable {
    var salt: Data
    var hash: Data
    var failedAttempts: Int = 0
    var lockedUntil: Date?
}

enum SourceLockError: Error, LocalizedError {
    case invalidPin
    case tooManyAttempts(retryAfter: TimeInterval)
    case incorrectPin

    var errorDescription: String? {
        switch self {
        case .invalidPin: return "密码必须是 3-12 位数字"
        case .tooManyAttempts(let retryAfter): return "错误次数过多，请 \(max(1, Int(retryAfter.rounded(.up)))) 秒后再试"
        case .incorrectPin: return "密码不对"
        }
    }
}

@MainActor
final class SourceLockStore: ObservableObject {
    static let shared = SourceLockStore()

    @Published private(set) var record: SourceLockRecord?
    /// 本次 App 运行期间是否已经输对过密码；不持久化，重启要重新输入。
    @Published private(set) var isUnlockedThisLaunch = false

    private let storageKey = "playerx.sourceLock.v1"
    private let iterations: UInt32 = 120_000
    private let keyLength = 32
    private let saltLength = 16

    var hasPassword: Bool { record != nil }

    private init() { load() }

    func setPassword(_ pin: String) throws {
        try Self.validate(pin)
        let salt = Self.randomBytes(count: saltLength)
        let hash = Self.derive(pin: pin, salt: salt, iterations: iterations, keyLength: keyLength)
        record = SourceLockRecord(salt: salt, hash: hash)
        isUnlockedThisLaunch = true
        save()
    }

    /// 校验成功会把 `isUnlockedThisLaunch` 置 true；失败会抛出具体原因（含退避剩余时间）。
    func verify(_ pin: String) throws {
        guard var current = record else {
            throw SourceLockError.incorrectPin
        }
        if let lockedUntil = current.lockedUntil, lockedUntil > Date() {
            throw SourceLockError.tooManyAttempts(retryAfter: lockedUntil.timeIntervalSinceNow)
        }
        let candidate = Self.derive(pin: pin, salt: current.salt, iterations: iterations, keyLength: keyLength)
        if candidate == current.hash {
            current.failedAttempts = 0
            current.lockedUntil = nil
            record = current
            isUnlockedThisLaunch = true
            save()
        } else {
            current.failedAttempts += 1
            if current.failedAttempts >= 3 {
                let backoff = min(pow(2.0, Double(current.failedAttempts - 2)), 300)
                current.lockedUntil = Date().addingTimeInterval(backoff)
            }
            record = current
            save()
            throw SourceLockError.incorrectPin
        }
    }

    /// 重新锁上（比如切后台），不影响已经设置的密码本身。
    func lockAgain() {
        isUnlockedThisLaunch = false
    }

    private static func validate(_ pin: String) throws {
        guard pin.count >= 3, pin.count <= 12, pin.allSatisfy(\.isNumber) else {
            throw SourceLockError.invalidPin
        }
    }

    private static func randomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    private static func derive(pin: String, salt: Data, iterations: UInt32, keyLength: Int) -> Data {
        var derived = [UInt8](repeating: 0, count: keyLength)
        pin.withCString { passwordPointer in
            _ = salt.withUnsafeBytes { saltPointer -> Int32 in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordPointer, pin.utf8.count,
                    saltPointer.bindMemory(to: UInt8.self).baseAddress, salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    iterations,
                    &derived, derived.count
                )
            }
        }
        return Data(derived)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(SourceLockRecord.self, from: data) else { return }
        record = decoded
    }

    private func save() {
        guard let record, let data = try? JSONEncoder().encode(record) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
