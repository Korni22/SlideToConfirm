import CoreGraphics

/// Pure, UI-free geometry for the slide control.
///
/// The clamping and threshold math lives here, separate from the SwiftUI
/// view, so it can be unit-tested without standing up a rendering host.
enum SlideGeometry {
    /// The maximum horizontal distance the thumb can travel inside the track.
    ///
    /// - Parameters:
    ///   - trackWidth: Full width of the track.
    ///   - thumbDiameter: Diameter of the draggable thumb.
    ///   - inset: Padding between the thumb and each end of the track.
    /// - Returns: The travel distance, never negative.
    static func maxOffset(trackWidth: CGFloat, thumbDiameter: CGFloat, inset: CGFloat) -> CGFloat {
        max(0, trackWidth - thumbDiameter - inset * 2)
    }

    /// Clamps a proposed offset into the valid `0...maxOffset` range.
    static func clamp(_ proposed: CGFloat, maxOffset: CGFloat) -> CGFloat {
        guard maxOffset > 0 else { return 0 }
        return min(max(proposed, 0), maxOffset)
    }

    /// The fraction of the track the thumb has travelled, in `0...1`.
    static func progress(offset: CGFloat, maxOffset: CGFloat) -> CGFloat {
        guard maxOffset > 0 else { return 0 }
        return min(max(offset / maxOffset, 0), 1)
    }

    /// Whether the given progress reaches the confirmation threshold.
    static func isPastThreshold(progress: CGFloat, threshold: CGFloat) -> Bool {
        progress >= threshold
    }
}
