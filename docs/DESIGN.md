# SlideToConfirm — Design

## Goal

A small, reusable, MIT-licensed SwiftUI slide-to-confirm control echoing the
classic *slide to unlock* / CallKit *slide to answer* / AlarmKit *slide to
stop* gestures. These iOS surfaces are all system-rendered (SpringBoard /
system processes), with no public, reusable component — so this rebuilds the
interaction from scratch rather than reverse-engineering it.

## Repository layout

```
SlideToX/
├── Package.swift                 — library product "SlideToConfirm", iOS 26+
├── Sources/SlideToConfirm/
│   ├── SlideGeometry.swift       — pure, UI-free clamp/progress/threshold math
│   ├── SlideToConfirmStyle.swift — config struct + environment modifier
│   ├── Shimmer.swift             — internal text-shimmer modifier
│   └── SlideToConfirm.swift      — the view
├── Tests/SlideToConfirmTests/    — Swift Testing over SlideGeometry
└── Example/SlideToXExample/      — bare iOS app depending on the local package
```

## Public API

```swift
SlideToConfirm("slide to stop", systemImage: "stop.fill") { /* onConfirm */ }
    .slideToConfirmStyle(.init(tint: .orange))
```

- `label: LocalizedStringKey`, `systemImage`, `confirmedSystemImage`, `onConfirm`.
- Optional `isConfirmed: Binding<Bool>` overload for programmatic reset.
- `SlideToConfirmStyle` (all defaulted): `tint`, `trackColor`, `textColor`,
  `height`, `threshold`, `hapticsEnabled`, `glass`. Applied via the
  environment-backed `slideToConfirmStyle(_:)` modifier so it cascades like
  `buttonStyle`.

## Behaviour & states

Internal states **idle → dragging → confirmed**:

- The thumb starts at the leading edge; the drag translation is clamped to
  `0...maxOffset`.
- Release **past `threshold`** springs the thumb to the end, swaps the glyph to
  a checkmark, fires `onConfirm` once, and **latches**. Release before springs
  back to idle.
- Latching is the default (confirm actions usually dismiss/navigate). The
  `isConfirmed` binding mirrors the state out and resets the control when set
  to `false`.
- Right-to-left layouts mirror the travel direction.
- The control reads `@Environment(\.isEnabled)`, so the standard `.disabled(_:)`
  modifier dims it, grays the thumb, stops the shimmer, and makes the drag and
  the accessibility action no-ops.

## Liquid Glass

`glass: true` renders the track with `.glassEffect(.regular, in: Capsule())`
(iOS 26). The thumb stays solid, matching CallKit/AlarmKit. Glass is only
visible over colourful content.

## Accessibility & motion

- One accessibility element, exposed as a button with a custom **Confirm**
  action — fully operable by VoiceOver without dragging.
- Shimmer is suppressed under **Reduce Motion**.
- Haptics use `.sensoryFeedback` (`.impact(weak)` on engage, `.success` on
  confirm) and can be disabled via the style.

## Testing

- **Unit (Swift Testing):** `SlideGeometry` clamp / progress / threshold math,
  tested without a UI host.
- **Visual:** `#Preview`s in the package + the Example app for real-device feel.

## Non-goals (v1)

- Multi-step / segmented sliders.
- Combining track + thumb in a `GlassEffectContainer` morph (the thumb stays
  solid by design).
