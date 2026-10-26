import SwiftUI

struct PXTVSourceDetailView: View {
    @EnvironmentObject private var app: PXTVAppState
    let sourceID: String
    let drama: Drama
    @State private var detail: DetailResult?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var playingID: String?

    private var provider: ContentProvider? {
        PXExternalMediaProviderLookup.provider(for: sourceID)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                hero
                if let detail {
                    if let warning = detail.warning, !warning.isEmpty {
                        Text(warning).font(.caption).foregroundStyle(PXTheme.warning)
                    }
                    chapterSection(detail.chapters)
                } else if isLoading {
                    PXTVLoadingView(text: "加载详情")
                } else {
                    PXTVErrorState(title: "详情加载失败", message: errorMessage ?? "未知错误") {
                        Task { await load() }
                    }
                }
            }
            .padding(.horizontal, 56)
            .padding(.top, 40)
            .padding(.bottom, 60)
        }
        .task { await load() }
    }

    private var hero: some View {
        HStack(alignment: .bottom, spacing: 24) {
            PXRemoteImage(url: URL(string: drama.cover ?? ""), maxPixel: 600)
                .frame(width: 190, height: 285)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PXTheme.stroke))
            VStack(alignment: .leading, spacing: 10) {
                Text(drama.title).font(PXFont.display(42)).foregroundStyle(PXTheme.textPrimary).lineLimit(2)
                HStack(spacing: 8) {
                    PXTag(text: drama.pxKind.title, tint: PXTheme.accent)
                    if let year = drama.pxYear { PXTag(text: String(year)) }
                    if let count = drama.pxEpisodeCount { PXTag(text: "\(count) 集") }
                }
                if let description = drama.description, !description.isEmpty {
                    Text(description)
                        .font(.body).foregroundStyle(PXTheme.textSecondary)
                        .lineSpacing(4).lineLimit(4)
                }
                if let first = detail?.chapters.first, let provider {
                    Button {
                        play(first, provider: provider)
                    } label: {
                        Label("播放", systemImage: "play.fill")
                    }
                    .buttonStyle(PXTVPrimaryButtonStyle())
                }
            }
            Spacer()
        }
    }

    private func chapterSection(_ chapters: [Chapter]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选集").font(PXFont.title(26)).foregroundStyle(PXTheme.textPrimary)
            if chapters.isEmpty {
                Text("没有可播放的剧集").font(.body).foregroundStyle(PXTheme.textTertiary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
                    ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                        Button {
                            if let provider { play(chapter, provider: provider) }
                        } label: {
                            HStack(spacing: 12) {
                                Text(String(format: "%02d", index + 1))
                                    .font(PXFont.mono(14)).foregroundStyle(PXTheme.accent).frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(chapter.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
                                    if let size = chapter.mediaSize { Text(PXFormat.byteCount(size)).font(.caption2).foregroundStyle(PXTheme.textTertiary) }
                                }
                                Spacer()
                                if playingID == chapter.id { ProgressView().controlSize(.small) }
                                else { Image(systemName: "play.circle").foregroundStyle(PXTheme.textTertiary) }
                            }
                            .padding(12)
                            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.card)
                    }
                }
            }
        }
    }

    private func play(_ chapter: Chapter, provider: ContentProvider) {
        playingID = chapter.id
        Task {
            await app.play(chapter: chapter, provider: provider, drama: drama)
            playingID = nil
        }
    }

    private func load() async {
        guard let provider else {
            errorMessage = "媒体源不存在"
            isLoading = false
            return
        }
        isLoading = true
        do {
            detail = try await provider.detail(for: drama)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

enum PXExternalMediaProviderLookup {
    static func provider(for sourceID: String) -> ContentProvider? {
        PXExternalSourceRegistry.descriptors.first { $0.id == sourceID }?.provider
    }
}
