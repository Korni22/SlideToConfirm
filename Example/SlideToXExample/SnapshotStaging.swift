import SlideToConfirm
import SwiftUI

/// Screenshot staging for the README assets.
///
/// When the app is launched with the `-UI-SCREENSHOTS` argument it renders one
/// full-screen variant of ``SlideToConfirm`` instead of the normal demo. The
/// variant is chosen by the `SNAPSHOT_SCENE` launch-environment value. This
/// keeps each captured frame to a single, centred control on a clean
/// background — see `Scripts/make-screenshots.sh`.
enum SnapshotScene: String {
    case classic
    case glass
    case disabled
    /// The control the GIF recording drags across. Identical to `classic` but
    /// kept separate so the still and the animation can diverge later.
    case demo

    static let flag = "-UI-SCREENSHOTS"
    static let environmentKey = "SNAPSHOT_SCENE"

    /// Resolve the active scene from the process inputs, or `nil` for a normal
    /// run (the gate flag is absent).
    static var current: SnapshotScene? {
        let info = ProcessInfo.processInfo
        guard info.arguments.contains(flag) else { return nil }
        let raw = info.environment[environmentKey] ?? classic.rawValue
        return SnapshotScene(rawValue: raw) ?? .classic
    }
}

/// A single, centred ``SlideToConfirm`` variant filling the screen, captioned
/// so each README image is self-explanatory.
struct SnapshotStage: View {
    let scene: SnapshotScene

    var body: some View {
        ZStack {
            background
            VStack(spacing: 16) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(scene == .glass ? .white : .primary)
                control
                    .padding(.top, 8)
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var control: some View {
        switch scene {
        case .classic, .demo:
            SlideToConfirm("slide to unlock", systemImage: "arrow.right") {}
        case .glass:
            SlideToConfirm("slide to answer", systemImage: "phone.fill") {}
                .slideToConfirmStyle(.init(tint: .green, height: 68, glass: true))
        case .disabled:
            SlideToConfirm("waiting for others…", systemImage: "person.2.fill") {}
                .slideToConfirmStyle(.init(tint: .green))
                .disabled(true)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch scene {
        case .glass:
            LinearGradient(
                colors: [.indigo, .pink, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            Color(.systemBackground)
        }
    }

    private var title: String {
        switch scene {
        case .classic, .demo: "Slide to unlock"
        case .glass: "Liquid Glass"
        case .disabled: "Disabled"
        }
    }
}
