import SwiftUI

struct PXDetailBackdrop: View {
    var url: URL?
    var drama: Drama? = nil
    var logoURL: URL?
    var title: String
    var height: CGFloat
    var showsForeground: Bool = true

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let url {
                    PXRemoteImage(url: url, maxPixel: 2000)
                } else if let drama {
                    PXCoverImage(drama: drama, maxPixel: 1400)
                        .blur(radius: 26)
                        .overlay(Color.black.opacity(0.28))
                } else {
                    PXTheme.backgroundLift
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.10), location: 0),
                    .init(color: .black.opacity(0.20), location: 0.38),
                    .init(color: PXTheme.background.opacity(0.70), location: 0.74),
                    .init(color: PXTheme.background, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            LinearGradient(
                colors: [PXTheme.background.opacity(0.60), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            if showsForeground, let logoURL {
                PXRemoteImage(url: logoURL, contentMode: .fit, maxPixel: 900)
                    .frame(maxWidth: 380, maxHeight: 100, alignment: .leading)
                    .padding(.horizontal, PXTheme.widePadding)
                    .padding(.bottom, 34)
            } else if showsForeground {
                Text(title)
                    .font(PXFont.display(38))
                    .foregroundStyle(PXTheme.textPrimary)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.42), radius: 14, y: 6)
                    .padding(.horizontal, PXTheme.widePadding)
                    .padding(.bottom, 30)
            }
        }
        .frame(height: height)
        .clipped()
    }
}
