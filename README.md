# SlideToConfirm

A small, dependency-free SwiftUI slide-to-confirm control in the spirit of the
classic *slide to unlock*, CallKit's *slide to answer*, and AlarmKit's
*slide to stop*.

The user drags a thumb across a track; crossing a threshold fires a single
`onConfirm` callback. It's fully configurable, accessible to VoiceOver, honours
Reduce Motion, and can render its track with the iOS 26 **Liquid Glass**
material.

- **Platforms:** iOS 26+
- **Dependencies:** none (SwiftUI only)
- **License:** MIT

## Installation

Swift Package Manager — add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/<you>/SlideToX.git", from: "1.0.0")
```

or in Xcode: *File ▸ Add Package Dependencies…* and point it at the repo.

```swift
import SlideToConfirm
```

## Usage

```swift
SlideToConfirm("slide to stop", systemImage: "stop.fill") {
    stopAlarm()
}
```

### Styling

Styling cascades through the environment like `buttonStyle`, so you can set it
once on a container:

```swift
SlideToConfirm("slide to answer", systemImage: "phone.fill") {
    answerCall()
}
.slideToConfirmStyle(.init(tint: .green, height: 70))
```

`SlideToConfirmStyle` knobs (all defaulted):

| Property | Default | Notes |
|----------|---------|-------|
| `tint` | `.accentColor` | Thumb fill |
| `trackColor` | `.secondarySystemFill` | Track fill (ignored when `glass`) |
| `textColor` | `.secondary` | Prompt label |
| `height` | `60` | Control height; thumb is sized to fit |
| `threshold` | `0.9` | Fraction of travel needed to confirm (`0...1`) |
| `hapticsEnabled` | `true` | Engage + success haptics |
| `glass` | `false` | Render the track as iOS 26 Liquid Glass |

### Liquid Glass

```swift
SlideToConfirm("slide to answer", systemImage: "phone.fill") { answerCall() }
    .slideToConfirmStyle(.init(tint: .green, glass: true))
```

The track uses `.glassEffect(.regular, in: Capsule())`. Glass is only visible
over colourful content — place it on a vivid background, not plain white.

### Resetting

By default the control **latches** once confirmed (typical when the action
dismisses or navigates away). To reset it, use the binding overload and set it
back to `false`:

```swift
@State private var confirmed = false

SlideToConfirm("slide to end trip", systemImage: "flag.checkered",
               isConfirmed: $confirmed) {
    endTrip()
}

Button("Undo") { confirmed = false }
```

### Disabling

The control honors the standard `.disabled(_:)` modifier. When disabled it dims,
the thumb turns gray, the shimmer stops, and dragging or activating it does
nothing:

```swift
SlideToConfirm("waiting for others…", systemImage: "person.2.fill") {
    launch()
}
.disabled(!everyoneReady)
```

### Accessibility

The control is exposed to VoiceOver as a single button — dragging is not
required. Activating it (double-tap) confirms directly. The shimmer is
suppressed under **Reduce Motion**, and haptics can be turned off via the
style.

## Example app

`Example/SlideToXExample.xcodeproj` is a bare iOS app that depends on the local
package and demonstrates every configuration (including the Liquid Glass
track). Open it and run on a simulator or device to feel the drag.

## License

MIT — see [LICENSE](LICENSE).
