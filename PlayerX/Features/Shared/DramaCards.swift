import SwiftUI


/// 纯背景封面：按父级给出的尺寸铺满、可模糊。和 `CoverImage` 的区别是
/// 不受海报比例限制，专门给 Hero / 继续观看这类横版背景用。
struct CoverBackdrop: View {
    let drama: Drama
    var blur: CGFloat = 0

    @State private var image: PlatformImage?

    init(drama: Drama, blur: CGFloat = 0) {
        self.drama = drama
        self.blur = blur
        _image = State(initialValue: CoverLoader.cached(for: drama))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.surfaceMuted
                if let image {
                    Image(platformImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .blur(radius: blur)
                        .scaleEffect(blur > 0 ? 1.08 : 1)
                }
            }
        }
        .clipped()
        .task(id: "\(drama.id)#\(drama.cover ?? "")") {
            if image == nil {
                image = try? await CoverLoader.load(for: drama)
            }
        }
        .accessibilityHidden(true)
    }
}

/// 海报卡：2:3 封面 + 压暗渐变 + 集数角标 + 标题/副标题。
/// 所有网格和横排共用，固定宽度传 `width`，自适应网格传 nil。
struct DramaPosterCard: View {
    let drama: Drama
    var width: CGFloat? = nil
    var showsSource: Bool = false
    var titleLineLimit: Int = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            poster
            VStack(alignment: .leading, spacing: 3) {
                Text(drama.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(titleLineLimit)
                    .multilineTextAlignment(.leading)
                if showsSource {
                    SourceBadge(sourceId: drama.source, name: drama.sourceName)
                } else if !drama.cardSubtitle.isEmpty {
                    Text(drama.cardSubtitle)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: width, alignment: .leading)
        .contentShape(Rectangle())
        .appHoverLift()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(drama.title)，\(drama.cardSubtitle)")
    }

    private var poster: some View {
        ZStack(alignment: .topLeading) {
            CoverImage(drama: drama)
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.02), Color.black.opacity(0.22)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack {
                HStack(alignment: .top) {
                    if let episodeText = drama.episodeText {
                        Text(episodeText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .frame(height: 19)
                            .background(.black.opacity(0.46), in: Capsule())
                    }
                    Spacer(minLength: 0)
                    if drama.vip == true {
                        Text("VIP")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color(hex: 0x2B1600))
                            .padding(.horizontal, 5)
                            .frame(height: 19)
                            .background(AppTheme.brandWarm, in: Capsule())
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
        }
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous)
                .strokeBorder(AppTheme.stroke, lineWidth: 0.6)
        }
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

/// 「继续观看」宽卡。没有横版剧照，用封面做模糊背景 + 小海报，避免把竖版海报硬裁成 16:9。
struct ContinueWatchingCard: View {
    let entry: HistoryEntry
    var width: CGFloat = AppTheme.stillWidth

    private var drama: Drama { entry.drama }
    private var imageHeight: CGFloat { width * 9 / 16 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverBackdrop(drama: drama, blur: 2)
                .frame(width: width, height: imageHeight)
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.02), .black.opacity(0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous)
                        .strokeBorder(AppTheme.stroke, lineWidth: 0.6)
                }

            ProgressTrack(
                progress: entry.progress,
                height: 3,
                track: Color.primary.opacity(0.12)
            )
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(drama.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text("\(entry.episodeLabel) · \(AppFormat.remaining(entry.remainingSeconds))")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.top, 10)
        }
        .frame(width: width, alignment: .leading)
        .contentShape(Rectangle())
        .appHoverLift()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("继续观看 \(drama.title)，\(entry.episodeLabel)")
    }
}

/// 首页 Hero。没有 backdrop 字段，用封面模糊铺底 + 右侧竖版海报，文字不压在主视觉上。
struct HomeHeroCard: View {
    let item: HomeHeroItem
    var height: CGFloat = 330

    private var drama: Drama { item.drama }

    var body: some View {
        ZStack {
            CoverBackdrop(drama: drama, blur: 24)
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.34),
                            Color.black.opacity(0.62),
                            Color.black.opacity(0.94)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                }

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 11) {
                    HStack(spacing: 7) {
                        SourceBadge(sourceId: item.sourceId, name: item.sourceName)
                        if let release = drama.releaseText {
                            MetaPill(text: release, tint: AppTheme.textSecondary)
                        }
                    }

                    Text(drama.title)
                        .font(.appDisplay(28))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .shadow(color: .black.opacity(0.4), radius: 8, y: 3)

                    Text(drama.metaLine)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.66))
                        .lineLimit(1)

                    if let description = drama.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.58))
                            .lineLimit(2)
                            .lineSpacing(2)
                    }

                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .black))
                            Text("立即观看")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.onBrand)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .background(AppTheme.brandGradient, in: Capsule())
                        .shadow(color: AppTheme.brand.opacity(0.35), radius: 12, y: 5)

                        HStack(spacing: 4) {
                            Text("详情")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                CoverImage(drama: drama)
                    .frame(width: 102, height: 153)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.8)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8)
        }
        .contentShape(Rectangle())
        .appHoverLift()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("推荐 \(drama.title)")
    }
}

/// 首页站源入口卡。
struct SourceTile: View {
    let descriptor: SourceDescriptor
    var width: CGFloat = AppTheme.stillWidth

    private var style: SourceVisualStyle { SourceVisualStyle.style(for: descriptor.id) }
    private var imageHeight: CGFloat { width * 9 / 16 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                style.gradient
                    .opacity(0.15)
                Image(systemName: style.symbol)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.72))
            }
            .frame(width: width, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous)
                    .strokeBorder(AppTheme.stroke, lineWidth: 0.6)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(descriptor.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(style.tagline)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.top, 10)
        }
        .frame(width: width, alignment: .leading)
        .contentShape(Rectangle())
        .appHoverLift()
        .accessibilityLabel("站源 \(descriptor.displayName)")
    }
}
