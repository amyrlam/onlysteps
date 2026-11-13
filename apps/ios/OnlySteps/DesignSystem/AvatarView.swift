import SwiftUI

/// A circle with someone's picture, or their initials on a color that is
/// consistent per name while the picture loads or when they have none.
struct AvatarView: View {
    let name: String
    /// The profile's `avatar_url`, if any.
    var imageURL: String? = nil
    var size: CGFloat = OSSpace._10
    var isHighlighted = false

    private static let palette = [OSColor.chart1, OSColor.chart2, OSColor.chart3, OSColor.chart4, OSColor.chart5]

    var body: some View {
        Circle()
            .fill(color)
            .overlay {
                Text(Initials.from(name))
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundStyle(OSColor.primaryForeground)
            }
            .overlay {
                if let imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.clear
                    }
                    .clipShape(Circle())
                }
            }
            .overlay {
                if isHighlighted {
                    Circle().strokeBorder(OSColor.ring, lineWidth: 2).padding(-OSSpace._1)
                }
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var color: Color {
        // A stable hash: String.hashValue changes on every launch.
        let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Self.palette[sum % Self.palette.count]
    }
}

enum Initials {
    /// "Ada Lovelace" -> "AL", "cher" -> "C", "" -> "?"
    static func from(_ name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let letters = [words.first, words.count > 1 ? words.last : nil]
            .compactMap { $0?.first.map(String.init) }
            .joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }
}

#Preview("Avatars") {
    HStack(spacing: OSSpace._4) {
        AvatarView(name: "Ada Lovelace")
        AvatarView(name: "Grace Hopper", isHighlighted: true)
        AvatarView(name: "Linus", size: OSSpace._16)
        AvatarView(name: "", size: OSSpace._8)
    }
    .padding(OSSpace._6)
    .background(OSColor.background)
}
