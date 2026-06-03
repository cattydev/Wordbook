import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var current: AppDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.current = self
        NSApp.setActivationPolicy(.accessory)
        installWindowObservers()
    }

    static func presentRegularApp() {
        current?.setRegularActivation()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func installWindowObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(handleWindowStateChange), name: NSWindow.didBecomeKeyNotification, object: nil)
        center.addObserver(self, selector: #selector(handleWindowStateChange), name: NSWindow.willCloseNotification, object: nil)
    }

    @objc
    private func handleWindowStateChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateActivationPolicy()
        }
    }

    private func setRegularActivation() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
    }

    private func updateActivationPolicy() {
        let hasManagedWindows = NSApp.windows.contains { window in
            window.isVisible && window.styleMask.contains(.titled) && window.isMiniaturized == false
        }

        if hasManagedWindows {
            setRegularActivation()
        } else if NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

@main
struct WordbookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup("Wordbook", id: "main") {
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
