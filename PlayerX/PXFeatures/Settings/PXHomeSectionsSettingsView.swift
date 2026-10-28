import SwiftUI
import PlayXUI

struct PXHomeSectionsSettingsView: View {
    @AppStorage(PXHomeSectionPreference.storageKey) private var hiddenRaw = ""

    private var hidden: Set<PXHomeSection> { PXHomeSectionPreference.hidden(from: hiddenRaw) }

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("首页栏目") {
                ForEach(Array(PXHomeSection.allCases.enumerated()), id: \.element.id) { index, section in
                    if index > 0 { SettingsGlassDivider() }
                    Toggle(isOn: Binding(
                        get: { !hidden.contains(section) },
                        set: { visible in
                            var value = hidden
                            if visible { value.remove(section) } else { value.insert(section) }
                            hiddenRaw = PXHomeSectionPreference.raw(from: value)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title)
                            Text(section.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            SettingsGlassSection("说明") {
                SettingsNote("关闭的栏目只会从首页隐藏，随时可以重新打开。全部关闭时首页显示空态。")
            }
        }
        .navigationTitle("首页栏目")
        .pxInlineNavigationTitle()
    }
}
