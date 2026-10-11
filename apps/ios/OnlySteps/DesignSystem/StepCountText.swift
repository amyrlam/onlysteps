import SwiftUI

/// A step count with digits that don't jiggle as they change.
struct StepCountText: View {
    let steps: Int
    var font: Font = .body
    var showsUnit = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: OSSpace._1) {
            Text(steps, format: .number)
                .font(font)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(steps)))
            if showsUnit {
                Text(steps == 1 ? "step" : "steps")
                    .font(.subheadline)
                    .foregroundStyle(OSColor.mutedForeground)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A round rank number; gold, silver and bronze for the top three.
struct RankBadge: View {
    let rank: Int
    var size: CGFloat = OSSpace._8

    var body: some View {
        Text(rank, format: .number)
            .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(rank <= 3 ? OSColor.primaryForeground : OSColor.mutedForeground)
            .frame(width: size, height: size)
            .background(Self.color(for: rank), in: Circle())
            .accessibilityLabel("Rank \(rank)")
    }

    static func color(for rank: Int) -> Color {
        switch rank {
        case 1: OSColor.podiumGold
        case 2: OSColor.podiumSilver
        case 3: OSColor.podiumBronze
        default: OSColor.muted
        }
    }
}

#Preview("Step counts") {
    VStack(alignment: .leading, spacing: OSSpace._3) {
        StepCountText(steps: 12_345, font: .largeTitle.bold(), showsUnit: true)
        StepCountText(steps: 987, font: .headline)
        StepCountText(steps: 1, showsUnit: true)
        HStack(spacing: OSSpace._2) {
            ForEach(1...5, id: \.self) { RankBadge(rank: $0) }
        }
    }
    .padding(OSSpace._6)
    .background(OSColor.background)
}
