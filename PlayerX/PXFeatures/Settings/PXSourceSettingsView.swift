import SwiftUI

struct PXSourceSettingsView: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var settings = PXAppSettings.shared
    @ObservedObject private var lock = SourceLockStore.shared
    @ObservedObject private var store = PXSourceConfigurationStore.shared
    @State private var editing: PXSourceConfiguration?
    @State private var showLock = false

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("外部媒体源") {
                if store.configurations.isEmpty {
                    SettingsNote("还没有外部源。可添加 Jellyfin / Emby、WebDAV、NAS、Alist 或 MacCMS。")
                } else {
                    ForEach(Array(store.configurations.enumerated()), id: \.element.id) { index, configuration in
                        if index > 0 { SettingsGlassDivider() }
                        externalRow(configuration)
                    }
                }
                SettingsGlassDivider()
                Menu {
                    ForEach([PXSourceKind.jellyfin, .emby, .webdav, .nas, .alist, .maccms]) { kind in
                        Button {
                            editing = PXSourceConfiguration(kind: kind, name: kind.title)
                        } label: {
                            Label(kind.title, systemImage: kind.symbol)
                        }
                    }
                } label: {
                    HStack(spacing: SettingsMetrics.iconLabelSpacing) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: SettingsMetrics.iconGlyphSize))
                            .frame(width: SettingsMetrics.iconColumnWidth)
                        Text("添加媒体源")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            SettingsGlassSection("内置站源") {
                ForEach(Array(SourceRegistry.stationSources.enumerated()), id: \.element.id) { index, descriptor in
                    if index > 0 { SettingsGlassDivider() }
                    HStack(spacing: SettingsMetrics.iconLabelSpacing) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: SettingsMetrics.iconGlyphSize))
                            .frame(width: SettingsMetrics.iconColumnWidth)
                            .foregroundStyle(.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(descriptor.displayName)
                            Text(PXCatalogService.sourceTagline(descriptor.id))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { isStationEnabled(descriptor) },
                            set: { toggleStation(descriptor.id, enabled: $0) }
                        ))
                        .labelsHidden()
                        .disabled(!descriptor.defaultVisible && !lock.isUnlockedThisLaunch)
                    }
                    .settingsRow()
                }
            }

            SettingsGlassSection("访问控制") {
                SettingsActionRow(lock.hasPassword ? "站源密码锁（已设置）" : "设置站源密码锁", systemImage: "lock.shield") {
                    showLock = true
                }
                SettingsGlassDivider()
                Toggle("显示成人内容", isOn: $settings.showAdultContent)
            }
        }
        .navigationTitle("媒体服务器与站源")
        .pxInlineNavigationTitle()
        .sheet(item: $editing) { configuration in
            PXSourceEditorView(configuration: configuration)
        }
        .sheet(isPresented: $showLock) { SourceLockView() }
    }

    private func externalRow(_ configuration: PXSourceConfiguration) -> some View {
        HStack(spacing: SettingsMetrics.iconLabelSpacing) {
            Image(systemName: configuration.kind.symbol)
                .font(.system(size: SettingsMetrics.iconGlyphSize))
                .frame(width: SettingsMetrics.iconColumnWidth)
                .foregroundStyle(configuration.enabled ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
            VStack(alignment: .leading, spacing: 2) {
                Text(configuration.displayName)
                Text(configuration.kind.title + ((configuration.normalizedBaseURL?.host).map { " · \($0)" } ?? ""))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { configuration.enabled },
                set: { store.setEnabled($0, id: configuration.id) }
            ))
            .labelsHidden()
            Menu {
                Button("编辑") { editing = configuration }
                Button("删除", role: .destructive) { store.delete(id: configuration.id) }
            } label: {
                Image(systemName: "ellipsis").foregroundStyle(.secondary)
            }
            .fixedSize()
        }
        .settingsRow()
    }

    private func isStationEnabled(_ descriptor: SourceDescriptor) -> Bool {
        let preferred = settings.preferredSourceIDs
        if preferred.isEmpty { return descriptor.defaultVisible || lock.isUnlockedThisLaunch }
        return preferred.contains(descriptor.id)
    }

    private func toggleStation(_ id: String, enabled: Bool) {
        var ids = SourceRegistry.stationSources.filter { isStationEnabled($0) }.map(\.id)
        if enabled { if !ids.contains(id) { ids.append(id) } }
        else { ids.removeAll { $0 == id } }
        settings.preferredSourceIDs = ids
    }
}
