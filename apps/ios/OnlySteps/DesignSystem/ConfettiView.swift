import SwiftUI

/// A short burst of falling confetti. Each change of `run` starts a new
/// burst; it is decorative, so it ignores touches and VoiceOver.
struct ConfettiView: View {
    let run: Int

    @State private var start: Date?
    private static let duration = 3.2
    private static let colors = [OSColor.chart1, OSColor.chart2, OSColor.chart3, OSColor.chart4, OSColor.chart5, OSColor.podiumGold]

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let t = timeline.date.timeIntervalSince(start)
                guard t >= 0, t < Self.duration else { return }
                for index in 0..<110 {
                    var random = SeededRandom(seed: UInt64(index + 1) &* 2_654_435_761 &+ UInt64(run))
                    let delay = Double.random(in: 0...0.5, using: &random)
                    let speed = Double.random(in: 140...320, using: &random)
                    let sway = Double.random(in: 10...36, using: &random)
                    let phase = Double.random(in: 0...(2 * .pi), using: &random)
                    let spin = Double.random(in: -6...6, using: &random)
                    let x0 = Double.random(in: 0...1, using: &random) * size.width
                    let color = Self.colors[Int.random(in: 0..<Self.colors.count, using: &random)]
                    let time = t - delay
                    guard time > 0 else { continue }
                    let x = x0 + sway * sin(time * 3 + phase)
                    let y = -20 + speed * time + 160 * time * time
                    guard y < size.height + 20 else { continue }
                    var piece = context
                    piece.opacity = min(1, (Self.duration - t) / 0.6)
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .radians(spin * time + phase))
                    piece.fill(Path(CGRect(x: -4, y: -6, width: 8, height: 12)), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: run) {
            let started = Date.now
            start = started
            Task {
                try? await Task.sleep(for: .seconds(Self.duration))
                if start == started { start = nil }
            }
        }
    }
}

/// SplitMix64, so every frame draws the same pieces for a given burst.
private struct SeededRandom: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
