import SwiftUI

@main
struct ExoCameraApp: App {
    @NSApplicationDelegateAdaptor(ExoCameraApplicationDelegate.self) private var applicationDelegate
    @StateObject private var model = AppModel()

    init() {
        LegacyAICameraMigration.migrateSupportDirectory()
    }

    var body: some Scene {
        MenuBarExtra("Exo Camera", image: "MenuBarIcon") {
            ControlCenterView(model: model)
        }
        .menuBarExtraStyle(.window)

        Window("Exo Camera Preview", id: "preview") {
            PreviewView(model: model)
        }
        .defaultSize(width: 900, height: 620)
        .windowResizability(.contentMinSize)

        Window("About Exo Camera", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)

        Window("Exo Camera Notes", id: "notes") {
            AgentNotesView(controller: model.agentNotes)
        }
        .defaultSize(width: 460, height: 560)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView(model: model)
        }
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Close Window") {
                    AppLifecycleCoordinator.shared.handleWindowQuitCommand()
                }
                .keyboardShortcut("q")
            }
        }
    }
}
