import SlideToConfirm
import SwiftUI

/// A bare harness that exercises ``SlideToConfirm`` in several configurations
/// so you can feel the drag, haptics, and reset behaviour on a device.
struct ContentView: View {
    @State private var lastAction = "—"
    @State private var endTripConfirmed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    section("Classic") {
                        SlideToConfirm("slide to unlock", systemImage: "arrow.right") {
                            lastAction = "Unlocked"
                        }
                    }

                    section("Alarm — slide to stop") {
                        SlideToConfirm("slide to stop", systemImage: "stop.fill") {
                            lastAction = "Alarm stopped"
                        }
                        .slideToConfirmStyle(.init(tint: .orange, height: 64))
                    }

                    section("Call — slide to answer") {
                        SlideToConfirm("slide to answer", systemImage: "phone.fill") {
                            lastAction = "Call answered"
                        }
                        .slideToConfirmStyle(.init(tint: .green, height: 70))
                    }

                    section("Resettable — end trip") {
                        SlideToConfirm(
                            "slide to end trip",
                            systemImage: "flag.checkered",
                            isConfirmed: $endTripConfirmed
                        ) {
                            lastAction = "Trip ended"
                        }
                        .slideToConfirmStyle(.init(tint: .red))

                        Button("Reset") { endTripConfirmed = false }
                            .buttonStyle(.bordered)
                            .disabled(!endTripConfirmed)
                    }

                    section("Easy threshold (0.5), no haptics") {
                        SlideToConfirm("easy slide") {
                            lastAction = "Easy slide done"
                        }
                        .slideToConfirmStyle(.init(tint: .purple, threshold: 0.5, hapticsEnabled: false))
                    }

                    section("Liquid Glass track") {
                        // Glass is only visible over colourful content, so put
                        // the control on a vivid backdrop.
                        ZStack {
                            LinearGradient(
                                colors: [.indigo, .pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            SlideToConfirm("slide to answer", systemImage: "phone.fill") {
                                lastAction = "Glass call answered"
                            }
                            .slideToConfirmStyle(.init(tint: .green, height: 68, glass: true))
                            .padding(20)
                        }
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
                .padding(24)
            }
            .navigationTitle("SlideToConfirm")
            .safeAreaInset(edge: .bottom) {
                Text("Last action: \(lastAction)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.bar)
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
