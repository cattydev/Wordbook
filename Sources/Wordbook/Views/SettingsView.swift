import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Section("Daily Learning") {
                Toggle("Enable Word of the Day", isOn: Binding(
                    get: { model.settings.wordOfDayEnabled },
                    set: { newValue in
                        Task {
                            await model.setWordOfDayEnabled(newValue)
                        }
                    }
                ))

                Toggle("Enable Daily Notification", isOn: Binding(
                    get: { model.settings.dailyNotificationEnabled },
                    set: { newValue in
                        Task {
                            await model.setDailyNotificationEnabled(newValue)
                        }
                    }
                ))
                .disabled(model.settings.wordOfDayEnabled == false)
            }

            Section("App Behavior") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { model.settings.launchAtLoginEnabled },
                    set: { newValue in
                        model.setLaunchAtLoginEnabled(newValue)
                    }
                ))
            }

            Section("Library") {
                Button("Clear Search History", role: .destructive) {
                    model.clearHistory()
                }
            }

            if let serviceMessage = model.serviceMessage {
                Section("Status") {
                    Text(serviceMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(width: 460)
    }
}
