import SwiftUI

/// Visual and behavioural configuration for ``SlideToConfirm``.
///
/// Apply a style with the ``SwiftUI/View/slideToConfirmStyle(_:)`` modifier;
/// it cascades through the environment like `buttonStyle`, so you can set it
/// once on a container and have every control below inherit it.
public struct SlideToConfirmStyle: Sendable, Equatable {
    /// Fill colour of the thumb.
    public var tint: Color
    /// Background colour of the track.
    public var trackColor: Color
    /// Colour of the prompt label.
    public var textColor: Color
    /// Overall height of the control. The thumb is sized to fit.
    public var height: CGFloat
    /// Fraction of travel (`0...1`) the thumb must cross to confirm.
    public var threshold: CGFloat
    /// Whether to play haptics on engage and on confirm.
    public var hapticsEnabled: Bool
    /// Renders the track with the iOS 26 Liquid Glass material instead of a
    /// solid `trackColor` fill. The thumb stays solid (as in CallKit's
    /// *slide to answer*). Glass is most visible over colourful content.
    public var glass: Bool

    public init(
        tint: Color = .accentColor,
        trackColor: Color = Color(.secondarySystemFill),
        textColor: Color = .secondary,
        height: CGFloat = 60,
        threshold: CGFloat = 0.9,
        hapticsEnabled: Bool = true,
        glass: Bool = false
    ) {
        self.tint = tint
        self.trackColor = trackColor
        self.textColor = textColor
        self.height = height
        self.threshold = min(max(threshold, 0), 1)
        self.hapticsEnabled = hapticsEnabled
        self.glass = glass
    }

    /// The default style.
    public static let automatic = SlideToConfirmStyle()
}

extension EnvironmentValues {
    @Entry var slideToConfirmStyle: SlideToConfirmStyle = .automatic
}

public extension View {
    /// Sets the style for ``SlideToConfirm`` controls within this view.
    func slideToConfirmStyle(_ style: SlideToConfirmStyle) -> some View {
        environment(\.slideToConfirmStyle, style)
    }
}
