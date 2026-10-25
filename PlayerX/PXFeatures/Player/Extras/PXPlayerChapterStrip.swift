import SwiftUI
struct PXPlayerChapterStrip: View {
    @ObservedObject var model: PXPlayerModel
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(model.chapters.enumerated()), id: \.element.id) { index, chapter in
                    Button { model.playEpisode(index) } label: {
                        Text(chapter.title.isEmpty ? "第 \(index + 1) 集" : chapter.title)
                            .font(.system(size: 10, weight: index == model.currentIndex ? .bold : .medium))
                            .foregroundStyle(index == model.currentIndex ? .black.opacity(0.84) : .white.opacity(0.68))
                            .padding(.horizontal, 10).frame(height: 27)
                            .background(index == model.currentIndex ? PXTheme.accent : .white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
