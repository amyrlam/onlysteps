import SwiftUI

/// Full-width button in the app's style.
/// Usage: `Button("Join") { ... }.buttonStyle(.osPrimary)`
struct OSButtonStyle: ButtonStyle {
    enum Variant {
        case primary, secondary, destructive
    }

    var variant: Variant = .primary
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, OSSpace._3)
            .padding(.horizontal, OSSpace._4)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: OSRadius.md, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .primary: OSColor.primaryForeground
        case .secondary: OSColor.secondaryForeground
        case .destructive: OSColor.destructiveForeground
        }
    }

    private var background: Color {
        switch variant {
        case .primary: OSColor.primary
        case .secondary: OSColor.secondary
        case .destructive: OSColor.destructive
        }
    }
}

extension ButtonStyle where Self == OSButtonStyle {
    static var osPrimary: OSButtonStyle { OSButtonStyle(variant: .primary) }
    static var osSecondary: OSButtonStyle { OSButtonStyle(variant: .secondary) }
    static var osDestructive: OSButtonStyle { OSButtonStyle(variant: .destructive) }
}

#Preview("Buttons") {
    VStack(spacing: OSSpace._3) {
        Button("Create group") {}.buttonStyle(.osPrimary)
        Button("Join with code") {}.buttonStyle(.osSecondary)
        Button("Sign out") {}.buttonStyle(.osDestructive)
        Button("Disabled") {}.buttonStyle(.osPrimary).disabled(true)
    }
    .padding(OSSpace._4)
    .background(OSColor.background)
}
