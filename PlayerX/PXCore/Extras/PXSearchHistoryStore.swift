import Foundation
import Combine
@MainActor
final class PXSearchHistoryStore: ObservableObject {
    static let shared = PXSearchHistoryStore()
    @Published private(set) var terms: [String] = []
    private let key = "playerx.search.history.v2"
    private init() { terms = UserDefaults.standard.stringArray(forKey: key) ?? [] }
    func add(_ term: String) {
        let value = term.pxTrimmed
        guard !value.isEmpty else { return }
        terms.removeAll { $0.caseInsensitiveCompare(value) == .orderedSame }
        terms.insert(value, at: 0)
        terms = Array(terms.prefix(10))
        UserDefaults.standard.set(terms, forKey: key)
    }
    func remove(_ term: String) {
        terms.removeAll { $0 == term }
        UserDefaults.standard.set(terms, forKey: key)
    }
    func clear() { terms = []; UserDefaults.standard.removeObject(forKey: key) }
}
