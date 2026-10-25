import SwiftUI

struct PXSourceSettingsView: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var settings = PXAppSettings.shared
    @ObservedObject private var lock = SourceLockStore.shared
    @State private var showLock = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PXSettingsSection(title: "已启用站源") {
                    ForEach(SourceRegistry.all) { descriptor in
                        let enabled = app.availableSources.contains { $0.id == descriptor.id }
                        Button {
                            toggle(descriptor.id, enabled: enabled)
                        } label: {
                            HStack(spacing: 11) {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundStyle(enabled ? PXTheme.accent : PXTheme.textTertiary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(descriptor.displayName).font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                                    Text(PXCatalogService.sourceTagline(descriptor.id)).font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                                }
                                Spacer()
                                Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(enabled ? PXTheme.accent : PXTheme.textTertiary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(!descriptor.defaultVisible && !lock.isUnlockedThisLaunch)
                        Divider().overlay(PXTheme.stroke)
                    }
                }
                PXSettingsSection(title: "访问控制") {
                    Button {
                        showLock = true
                    } label: {
                        PXSettingsRow(
                            symbol: lock.hasPassword ? "lock.shield.fill" : "lock.shield",
                            title: "站源密码锁",
                            subtitle: lock.hasPassword ? "已设置，重启后需要重新解锁" : "保护隐藏站源",
                            value: lock.isUnlockedThisLaunch ? "已解锁" : nil,
                            tint: PXTheme.warning
                        )
                    }
                    .buttonStyle(.plain)
                }
                ToggleRow(title: "显示成人内容", subtitle: "部分站源可能返回 R18 条目", isOn: $settings.showAdultContent)
            }
            .padding(20)
        }
        .background(PXPageBackground())
        .navigationTitle("站源")
        .pxInlineNavigationTitle()
        .sheet(isPresented: $showLock) { SourceLockView() }
    }

    private func toggle(_ id: String, enabled: Bool) {
        var ids = app.availableSources.map(\.id)
        if enabled {
            ids.removeAll { $0 == id }
            if ids.isEmpty { ids = [id] }
        } else {
            ids.append(id)
        }
        settings.preferredSourceIDs = ids
    }
}
