import SwiftUI
struct PXPlayerSleepTimerMenu: View {
    @Binding var minutes: Int?
    var body: some View {
        Menu {
            Button("关闭") { minutes = nil }
            ForEach([15, 30, 45, 60, 90], id: \.self) { value in
                Button("\(value) 分钟") { minutes = value }
            }
        } label: {
            Label(minutes.map { "\($0) 分钟" } ?? "定时关闭", systemImage: "moon.zzz")
                .font(.system(size: 10, weight: .semibold))
        }
    }
}
