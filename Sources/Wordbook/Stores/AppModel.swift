import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var settings: AppSettings
    var history: [HistoryItem]
    var favorites: [FavoriteItem]
    var wordOfDay: WordOfDayEntry?
    var dismissedWordOfDayDateKey: String?
    var selectedEntry: DictionaryEntry?
    var menuSearchResult: DictionaryEntry?
    var isSearching = false
    var errorMessage: String?
    var serviceMessage: String?

    private let persistenceStore: any PersistenceStore
    private let dictionaryService: any DictionaryService
    private let wordOfDayService: any WordOfDayService
    private let launchAtLoginService: any LaunchAtLoginService
    private let notificationService: any NotificationService

    init(
        persistenceStore: any PersistenceStore = UserDefaultsPersistenceStore(),
        dictionaryService: any DictionaryService = LiveDictionaryService(),
        wordOfDayService: (any WordOfDayService)? = nil,
        launchAtLoginService: any LaunchAtLoginService = LiveLaunchAtLoginService(),
        notificationService: any NotificationService = LiveNotificationService()
    ) {
        let snapshot = persistenceStore.loadSnapshot()
        self.persistenceStore = persistenceStore
        self.dictionaryService = dictionaryService
        self.wordOfDayService = wordOfDayService ?? LiveWordOfDayService(dictionaryService: dictionaryService)
        self.launchAtLoginService = launchAtLoginService
        self.notificationService = notificationService
        settings = snapshot.settings
        history = snapshot.history
        favorites = snapshot.favorites
        wordOfDay = snapshot.cachedWordOfDay
        dismissedWordOfDayDateKey = snapshot.dismissedWordOfDayDateKey
        selectedEntry = snapshot.cachedWordOfDay?.entry ?? snapshot.history.first?.entry
    }

    func start() async {
        await refreshWordOfDayIfNeeded()
        await synchronizeServices()
    }

    func search(for rawWord: String) async {
        isSearching = true
        defer { isSearching = false }

        do {
            let entry = try await dictionaryService.lookup(word: rawWord)
            selectedEntry = entry
            menuSearchResult = entry
            errorMessage = nil
            registerHistory(entry)
            persist()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(entry: DictionaryEntry) {
        selectedEntry = entry
        errorMessage = nil
    }

    func isFavorite(_ entry: DictionaryEntry) -> Bool {
        favorites.contains(where: { $0.entry.id == entry.id })
    }

    func toggleFavorite(_ entry: DictionaryEntry) {
        if isFavorite(entry) {
            favorites.removeAll { $0.entry.id == entry.id }
        } else {
            favorites.insert(FavoriteItem(entry: entry, addedAt: .now), at: 0)
        }
        persist()
    }

    func clearHistory() {
        history.removeAll()
        persist()
    }

    func applyWordOfDaySelection() {
        guard let wordOfDay else { return }
        select(entry: wordOfDay.entry)
    }

    func dismissWordOfDayCard() {
        dismissedWordOfDayDateKey = wordOfDay?.dateKey
        persist()
    }

    func clearMenuSearchResult() {
        menuSearchResult = nil
        errorMessage = nil
    }

    func setWordOfDayEnabled(_ enabled: Bool) async {
        settings.wordOfDayEnabled = enabled
        if enabled {
            await refreshWordOfDayIfNeeded(force: true)
        } else {
            wordOfDay = nil
        }
        persist()
    }

    func setDailyNotificationEnabled(_ enabled: Bool) async {
        do {
            if enabled {
                try await notificationService.enableDailyReminder()
            } else {
                await notificationService.disableDailyReminder()
            }
            settings.dailyNotificationEnabled = enabled
            serviceMessage = nil
            persist()
        } catch {
            settings.dailyNotificationEnabled = false
            serviceMessage = error.localizedDescription
            persist()
        }
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            try launchAtLoginService.setEnabled(enabled)
            settings.launchAtLoginEnabled = enabled
            serviceMessage = nil
            persist()
        } catch {
            settings.launchAtLoginEnabled = launchAtLoginService.isEnabled()
            serviceMessage = error.localizedDescription
            persist()
        }
    }

    func refreshWordOfDayIfNeeded(force: Bool = false) async {
        guard settings.wordOfDayEnabled else {
            wordOfDay = nil
            return
        }

        do {
            let nextWord = try await wordOfDayService.currentWord(cached: force ? nil : wordOfDay)
            wordOfDay = nextWord
            if dismissedWordOfDayDateKey != nextWord.dateKey {
                dismissedWordOfDayDateKey = nil
            }
            if selectedEntry == nil {
                selectedEntry = nextWord.entry
            }
            persist()
        } catch {
            if wordOfDay == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func synchronizeServices() async {
        setLaunchAtLoginEnabled(settings.launchAtLoginEnabled)
        if settings.dailyNotificationEnabled {
            await setDailyNotificationEnabled(true)
        } else {
            await notificationService.disableDailyReminder()
        }
    }

    private func registerHistory(_ entry: DictionaryEntry) {
        history.removeAll { $0.entry.id == entry.id }
        history.insert(HistoryItem(entry: entry, viewedAt: .now), at: 0)
        if history.count > 25 {
            history = Array(history.prefix(25))
        }
    }

    private func persist() {
        persistenceStore.saveSnapshot(
            AppSnapshot(
                settings: settings,
                history: history,
                favorites: favorites,
                cachedWordOfDay: wordOfDay,
                dismissedWordOfDayDateKey: dismissedWordOfDayDateKey
            )
        )
    }

    var shouldShowWordOfDayCard: Bool {
        guard settings.wordOfDayEnabled, let wordOfDay else {
            return false
        }

        return dismissedWordOfDayDateKey != wordOfDay.dateKey
    }
}
