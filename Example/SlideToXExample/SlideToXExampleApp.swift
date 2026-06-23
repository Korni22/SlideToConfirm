import SwiftUI

@main
struct SlideToXExampleApp: App {
    var body: some Scene {
        WindowGroup {
            if let scene = SnapshotScene.current {
                SnapshotStage(scene: scene)
            } else {
                ContentView()
            }
        }
    }
}
