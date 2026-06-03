import Foundation
import Testing
@testable import Wordbook

struct PersistenceStoreTests {
    @Test
    func roundTripsSnapshot() {
        let suiteName = "wordbook.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = UserDefaultsPersistenceStore(defaults: defaults, snapshotKey: "snapshot")

        let snapshot = AppSnapshot(
            settings: AppSettings(wordOfDayEnabled: true, dailyNotificationEnabled: true, launchAtLoginEnabled: false),
            history: [
                HistoryItem(
                    entry: DictionaryEntry(
                        word: "example",
                        phonetic: "/example/",
                        phonetics: [],
                        meanings: [],
                        sourceURLs: []
                    ),
                    viewedAt: .now
                )
            ],
            favorites: [],
            cachedWordOfDay: nil
        )

        store.saveSnapshot(snapshot)
        let reloaded = store.loadSnapshot()

        #expect(reloaded.settings == snapshot.settings)
        #expect(reloaded.history.first?.entry.word == "example")
    }
}
