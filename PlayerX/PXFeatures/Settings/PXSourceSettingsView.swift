import SwiftUI

struct PXSourceSettingsView: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var settings = PXAppSettings.shared
    @ObservedObject private var lock = SourceLockStore.shared
    @ObservedObject private var store = PXSourceConfigurationStore.shared
    @State private var editing: PXSourceConfiguration?
    @State private var showLock = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                externalSection
                stationSection
                accessSection
                ToggleRow(title: "显示成人内容", subtitle: "部分站源可能返回 R18 条目", isOn: $settings.showAdultContent)
            }
            .padding(20)
        }
        .background(PXPageBackground())
        .navigationTitle("媒体源")
        .pxInlineNavigationTitle()
        .sheet(item: $editing) { configuration in
            PXSourceEditorView(configuration: configuration)
        }
        .sheet(isPresented: $showLock) { SourceLockView() }
    }

    private var externalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("外部媒体源").font(PXFont.section(16)).foregroundStyle(PXTheme.textPrimary)
                Spacer()
                Menu {
                    ForEach([PXSourceKind.jellyfin, .emby, .webdav, .nas, .alist, .maccms]) { kind in
                        Button {
                            editing = PXSourceConfiguration(kind: kind, name: kind.title)
                        } label: {
                            Label(kind.title, systemImage: kind.symbol)
                        }
                    }
                } label: {
                    Label("添加", systemImage: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(PXTheme.accent)
                }
            }
            if store.configurations.isEmpty {
                Text("还没有外部源。可添加 Jellyfin / Emby、WebDAV、NAS、Alist 或 MacCMS。")
                    .font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
                    .pxFlatCard()
            } else {
                ForEach(store.configurations) { configuration in
                    externalRow(configuration)
                }
            }
        }
    }

    private func externalRow(_ configuration: PXSourceConfiguration) -> some View {
        HStack(spacing: 11) {
            Image(systemName: configuration.kind.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(configuration.enabled ? PXTheme.accent : PXTheme.textTertiary)
                .frame(width: 28)
            Button {
                editing = configuration
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(configuration.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PXTheme.textPrimary)
                    Text(configuration.kind.title + ((configuration.normalizedBaseURL?.host).map { " · \($0)" } ?? ""))
                        .font(.system(size: 9))
                        .foregroundStyle(PXTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            Toggle("", isOn: Binding(
                get: { configuration.enabled },
                set: { store.setEnabled($0, id: configuration.id) }
            ))
            .labelsHidden()
            .tint(PXTheme.accent)
            Menu {
                Button("编辑") { editing = configuration }
                Button("删除", role: .destructive) { store.delete(id: configuration.id) }
            } label: {
                Image(systemName: "ellipsis").foregroundStyle(PXTheme.textTertiary)
            }
        }
        .padding(10)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 11))
    }

    private var stationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("内置站源").font(PXFont.section(16)).foregroundStyle(PXTheme.textPrimary)
            PXSettingsSection(title: nil) {
                ForEach(SourceRegistry.stationSources) { descriptor in
                    HStack(spacing: 11) {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundStyle(isStationEnabled(descriptor) ? PXTheme.accent : PXTheme.textTertiary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(descriptor.displayName).font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                            Text(PXCatalogService.sourceTagline(descriptor.id))
                                .font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { isStationEnabled(descriptor) },
                            set: { toggleStation(descriptor.id, enabled: $0) }
                        ))
                        .labelsHidden()
                        .tint(PXTheme.accent)
                        .disabled(!descriptor.defaultVisible && !lock.isUnlockedThisLaunch)
                    }
                    .padding(.vertical, 8)
                    if descriptor.id != SourceRegistry.stationSources.last?.id {
                        Divider().overlay(PXTheme.stroke)
                    }
                }
            }
        }
    }

    private var accessSection: some View {
        PXSettingsSection(title: "访问控制") {
            Button { showLock = true } label: {
                PXSettingsRow(
                    symbol: lock.hasPassword ? "lock.shield.fill" : "lock.shield",
                    title: "站源密码锁",
                    subtitle: lock.hasPassword ? "隐藏站源需解锁" : "保护隐藏站源",
                    value: lock.isUnlockedThisLaunch ? "已解锁" : nil,
                    tint: PXTheme.warning
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func isStationEnabled(_ descriptor: SourceDescriptor) -> Bool {
        let preferred = settings.preferredSourceIDs
        if preferred.isEmpty { return descriptor.defaultVisible || lock.isUnlockedThisLaunch }
        return preferred.contains(descriptor.id)
    }

    private func toggleStation(_ id: String, enabled: Bool) {
        var ids = SourceRegistry.stationSources
            .filter { isStationEnabled($0) }
            .map(\.id)
        if enabled {
            if !ids.contains(id) { ids.append(id) }
        } else {
            ids.removeAll { $0 == id }
        }
        settings.preferredSourceIDs = ids
    }
}
