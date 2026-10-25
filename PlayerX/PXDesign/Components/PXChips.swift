import SwiftUI

struct PXChip: View {
    var title: String
    var selected: Bool = false
    var symbol: String?
    var tint: Color = PXTheme.accent

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 10, weight: .bold))
            }
            Text(title)
                .font(.system(size: 12, weight: selected ? .bold : .medium))
        }
        .foregroundStyle(selected ? Color.black.opacity(0.86) : PXTheme.textSecondary)
        .padding(.horizontal, 12)
        .frame(height: 31)
        .background {
            if selected {
                Capsule().fill(tint)
            } else {
                Capsule().fill(PXTheme.surfaceMuted)
            }
        }
        .overlay {
            Capsule().strokeBorder(selected ? .clear : PXTheme.stroke, lineWidth: 0.7)
        }
    }
}

struct PXTag: View {
    var text: String
    var tint: Color = PXTheme.textSecondary

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(tint.opacity(0.10), in: Capsule())
            .overlay(Capsule().strokeBorder(tint.opacity(0.18), lineWidth: 0.6))
    }
}

struct PXRatingBadge: View {
    var rating: Double?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill").font(.system(size: 9, weight: .bold))
            Text(PXFormat.rating(rating))
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(rating == nil ? PXTheme.textSecondary : PXTheme.rating)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(PXTheme.stroke, lineWidth: 0.6))
    }
}

struct PXMetaDot: View {
    var body: some View {
        Circle().fill(PXTheme.textTertiary).frame(width: 3, height: 3)
    }
}

struct PXMetadataLine: View {
    var parts: [String]

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 { PXMetaDot() }
                Text(part)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PXTheme.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}
