import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var wordOfDayEnabled: Bool = true
    var dailyNotificationEnabled: Bool = false
    var launchAtLoginEnabled: Bool = true
}

struct HistoryItem: Codable, Equatable, Identifiable, Sendable {
    let entry: DictionaryEntry
    let viewedAt: Date

    var id: String {
        entry.id
    }
}

struct FavoriteItem: Codable, Equatable, Identifiable, Sendable {
    let entry: DictionaryEntry
    let addedAt: Date

    var id: String {
        entry.id
    }
}

struct WordOfDayEntry: Codable, Equatable, Sendable {
    let dateKey: String
    let entry: DictionaryEntry
}

struct AppSnapshot: Codable, Equatable, Sendable {
    var settings: AppSettings
    var history: [HistoryItem]
    var favorites: [FavoriteItem]
    var cachedWordOfDay: WordOfDayEntry?
    var dismissedWordOfDayDateKey: String?

    static let `default` = AppSnapshot(
        settings: AppSettings(),
        history: [],
        favorites: [],
        cachedWordOfDay: nil,
        dismissedWordOfDayDateKey: nil
    )
}

enum SidebarDestination: Hashable, Sendable {
    case wordOfDay
    case history(String)
    case favorite(String)
}
