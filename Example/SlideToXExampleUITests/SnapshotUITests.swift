import XCTest

/// Drives a single, deliberate slide across the `demo` scene so a screen
/// recording captures the real gesture, thumb spring, symbol morph, and prompt
/// fade. `Scripts/make-screenshots.sh` wraps this test with
/// `simctl io recordVideo` and turns the result into the README GIF (and grabs
/// its final frame as the "confirmed" still).
final class SnapshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSlideToConfirmGesture() {
        let app = XCUIApplication()
        app.launchArguments += ["-UI-SCREENSHOTS"]
        app.launchEnvironment["SNAPSHOT_SCENE"] = "demo"
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Let the resting shimmer play for a beat before the drag begins.
        sleep(1)

        // The control is centred; the thumb sits at the leading inset. Drag
        // from there to the trailing edge slowly enough to read as a real
        // user gesture rather than a flick.
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.13, dy: 0.5))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: 220, thenHoldForDuration: 0.2)

        // Let the confirm spring settle, then capture the confirmed state as a
        // result-bundle attachment. This is deterministic — unlike grabbing a
        // frame from the recording, which races the test teardown.
        usleep(600_000)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "confirmed"
        shot.lifetime = .keepAlways
        add(shot)

        // Dwell so the GIF tail rests on the confirmed state too.
        sleep(2)
    }
}
