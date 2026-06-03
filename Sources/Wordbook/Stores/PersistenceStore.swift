import Foundation

protocol PersistenceStore: Sendable {
    func loadSnapshot() -> AppSnapshot
    func saveSnapshot(_ snapshot: AppSnapshot)
}

struct UserDefaultsPersistenceStore: PersistenceStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let snapshotKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard, snapshotKey: String = "wordbook.snapshot") {
        self.defaults = defaults
        self.snapshotKey = snapshotKey
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadSnapshot() -> AppSnapshot {
        guard let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? decoder.decode(AppSnapshot.self, from: data) else {
            return .default
        }
        return snapshot
    }

    func saveSnapshot(_ snapshot: AppSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }
        defaults.set(data, forKey: snapshotKey)
    }
}
