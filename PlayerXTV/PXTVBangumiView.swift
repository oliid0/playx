import SwiftUI

struct PXTVBangumiView: View {
    @EnvironmentObject private var app: PXTVAppState
    @ObservedObject private var coordinator = PXBangumiCoordinator.shared
    @State private var selectedDay: Int?
    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 22)]

    private var day: PXBangumiCalendarDay? {
        if let selectedDay, let found = coordinator.calendar.first(where: { $0.weekday.id == selectedDay }) { return found }
        return coordinator.today ?? coordinator.calendar.first
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("追番").font(PXFont.display(44)).foregroundStyle(PXTheme.textPrimary)
                        Text("Bangumi 每日放送").font(.body).foregroundStyle(PXTheme.textTertiary)
                    }
                    Spacer()
                    if coordinator.isLoggedIn, let profile = coordinator.profile {
                        Text(profile.displayName).font(.body).foregroundStyle(PXTheme.textSecondary)
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(coordinator.calendar) { item in
                            Button(item.weekday.cn) { selectedDay = item.weekday.id }
                                .buttonStyle(.card)
                        }
                    }
                }
                if coordinator.isLoading && coordinator.calendar.isEmpty {
                    PXTVLoadingView(text: "加载 Bangumi 日历")
                } else if let day {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(day.items) { subject in
                            NavigationLink(value: PXTVRoute.bangumi(subject.id)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    PXRemoteImage(url: subject.imageURL, maxPixel: 500)
                                        .frame(width: 180, height: 270)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Text(subject.displayTitle).font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(PXTheme.textPrimary).lineLimit(2)
                                    Text(subject.episodesText ?? "放送中").font(.caption).foregroundStyle(PXTheme.textTertiary)
                                }
                                .frame(width: 180)
                            }
                            .buttonStyle(.card)
                        }
                    }
                } else {
                    PXTVEmptyView(title: "没有日历数据", message: "Bangumi 暂时不可用。", symbol: "calendar")
                }
            }
            .padding(.horizontal, 56)
            .padding(.top, 46)
            .padding(.bottom, 60)
        }
        .task { await coordinator.loadCalendarIfNeeded() }
    }
}
