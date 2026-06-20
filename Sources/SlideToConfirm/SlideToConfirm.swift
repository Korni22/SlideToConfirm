import SwiftUI

/// A slide-to-confirm control in the spirit of the classic *slide to unlock*,
/// CallKit's *slide to answer*, and AlarmKit's *slide to stop*.
///
/// The user drags a thumb across a track. Crossing the configured threshold
/// fires `onConfirm` exactly once and latches the control into a confirmed
/// state. Releasing before the threshold springs the thumb back.
///
/// ```swift
/// SlideToConfirm("slide to stop", systemImage: "stop.fill") {
///     stopAlarm()
/// }
/// .slideToConfirmStyle(.init(tint: .orange))
/// ```
///
/// Use the ``init(_:systemImage:confirmedSystemImage:isConfirmed:onConfirm:)``
/// overload when you need to reset the control: set the binding back to
/// `false`.
///
/// ### Accessibility
/// The control is exposed to VoiceOver as a single button — dragging is not
/// required. Activating it (double-tap) confirms directly. The shimmer is
/// suppressed under Reduce Motion, and haptics can be disabled via the style.
public struct SlideToConfirm: View {
    private let label: LocalizedStringKey
    private let systemImage: String
    private let confirmedSystemImage: String
    private let onConfirm: () -> Void

    @Binding private var externalConfirmed: Bool

    @Environment(\.slideToConfirmStyle) private var style
    @Environment(\.layoutDirection) private var layoutDirection

    @State private var dragOffset: CGFloat = 0
    @State private var isConfirmed = false
    @State private var isDragging = false

    /// Creates a control that latches once confirmed. Recreate or dismiss the
    /// view to reset it.
    public init(
        _ label: LocalizedStringKey,
        systemImage: String = "chevron.right",
        confirmedSystemImage: String = "checkmark",
        onConfirm: @escaping () -> Void
    ) {
        self.init(
            label,
            systemImage: systemImage,
            confirmedSystemImage: confirmedSystemImage,
            isConfirmed: .constant(false),
            onConfirm: onConfirm
        )
    }

    /// Creates a control whose confirmed state is mirrored to `isConfirmed`.
    /// Set the binding back to `false` to reset the control.
    public init(
        _ label: LocalizedStringKey,
        systemImage: String = "chevron.right",
        confirmedSystemImage: String = "checkmark",
        isConfirmed: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) {
        self.label = label
        self.systemImage = systemImage
        self.confirmedSystemImage = confirmedSystemImage
        self._externalConfirmed = isConfirmed
        self.onConfirm = onConfirm
    }

    private var thumbDiameter: CGFloat { style.height - inset * 2 }
    private let inset: CGFloat = 4

    public var body: some View {
        GeometryReader { geo in
            let maxOffset = SlideGeometry.maxOffset(
                trackWidth: geo.size.width,
                thumbDiameter: thumbDiameter,
                inset: inset
            )
            let displayOffset = isConfirmed ? maxOffset : dragOffset
            let progress = SlideGeometry.progress(offset: displayOffset, maxOffset: maxOffset)

            ZStack(alignment: .leading) {
                track
                prompt(progress: progress)
                thumb
                    .padding(inset)
                    .offset(x: directed(displayOffset))
                    .gesture(dragGesture(maxOffset: maxOffset))
            }
        }
        .frame(height: style.height)
        .sensoryFeedback(.success, trigger: isConfirmed) { _, now in now && style.hapticsEnabled }
        .sensoryFeedback(.impact(weight: .light), trigger: isDragging) { _, now in now && style.hapticsEnabled }
        .onChange(of: isConfirmed) { _, now in externalConfirmed = now }
        .onChange(of: externalConfirmed) { _, now in
            if !now { reset() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text("Swipe to the end, or double tap, to confirm"))
        .accessibilityValue(isConfirmed ? Text("Confirmed") : Text(verbatim: ""))
        .accessibilityAction { confirm() }
    }

    // MARK: - Pieces

    @ViewBuilder
    private var track: some View {
        if style.glass {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: Capsule())
        } else {
            Capsule().fill(style.trackColor)
        }
    }

    private func prompt(progress: CGFloat) -> some View {
        Text(label)
            .font(.headline)
            .foregroundStyle(style.textColor)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, style.height)
            .opacity(isConfirmed ? 0 : 1 - Double(progress) * 0.85)
            .shimmer(active: !isConfirmed && !isDragging)
            .allowsHitTesting(false)
    }

    private var thumb: some View {
        Circle()
            .fill(style.tint)
            .overlay {
                Image(systemName: isConfirmed ? confirmedSystemImage : systemImage)
                    .font(.system(size: thumbDiameter * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: thumbDiameter, height: thumbDiameter)
            .scaleEffect(isDragging ? 1.06 : 1)
            .animation(.spring(duration: 0.2), value: isDragging)
            .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
    }

    // MARK: - Interaction

    private func dragGesture(maxOffset: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isConfirmed else { return }
                if !isDragging { isDragging = true }
                let raw = layoutDirection == .rightToLeft ? -value.translation.width : value.translation.width
                dragOffset = SlideGeometry.clamp(raw, maxOffset: maxOffset)
            }
            .onEnded { _ in
                guard !isConfirmed else { return }
                isDragging = false
                let progress = SlideGeometry.progress(offset: dragOffset, maxOffset: maxOffset)
                if SlideGeometry.isPastThreshold(progress: progress, threshold: style.threshold) {
                    confirm()
                } else {
                    withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                }
            }
    }

    private func confirm() {
        guard !isConfirmed else { return }
        withAnimation(.spring(duration: 0.3)) { isConfirmed = true }
        onConfirm()
    }

    private func reset() {
        withAnimation(.spring(duration: 0.3)) {
            isConfirmed = false
            dragOffset = 0
        }
    }

    /// Maps a positive travel distance to a signed horizontal offset that
    /// respects the layout direction (slides left in right-to-left layouts).
    private func directed(_ offset: CGFloat) -> CGFloat {
        layoutDirection == .rightToLeft ? -offset : offset
    }
}

#Preview("States") {
    @Previewable @State var bound = false
    VStack(spacing: 28) {
        SlideToConfirm("slide to unlock") {}

        SlideToConfirm("slide to stop", systemImage: "stop.fill") {}
            .slideToConfirmStyle(.init(tint: .orange))

        SlideToConfirm("slide to answer", systemImage: "phone.fill") {}
            .slideToConfirmStyle(.init(tint: .green, height: 68))

        SlideToConfirm("slide to end trip", systemImage: "flag.checkered", isConfirmed: $bound) {}
            .slideToConfirmStyle(.init(tint: .red))
        Button("Reset bound control") { bound = false }
    }
    .padding(24)
}
