import SwiftUI

/// 封面图统一用这个，不要直接 `AsyncImage(url: URL(string: drama.cover))`——见
/// `Core/Media/CoverLoader.swift` 的说明，某些站源的图片 CDN 要校验 Referer，
/// 直接拿 URL 发请求大概率 403。
///
/// 设计上只负责「把给定框填满」：圆角、渐变、角标由调用方（`DramaPosterCard` /
/// `ContinueWatchingCard`）叠加，避免每个页面各裁一个圆角。
struct CoverImage: View {
    let drama: Drama
    var aspectRatio: CGFloat = 2.0 / 3.0
    var showsPlaceholderIcon: Bool = true

    @State private var image: PlatformImage?
    @State private var failed = false

    init(drama: Drama, aspectRatio: CGFloat = 2.0 / 3.0, showsPlaceholderIcon: Bool = true) {
        self.drama = drama
        self.aspectRatio = aspectRatio
        self.showsPlaceholderIcon = showsPlaceholderIcon
        // 内存缓存命中时首帧直接出图，列表来回滚动不会闪灰块。
        _image = State(initialValue: CoverLoader.cached(for: drama))
    }

    var body: some View {
        ZStack {
            placeholder
            if let image {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipped()
        .appMotion(AppTheme.standard, value: image != nil)
        .task(id: "\(drama.id)#\(drama.cover ?? "")") { await load() }
        .accessibilityLabel(drama.title)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.surfaceStrong, AppTheme.surfaceMuted],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if showsPlaceholderIcon {
                Image(systemName: failed ? "photo.badge.exclamationmark" : "photo")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    private func load() async {
        if image != nil { return }
        guard let cover = drama.cover, !cover.isEmpty else {
            failed = true
            return
        }
        do {
            let loaded = try await CoverLoader.load(for: drama)
            guard !Task.isCancelled else { return }
            image = loaded
        } catch {
            guard !Task.isCancelled else { return }
            failed = true
        }
    }
}
