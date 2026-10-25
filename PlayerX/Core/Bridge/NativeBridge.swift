import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// 发给 native/bridge 的 DuanjuRequest 的统一请求信封。
/// 字段名直接对应 Go 侧 `nativeInput` 的 json tag（驼峰一致，不用额外 CodingKeys）。
struct NativeRequest: Encodable {
    var action: String
    var directory: String?
    var source: String?
    var page: Int?
    var query: String?
    var category: String?
    var drama: Drama?
    var chapter: Chapter?
    var index: Int?
    var quality: Int?
    var session: String?
    var sequence: Int64?
    var force: Bool?
    // 下载队列
    var jobId: String?
    var command: String?
    var entries: [DownloadEntry]?
    // 弹幕：playbackSession 来自 resolve 返回的 PlaybackPlan.session，
    // startMs/durationMs 是本次要拉的时间窗口（毫秒）
    var playbackSession: String?
    var startMs: Int64?
    var durationMs: Int64?
}

enum NativeError: Error, LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "原生核心返回了无法解析的数据"
        case .server(let message): return message
        }
    }
}

/// 对 native/bridge 导出的 `DuanjuRequest`/`DuanjuFree` 的 Swift 封装。
/// 调用是同步阻塞的 C 函数（Go 侧内部做网络请求），丢到并发队列跑，避免卡 UI；
/// 必须是并发（不能是串行）——Go 核心内部本来就是按并发请求设计的（`nativeDispatch`/各处
/// `engine.mu` 都是靠锁保护状态，不是假设单线程调用；Dart 版本来就会同时发出好几个请求，
/// 比如列表里同时拉一堆封面）。串行队列会把所有请求排成一条队，封面瀑布流会卡成一张一张蹦出来。
/// 没有超时/取消机制——Go 核心本身也不支持中途取消一次 DuanjuRequest，这点和 Dart 版一致
/// （Dart 侧靠 `cancelRead`/`session` 在协议层模拟取消，不是真中断 FFI 调用）。
enum NativeBridge {
    private static let queue = DispatchQueue(label: "com.oliid0.playerx.native", qos: .userInitiated, attributes: .concurrent)
    private static let encoder: JSONEncoder = JSONEncoder()
    private static let decoder: JSONDecoder = JSONDecoder()

    /// 调用一次原生核心，返回信封里 `data` 字段解码成 T 的结果。
    ///
    /// Go 核心要求先发一次 `action:"initialize"`（带沙盒内可写目录路径）引擎才会创建，
    /// 在那之前任何别的 action 都会收到"应用核心尚未就绪"——这里统一兜底，调用方不用操心。
    static func call<T: Decodable>(_ request: NativeRequest) async throws -> T {
        if request.action != "initialize" {
            await AppBootstrap.shared.ensureInitialized()
        }
        let payload = try encoder.encode(request)
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let data = try invoke(payload)
                    let value = try decoder.decode(T.self, from: data)
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 实际调用 C 符号，返回信封里 `data` 字段重新序列化出的 JSON Data。
    private static func invoke(_ payload: Data) throws -> Data {
        guard let inputString = String(data: payload, encoding: .utf8) else {
            throw NativeError.invalidResponse
        }
        // DuanjuRequest 签名是 `char* DuanjuRequest(char* input)`：Go 侧用 C.GoString
        // 立即拷走内容，不持有也不释放这块内存，输入缓冲区由调用方（这里）自己 free。
        guard let inputPointer = strdup(inputString) else {
            throw NativeError.invalidResponse
        }
        defer { free(inputPointer) }
        guard let outputPointer = DuanjuRequest(inputPointer) else {
            throw NativeError.invalidResponse
        }
        defer { DuanjuFree(outputPointer) }
        let outputString = String(cString: outputPointer)
        guard let outputData = outputString.data(using: .utf8),
              let envelope = try JSONSerialization.jsonObject(with: outputData) as? [String: Any] else {
            throw NativeError.invalidResponse
        }
        let ok = envelope["ok"] as? Bool ?? false
        guard ok else {
            throw NativeError.server(envelope["error"] as? String ?? "原生核心返回未知错误")
        }
        let value = envelope["data"] ?? NSNull()
        return try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
    }
}

/// `resolve` 请求里的 `sequence`：每次发起新播放递增，Go 侧用来识别并取消上一次还没返回的解析
/// （见 `nativeBeginPlayback`），纯粹是个单调计数器，不需要持久化。
actor PlaybackSequence {
    static let shared = PlaybackSequence()
    private var value: Int64 = 0
    func next() -> Int64 {
        value += 1
        return value
    }
}

/// 负责发那一次性的 `initialize`。用 actor 串行化：并发涌入的第一批请求只会真正发一次，
/// 其余的等同一个 in-flight task 完。目录给沙盒内的 Documents（Go 侧会自己 `MkdirAll`）。
actor AppBootstrap {
    static let shared = AppBootstrap()

    private struct InitializeResponse: Decodable {
        let version: String
        let standalone: Bool
        let allSources: Bool
    }

    private var inFlight: Task<Void, Never>?

    func ensureInitialized() async {
        if let inFlight {
            await inFlight.value
            return
        }
        let task = Task {
            let directory = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("PlayerXCore", isDirectory: true)
                .path
            do {
                let request = NativeRequest(action: "initialize", directory: directory)
                let response: InitializeResponse = try await NativeBridge.call(request)
                print("[PlayerX] native core ready: version=\(response.version) allSources=\(response.allSources)")
            } catch {
                print("[PlayerX] native core initialize failed: \(error.localizedDescription)")
            }
        }
        inFlight = task
        await task.value
    }
}
