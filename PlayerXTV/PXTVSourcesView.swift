import SwiftUI

struct PXTVSourcesView: View {
    @EnvironmentObject private var app: PXTVAppState
    @ObservedObject private var store = PXSourceConfigurationStore.shared
    @State private var editing: PXSourceConfiguration?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("媒体源").font(PXFont.display(42)).foregroundStyle(PXTheme.textPrimary)
                        Text("Jellyfin / Emby / WebDAV / NAS / Alist / MacCMS").font(.body).foregroundStyle(PXTheme.textTertiary)
                    }
                    Spacer()
                    Menu {
                        ForEach([PXSourceKind.jellyfin, .emby, .webdav, .nas, .alist, .maccms]) { kind in
                            Button(kind.title) {
                                editing = PXSourceConfiguration(kind: kind, name: kind.title)
                            }
                        }
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                    .buttonStyle(PXTVPrimaryButtonStyle())
                }

                if store.configurations.isEmpty {
                    PXTVEmptyView(title: "还没有外部媒体源", message: "添加 Jellyfin / Emby、WebDAV、NAS、Alist 或 MacCMS。", symbol: "externaldrive.badge.plus")
                } else {
                    ForEach(store.configurations) { configuration in
                        HStack(spacing: 18) {
                            Image(systemName: configuration.kind.symbol)
                                .font(.system(size: 24, weight: .semibold)).foregroundStyle(PXTheme.accent).frame(width: 38)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(configuration.displayName).font(.title3.weight(.semibold)).foregroundStyle(PXTheme.textPrimary)
                                Text(configuration.kind.title + " · " + (configuration.normalizedBaseURL?.host ?? ""))
                                    .font(.caption).foregroundStyle(PXTheme.textTertiary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { configuration.enabled },
                                set: { store.setEnabled($0, id: configuration.id) }
                            ))
                            .labelsHidden()
                            .tint(PXTheme.accent)
                            Button("编辑") { editing = configuration }
                                .buttonStyle(.card)
                            if configuration.isConfigured, configuration.enabled {
                                NavigationLink(value: PXTVRoute.sourceLibrary(configuration.id)) {
                                    Text("打开")
                                }
                                .buttonStyle(.card)
                            }
                            Button(role: .destructive) {
                                store.delete(id: configuration.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.card)
                        }
                        .padding(14)
                        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 56)
            .padding(.top, 46)
            .padding(.bottom, 60)
        }
        .sheet(item: $editing) { configuration in
            PXSourceEditorView(configuration: configuration)
        }
        .onAppear { app.refreshSources() }
    }
}
