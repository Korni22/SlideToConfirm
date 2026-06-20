import CoreGraphics
import Testing
@testable import SlideToConfirm

@Suite("SlideGeometry")
struct SlideGeometryTests {

    @Test("maxOffset subtracts the thumb and both insets")
    func maxOffset() {
        #expect(SlideGeometry.maxOffset(trackWidth: 300, thumbDiameter: 52, inset: 4) == 240)
    }

    @Test("maxOffset never goes negative when the track is too small")
    func maxOffsetClampsToZero() {
        #expect(SlideGeometry.maxOffset(trackWidth: 40, thumbDiameter: 52, inset: 4) == 0)
    }

    @Test("clamp keeps the offset within range", arguments: [
        (input: -50.0, expected: 0.0),
        (input: 0.0, expected: 0.0),
        (input: 120.0, expected: 120.0),
        (input: 240.0, expected: 240.0),
        (input: 300.0, expected: 240.0),
    ] as [(input: CGFloat, expected: CGFloat)])
    func clamp(c: (input: CGFloat, expected: CGFloat)) {
        #expect(SlideGeometry.clamp(c.input, maxOffset: 240) == c.expected)
    }

    @Test("clamp returns zero when there is no travel")
    func clampZeroTravel() {
        #expect(SlideGeometry.clamp(100, maxOffset: 0) == 0)
    }

    @Test("progress is a 0...1 fraction of travel")
    func progress() {
        #expect(SlideGeometry.progress(offset: 0, maxOffset: 240) == 0)
        #expect(SlideGeometry.progress(offset: 120, maxOffset: 240) == 0.5)
        #expect(SlideGeometry.progress(offset: 240, maxOffset: 240) == 1)
    }

    @Test("progress clamps past the ends")
    func progressClamps() {
        #expect(SlideGeometry.progress(offset: -10, maxOffset: 240) == 0)
        #expect(SlideGeometry.progress(offset: 999, maxOffset: 240) == 1)
    }

    @Test("progress is zero when there is no travel")
    func progressZeroTravel() {
        #expect(SlideGeometry.progress(offset: 100, maxOffset: 0) == 0)
    }

    @Test("threshold is reached at or above the cutoff")
    func threshold() {
        #expect(SlideGeometry.isPastThreshold(progress: 0.9, threshold: 0.9))
        #expect(SlideGeometry.isPastThreshold(progress: 0.95, threshold: 0.9))
        #expect(!SlideGeometry.isPastThreshold(progress: 0.89, threshold: 0.9))
    }
}
