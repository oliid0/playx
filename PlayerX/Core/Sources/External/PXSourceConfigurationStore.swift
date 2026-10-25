import Foundation
import Combine

@MainActor
final class PXSourceConfigurationStore: ObservableObject {
    static let shared = PXSourceConfigurationStore()

    @Published private(set) var configurations: [PXSourceConfiguration] = []

    private let defaultsKey = "playerx.sources.external.v1"

    private init() {
        load()
        refreshRegistry()
    }

    var enabledConfigurations: [PXSourceConfiguration] {
        configurations.filter(\.enabled)
    }

    func configuration(id: String) -> PXSourceConfiguration? {
        configurations.first { $0.id == id }
    }

    @discardableResult
    func upsert(_ configuration: PXSourceConfiguration) -> PXSourceConfiguration {
        var value = configuration
        value.touch()
        if let index = configurations.firstIndex(where: { $0.id == value.id }) {
            configurations[index] = value
        } else {
            configurations.append(value)
        }
        sort()
        persist()
        refreshRegistry()
        return value
    }

    func delete(id: String) {
        configurations.removeAll { $0.id == id }
        persist()
        refreshRegistry()
    }

    func setEnabled(_ enabled: Bool, id: String) {
        guard let index = configurations.firstIndex(where: { $0.id == id }) else { return }
        configurations[index].enabled = enabled
        configurations[index].touch()
        persist()
        refreshRegistry()
    }

    func refreshRegistry() {
        PXExternalSourceRegistry.reload(configurations)
    }

    func reload() {
        load()
        refreshRegistry()
    }

    private func sort() {
        configurations.sort {
            if $0.kind == $1.kind { return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
            return $0.kind.rawValue < $1.kind.rawValue
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([PXSourceConfiguration].self, from: data) else {
            configurations = []
            return
        }
        configurations = decoded
        sort()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(configurations) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
