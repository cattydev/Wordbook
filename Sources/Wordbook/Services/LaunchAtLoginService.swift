import Foundation
import ServiceManagement

protocol LaunchAtLoginService: Sendable {
    func setEnabled(_ enabled: Bool) throws
    func isEnabled() -> Bool
}

enum LaunchAtLoginError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Wordbook couldn't update the launch-at-login preference for this build."
        }
    }
}

struct LiveLaunchAtLoginService: LaunchAtLoginService, Sendable {
    func setEnabled(_ enabled: Bool) throws {
        let service = SMAppService.mainApp

        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            throw LaunchAtLoginError.unavailable
        }
    }

    func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }
}
