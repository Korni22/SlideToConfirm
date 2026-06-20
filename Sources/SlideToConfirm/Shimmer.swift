import SwiftUI

/// A subtle left-to-right sheen that sweeps across the modified content,
/// echoing the classic "slide to unlock" prompt.
///
/// Honours **Reduce Motion**: when enabled (or when `active` is `false`) the
/// content renders unchanged.
struct Shimmer: ViewModifier {
    var active: Bool

    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if active && !reduceMotion {
            content.overlay { sheen }.mask(content)
        } else {
            content
        }
    }

    private var sheen: some View {
        GeometryReader { geo in
            let width = geo.size.width
            LinearGradient(
                colors: [.clear, .white.opacity(0.9), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.45)
            .offset(x: phase * width)
            .blendMode(.plusLighter)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1.6
                }
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    /// Sweeps a sheen across the view while `active` is `true`.
    func shimmer(active: Bool) -> some View {
        modifier(Shimmer(active: active))
    }
}
