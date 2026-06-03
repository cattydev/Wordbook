import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct WordbookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        Window("Wordbook", id: "main") {
            MainWindowView(model: model)
                .frame(minWidth: 920, minHeight: 620)
                .containerBackground(.regularMaterial, for: .window)
        }
        .restorationBehavior(.disabled)

        MenuBarExtra("Wordbook", systemImage: "text.book.closed.fill") {
            MenuBarRootView(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
                .containerBackground(.thinMaterial, for: .window)
        }
    }
}
