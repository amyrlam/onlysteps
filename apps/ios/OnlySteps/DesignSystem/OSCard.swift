import SwiftUI

/// A rounded, bordered surface for grouping content.
struct OSCard<Content: View>: View {
    var padding: CGFloat = OSSpace._4
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: OSRadius.lg, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(OSColor.cardForeground)
            .background(OSColor.card, in: shape)
            .overlay(shape.strokeBorder(OSColor.border, lineWidth: 1))
    }
}

#Preview("Card") {
    VStack(spacing: OSSpace._4) {
        OSCard {
            VStack(alignment: .leading, spacing: OSSpace._1) {
                Text("Today").font(.subheadline).foregroundStyle(OSColor.mutedForeground)
                StepCountText(steps: 8_421, font: .largeTitle.bold(), showsUnit: true)
            }
        }
        OSCard(padding: OSSpace._2) {
            Text("Compact card")
        }
    }
    .padding(OSSpace._4)
    .background(OSColor.background)
}
