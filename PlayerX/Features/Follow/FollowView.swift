import SwiftUI

/// 追剧 Tab：把 FollowStore（手动想看/已看）和 HistoryStore（自动播放进度）合并。
/// 「在看」不需要手动点：有播放记录且没被标成已看就算在看；手动「已看完」优先。
private struct FollowRow: Identifiable {
    let drama: Drama
    let status: FollowStatus
    let entry: HistoryEntry?
    let updatedAt: Date
    var id: String { drama.id }
}

private enum FollowFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case watching = "在看"
    case planned = "想看"
    case watched = "已看"
    var id: String { rawValue }
}

struct FollowView: View {
    @ObservedObject private var history = HistoryStore.shared
    @ObservedObject private var follow = FollowStore.shared
    @State private var filter: FollowFilter = .all

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    summary
                    filterBar
                    if filteredRows.isEmpty {
                        EmptyStateView(
                            systemImage: "heart.text.square",
                            title: "还没有追剧记录",
                            message: "在详情页点收藏，或直接播放一集，这里就会自动出现观看进度。"
                        )
                        .padding(.top, 24)
                    } else {
                        ForEach(filteredRows) { row in
                            if let descriptor = SourceRegistry.descriptor(for: row.drama.source) {
                                NavigationLink {
                                    DetailView(provider: descriptor.provider, drama: row.drama)
                                } label: {
                                    FollowCard(row: row)
                                }
                                .buttonStyle(AppPressStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        follow.remove(dramaId: row.drama.id)
                                        history.remove(dramaId: row.drama.id)
                                    } label: {
                                        Label("从追剧移除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.contentPadding)
                .padding(.top, 8)
                .padding(.bottom, 28)
                .frame(maxWidth: 980, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("追剧")
        .appLargeNavigationTitle()
        .appTransparentNavigationChrome()
    }

    private var summary: some View {
        HStack(spacing: 10) {
            summaryTile(value: rows.filter { $0.status == .watching }.count, title: "在看", tint: AppTheme.brand)
            summaryTile(value: rows.filter { $0.status == .planned }.count, title: "想看", tint: AppTheme.lilac)
            summaryTile(value: rows.filter { $0.status == .watched }.count, title: "已看", tint: AppTheme.mint)
        }
    }

    private func summaryTile(value: Int, title: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(value)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .solidCard()
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(FollowFilter.allCases) { item in
                let selected = filter == item
                Button {
                    withAnimation(AppTheme.quick) { filter = item }
                } label: {
                    HStack(spacing: 5) {
                        Text(item.rawValue)
                        Text("\(count(for: item))")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(selected ? AppTheme.onBrand.opacity(0.64) : AppTheme.textTertiary)
                    }
                    .font(.system(size: 12, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? AppTheme.onBrand : AppTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background {
                        Capsule().fill(selected ? AnyShapeStyle(AppTheme.brandGradient) : AnyShapeStyle(AppTheme.surfaceMuted))
                    }
                    .overlay {
                        Capsule().strokeBorder(selected ? Color.clear : AppTheme.stroke, lineWidth: 0.7)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var rows: [FollowRow] {
        var byId: [String: FollowRow] = [:]
        for entry in follow.entries {
            byId[entry.drama.id] = FollowRow(
                drama: entry.drama,
                status: entry.status,
                entry: history.entry(forDramaId: entry.drama.id),
                updatedAt: entry.updatedAt
            )
        }

        for entry in history.entries {
            let ratio = entry.duration > 0 ? entry.position / entry.duration : 0
            let episodes = entry.drama.episodes ?? 0
            let isLastEpisode = episodes > 0 && entry.episodeIndex >= episodes
            let autoStatus: FollowStatus = (ratio >= 0.95 && isLastEpisode) ? .watched : .watching
            if let existing = byId[entry.drama.id] {
                let status: FollowStatus = existing.status == .watched ? .watched : autoStatus
                byId[entry.drama.id] = FollowRow(
                    drama: entry.drama,
                    status: status,
                    entry: entry,
                    updatedAt: max(existing.updatedAt, entry.updatedAt)
                )
            } else {
                byId[entry.drama.id] = FollowRow(
                    drama: entry.drama,
                    status: autoStatus,
                    entry: entry,
                    updatedAt: entry.updatedAt
                )
            }
        }

        return byId.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var filteredRows: [FollowRow] {
        switch filter {
        case .all: return rows
        case .watching: return rows.filter { $0.status == .watching }
        case .planned: return rows.filter { $0.status == .planned }
        case .watched: return rows.filter { $0.status == .watched }
        }
    }

    private func count(for filter: FollowFilter) -> Int {
        switch filter {
        case .all: return rows.count
        case .watching: return rows.filter { $0.status == .watching }.count
        case .planned: return rows.filter { $0.status == .planned }.count
        case .watched: return rows.filter { $0.status == .watched }.count
        }
    }
}

private struct FollowCard: View {
    let row: FollowRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CoverImage(drama: row.drama)
                .frame(width: 64, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(row.drama.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    statusPill
                }

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)

                if let entry = row.entry, entry.progress > 0.01 {
                    VStack(alignment: .leading, spacing: 5) {
                        ProgressTrack(progress: entry.progress, height: 3)
                        Text("已看 \(Int(entry.progress * 100))% · \(AppFormat.remaining(entry.remainingSeconds))")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)

                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8, weight: .black))
                    Text(row.entry == nil ? "开始观看" : "继续观看")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundStyle(AppTheme.onBrand)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(AppTheme.brandGradient, in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .solidCard()
    }

    private var subtitle: String {
        var parts: [String] = []
        if let entry = row.entry {
            parts.append(entry.episodeLabel)
        } else if let episodes = row.drama.episodeText {
            parts.append(episodes)
        }
        parts.append(row.drama.sourceName)
        if let heat = AppFormat.heat(row.drama.heat) {
            parts.append("热度 \(heat)")
        }
        return parts.joined(separator: " · ")
    }

    private var statusPill: some View {
        Text(statusText)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 7)
            .frame(height: 20)
            .background(statusColor.opacity(0.13), in: Capsule())
            .overlay(Capsule().strokeBorder(statusColor.opacity(0.28), lineWidth: 0.6))
    }

    private var statusText: String {
        switch row.status {
        case .planned: return "想看"
        case .watching: return "在看"
        case .watched: return "已看"
        }
    }

    private var statusColor: Color {
        switch row.status {
        case .planned: return AppTheme.lilac
        case .watching: return AppTheme.brand
        case .watched: return AppTheme.mint
        }
    }
}
