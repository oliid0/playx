import SwiftUI

struct PXSourcePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: PXAppState
    @State private var selected: Set<String> = []
    @State private var showingLock = false
    @State private var showingExternal = false

    private var all: [SourceDescriptor] { SourceRegistry.stationSources }
    private var visible: Set<String> {
        Set(app.catalog.visibleSources.filter { !$0.isExternal }.map(\.id))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(all) { descriptor in
                        Button {
                            toggle(descriptor.id)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(PXTheme.surface)
                                    Image(systemName: "play.rectangle.fill")
                                        .foregroundStyle(PXTheme.accent)
                                }
                                .frame(width: 38, height: 38)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(descriptor.displayName)
                                        .foregroundStyle(PXTheme.textPrimary)
                                    Text(PXCatalogService.sourceTagline(descriptor.id))
                                        .font(.system(size: 10))
                                        .foregroundStyle(PXTheme.textTertiary)
                                }
                                Spacer()
                                Image(systemName: selected.contains(descriptor.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected.contains(descriptor.id) ? PXTheme.accent : PXTheme.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!descriptor.defaultVisible && !SourceLockStore.shared.isUnlockedThisLaunch)
                    }
                } header: {
                    Text("启用站源")
                } footer: {
                    Text("站源是内容库；首页与片库会聚合所有启用源。外部媒体源在“设置 → 媒体源”中添加。")
                }
                Section {
                    Button {
                        showingExternal = true
                    } label: {
                        Label("外部媒体源（Emby / Jellyfin / WebDAV / MacCMS）", systemImage: "externaldrive.connected.to.line.below")
                    }
                    Button {
                        showingLock = true
                    } label: {
                        Label("站源密码锁", systemImage: "lock.shield")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(PXPageBackground())
            .navigationTitle("内容源")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        app.settings.preferredSourceIDs = Array(selected)
                        dismiss()
                    }
                }
            }
            .onAppear {
                selected = visible
            }
            .sheet(isPresented: $showingLock) {
                SourceLockView()
            }
            .sheet(isPresented: $showingExternal) {
                NavigationStack { PXSourceSettingsView() }
                    .environmentObject(app)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func toggle(_ id: String) {
        if selected.contains(id) {
            guard selected.count > 1 else { return }
            selected.remove(id)
        } else {
            selected.insert(id)
        }
    }
}
