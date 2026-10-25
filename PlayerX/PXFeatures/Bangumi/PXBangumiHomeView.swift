import SwiftUI

struct PXBangumiHomeView: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var coordinator = PXBangumiCoordinator.shared
    @State private var selectedWeekday: Int?
    @State private var showLogin = false
    @State private var showSearch = false

    private var days: [PXBangumiCalendarDay] { coordinator.calendar }
    private var selectedDay: PXBangumiCalendarDay? {
        if let selectedWeekday, let day = days.first(where: { $0.weekday.id == selectedWeekday }) {
            return day
        }
        return coordinator.today ?? days.first
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    header(width: proxy.size.width)
                    if !coordinator.isLoggedIn {
                        loginCard
                            .padding(.horizontal, PXTheme.contentPadding)
                            .padding(.top, 14)
                    }
                    if let error = coordinator.errorMessage {
                        PXErrorBanner(message: error) {
                            Task { await coordinator.loadCalendar() }
                        }
                        .padding(.horizontal, PXTheme.contentPadding)
                        .padding(.top, 12)
                    }
                    weekdayBar(width: proxy.size.width)
                    calendarGrid(width: proxy.size.width)
                    collectionsSection(width: proxy.size.width)
                }
                .padding(.bottom, 34)
            }
            .refreshable { await coordinator.loadCalendar() }
        }
        .background(PXPageBackground())
        .navigationTitle("追番")
        .pxHiddenNavigationBar()
        .task {
            await coordinator.loadCalendarIfNeeded()
            await coordinator.restoreSession()
        }
        .sheet(isPresented: $showLogin) {
            PXBangumiLoginView()
        }
        .sheet(isPresented: $showSearch) {
            PXBangumiSearchView()
        }
    }

    private func header(width: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("追番")
                    .font(PXFont.display(32))
                    .foregroundStyle(PXTheme.textPrimary)
                Text("Bangumi 每日放送 / 收藏与进度")
                    .font(PXFont.caption(11))
                    .foregroundStyle(PXTheme.textTertiary)
            }
            Spacer()
            Button { showSearch = true } label: { Image(systemName: "magnifyingglass") }
                .buttonStyle(PXIconButtonStyle(size: 38))
            Button {
                if coordinator.isLoggedIn { showLogin = true } else { showLogin = true }
            } label: {
                PXRemoteImage(url: coordinator.profile?.avatar?.best, maxPixel: 120)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(PXTheme.stroke, lineWidth: 0.8))
                    .overlay {
                        if coordinator.profile == nil {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 17))
                                .foregroundStyle(PXTheme.textSecondary)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PXTheme.padding(for: width))
        .padding(.top, PXPlatform.isMac ? 20 : 8)
    }

    private var loginCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 20))
                .foregroundStyle(PXTheme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("登录 Bangumi")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PXTheme.textPrimary)
                Text("同步想看 / 在看 / 看过与单集进度")
                    .font(.system(size: 10))
                    .foregroundStyle(PXTheme.textTertiary)
            }
            Spacer()
            Button("登录") { showLogin = true }
                .buttonStyle(PXSecondaryButtonStyle(compact: true))
        }
        .padding(13)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(PXTheme.stroke, lineWidth: 0.7))
    }

    private func weekdayBar(width: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(days) { day in
                    Button {
                        withAnimation(PXTheme.quick) { selectedWeekday = day.weekday.id }
                    } label: {
                        PXChip(
                            title: day.weekday.cn,
                            selected: selectedDay?.weekday.id == day.weekday.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PXTheme.padding(for: width))
            .padding(.vertical, 14)
        }
    }

    @ViewBuilder
    private func calendarGrid(width: CGFloat) -> some View {
        if coordinator.isLoading && days.isEmpty {
            PXLoadingCard()
        } else if let day = selectedDay {
            let columns = Array(repeating: GridItem(.adaptive(minimum: 104), spacing: 14), count: 1)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 14)], spacing: 18) {
                ForEach(day.items) { subject in
                    NavigationLink {
                        PXBangumiDetailView(subjectID: subject.id, initial: subject)
                    } label: {
                        PXBangumiPosterCard(subject: subject)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PXTheme.padding(for: width))
        } else {
            PXEmptyState(
                title: "本周没有放送数据",
                message: "Bangumi 日历暂时不可用，稍后下拉刷新。",
                symbol: "calendar.badge.exclamationmark"
            )
        }
    }

    @ViewBuilder
    private func collectionsSection(width: CGFloat) -> some View {
        if coordinator.isLoggedIn {
            let items = coordinator.collections.compactMap(\.subject)
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    PXSectionHeader(title: "我的收藏", subtitle: "\(items.count) 部", symbol: "heart")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(items.prefix(16)) { subject in
                                NavigationLink {
                                    PXBangumiDetailView(subjectID: subject.id, initial: subject)
                                } label: {
                                    PXBangumiPosterCard(subject: subject, width: 112)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, PXTheme.padding(for: width))
                .padding(.top, 28)
            }
        }
    }
}
