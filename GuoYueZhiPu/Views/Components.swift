import SwiftUI

enum AppTheme {
    static let ink = Color(hex: "#202423")
    static let jade = Color(hex: "#2B5A4A")
    static let cinnabar = Color(hex: "#9A3629")
    static let gold = Color(hex: "#CAA044")
    static let lapis = Color(hex: "#364C78")
    static let paper = Color(hex: "#F3EFE6")

    static var background: Color {
        Color(.systemGroupedBackground)
    }

    static var surface: Color {
        Color(.secondarySystemGroupedBackground)
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

struct BrandHeroImage: View {
    var height: CGFloat = 220

    var body: some View {
        Image("brand_hero")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [.black.opacity(0.05), .black.opacity(0.56)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }
}

struct AppSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct InstrumentArtwork: View {
    let instrument: Instrument
    var cornerRadius: CGFloat = 8

    var body: some View {
        Image(instrument.artworkAssetName)
            .resizable()
            .scaledToFill()
            .overlay(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.56)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .accessibilityHidden(true)
    }
}

struct SectionBadge: View {
    let section: OrchestraSection

    var body: some View {
        HStack(spacing: 6) {
            Text(section.ordinal)
                .font(.caption2.weight(.bold))
            Text(section.nameZh)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: section.colorHex), in: Capsule())
    }
}

struct PremiumPill: View {
    var text = "Pro"

    var body: some View {
        Label(text, systemImage: "sparkles")
            .font(.caption.weight(.bold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.gold, in: Capsule())
    }
}

struct PremiumTeaserCard: View {
    let feature: PremiumFeature
    let isUnlocked: Bool
    var action: (() -> Void)?

    var body: some View {
        AppSurface {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: feature.systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(isUnlocked ? AppTheme.gold : AppTheme.cinnabar)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(feature.title)
                            .font(.headline)
                        if !isUnlocked {
                            PremiumPill(text: "需解鎖")
                        }
                    }

                    Text(feature.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if let action, !isUnlocked {
                    Button(action: action) {
                        Image(systemName: "lock.open")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.cinnabar)
                    .accessibilityLabel("前往解鎖")
                }
            }
        }
    }
}

struct MetricCapsule: View {
    let title: String
    let value: String
    let systemImage: String
    var color: Color = AppTheme.jade

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct TagLabel: View {
    let text: String
    var color: Color = .secondary

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 84, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SectionFilterBar: View {
    let sections: [OrchestraSection]
    @Binding var selectedSectionID: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedSectionID = nil
                } label: {
                    Label("全部", systemImage: "square.grid.2x2")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(FilterChipStyle(isSelected: selectedSectionID == nil, color: .primary))

                ForEach(sections) { section in
                    Button {
                        selectedSectionID = section.id
                    } label: {
                        Text(section.nameZh)
                    }
                    .buttonStyle(FilterChipStyle(
                        isSelected: selectedSectionID == section.id,
                        color: Color(hex: section.colorHex)
                    ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

struct FilterChipStyle: ButtonStyle {
    let isSelected: Bool
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .white : .primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.secondarySystemGroupedBackground), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.clear : Color(.separator), lineWidth: 0.5)
            }
            .opacity(configuration.isPressed ? 0.72 : 1.0)
    }
}
