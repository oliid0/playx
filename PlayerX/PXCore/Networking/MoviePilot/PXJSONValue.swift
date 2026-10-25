import Foundation

/// MoviePilot 的若干接口要求把搜索结果原样回传（下载 / 订阅），所以不能只
/// 映射成扁平 struct。这里保留一份无损 JSON，同时提供常用的读取辅助。
enum PXJSONValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: PXJSONValue])
    case array([PXJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let value = try? container.decode(Bool.self) { self = .bool(value); return }
        if let value = try? container.decode(Double.self) { self = .number(value); return }
        if let value = try? container.decode(String.self) { self = .string(value); return }
        if let value = try? container.decode([String: PXJSONValue].self) { self = .object(value); return }
        if let value = try? container.decode([PXJSONValue].self) { self = .array(value); return }
        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let value): value
        case .number(let value): value.rounded() == value ? String(Int(value)) : String(value)
        case .bool(let value): String(value)
        default: nil
        }
    }

    var intValue: Int? {
        switch self {
        case .number(let value): Int(value)
        case .string(let value): Int(value)
        default: nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case .number(let value): value
        case .string(let value): Double(value)
        default: nil
        }
    }

    var boolValue: Bool? {
        switch self {
        case .bool(let value): value
        case .number(let value): value != 0
        case .string(let value): value == "true" || value == "1"
        default: nil
        }
    }

    var objectValue: [String: PXJSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    static func convert(_ any: Any) -> PXJSONValue {
        switch any {
        case let value as String: .string(value)
        case let value as Bool: .bool(value)
        case let value as Int: .number(Double(value))
        case let value as Double: .number(value)
        case let value as NSNumber: .number(value.doubleValue)
        case let value as [String: Any]:
            .object(value.mapValues(convert))
        case let value as [Any]: .array(value.map(convert))
        default: .null
        }
    }
}
