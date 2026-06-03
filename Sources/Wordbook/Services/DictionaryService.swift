import Foundation

protocol DictionaryService: Sendable {
    func lookup(word: String) async throws -> DictionaryEntry
}

enum DictionaryLookupError: LocalizedError, Equatable {
    case emptyQuery
    case invalidQuery
    case notFound
    case offline
    case serverError
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Enter an English word to look it up."
        case .invalidQuery:
            return "Only English words, apostrophes, and hyphens are supported."
        case .notFound:
            return "No dictionary entry was found for that word."
        case .offline:
            return "Wordbook couldn't reach the dictionary service. Check your connection and try again."
        case .serverError:
            return "The dictionary service returned an unexpected error."
        case .unexpectedResponse:
            return "Wordbook couldn't read the dictionary response."
        }
    }
}

struct LiveDictionaryService: DictionaryService, Sendable {
    typealias Fetch = @Sendable (URL) async throws -> (Data, URLResponse)

    private let fetch: Fetch

    init(fetch: @escaping Fetch = { url in
        try await URLSession.shared.data(from: url)
    }) {
        self.fetch = fetch
    }

    func lookup(word: String) async throws -> DictionaryEntry {
        let sanitizedWord = try Self.sanitize(word: word)
        guard let encodedWord = sanitizedWord.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encodedWord)") else {
            throw DictionaryLookupError.invalidQuery
        }

        let (data, response) = try await fetch(url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryLookupError.unexpectedResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 404:
            throw DictionaryLookupError.notFound
        default:
            throw DictionaryLookupError.serverError
        }

        let decoder = JSONDecoder()
        let apiEntries = try decoder.decode([DictionaryAPIEntry].self, from: data)
        return try Self.normalize(entries: apiEntries)
    }

    static func sanitize(word: String) throws -> String {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            throw DictionaryLookupError.emptyQuery
        }

        let pattern = #"^[A-Za-z][A-Za-z'\- ]*$"#
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            throw DictionaryLookupError.invalidQuery
        }

        return trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private static func normalize(entries: [DictionaryAPIEntry]) throws -> DictionaryEntry {
        guard let firstEntry = entries.first else {
            throw DictionaryLookupError.unexpectedResponse
        }

        let phonetic = firstNonEmpty(entries.map(\.phonetic))
        let phonetics = uniquePhonetics(from: entries)
        let meanings = normalizeMeanings(from: entries)
        let sourceURLs = entries
            .flatMap(\.sourceURLs)
            .compactMap(URL.init(string:))
            .uniquedURLs()

        return DictionaryEntry(
            word: firstEntry.word,
            phonetic: phonetic,
            phonetics: phonetics,
            meanings: meanings,
            sourceURLs: sourceURLs
        )
    }

    static func firstNonEmpty(_ candidates: [String?]) -> String? {
        candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { $0.isEmpty == false })
    }

    private static func uniquePhonetics(from entries: [DictionaryAPIEntry]) -> [PhoneticOption] {
        var seen = Set<String>()
        var results: [PhoneticOption] = []

        for entry in entries {
            for phonetic in entry.phonetics {
                let audioURL = phonetic.audio.flatMap(URL.init(string:))
                let option = PhoneticOption(
                    text: phonetic.text?.nilIfBlank,
                    audioURL: audioURL
                )
                let key = option.id
                guard seen.insert(key).inserted else {
                    continue
                }
                guard option.text != nil || option.audioURL != nil else {
                    continue
                }
                results.append(option)
            }
        }

        return results.sorted { lhs, rhs in
            switch (lhs.audioURL != nil, rhs.audioURL != nil) {
            case (true, false):
                return true
            case (false, true):
                return false
            default:
                return (lhs.text ?? "") < (rhs.text ?? "")
            }
        }
    }

    private static func normalizeMeanings(from entries: [DictionaryAPIEntry]) -> [MeaningGroup] {
        Dictionary(grouping: entries.flatMap(\.meanings), by: \.partOfSpeech)
            .map { partOfSpeech, groupedMeanings in
                let definitions = groupedMeanings
                    .flatMap(\.definitions)
                    .map {
                        DefinitionItem(
                            definition: $0.definition,
                            example: $0.example?.nilIfBlank,
                            synonyms: $0.synonyms.uniqued(),
                            antonyms: $0.antonyms.uniqued()
                        )
                    }

                let synonyms = groupedMeanings
                    .flatMap(\.synonyms)
                    .uniqued()

                let antonyms = groupedMeanings
                    .flatMap(\.antonyms)
                    .uniqued()

                return MeaningGroup(
                    partOfSpeech: partOfSpeech.capitalized,
                    definitions: definitions,
                    synonyms: synonyms,
                    antonyms: antonyms
                )
            }
            .sorted { $0.partOfSpeech < $1.partOfSpeech }
    }
}

private struct DictionaryAPIEntry: Decodable {
    let word: String
    let phonetic: String?
    let phonetics: [DictionaryAPIPhonetic]
    let meanings: [DictionaryAPIMeaning]
    let sourceURLs: [String]

    enum CodingKeys: String, CodingKey {
        case word
        case phonetic
        case phonetics
        case meanings
        case sourceURLs = "sourceUrls"
    }
}

private struct DictionaryAPIPhonetic: Decodable {
    let text: String?
    let audio: String?
}

private struct DictionaryAPIMeaning: Decodable {
    let partOfSpeech: String
    let definitions: [DictionaryAPIDefinition]
    let synonyms: [String]
    let antonyms: [String]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        definitions = try container.decode([DictionaryAPIDefinition].self, forKey: .definitions)
        synonyms = try container.decodeIfPresent([String].self, forKey: .synonyms) ?? []
        antonyms = try container.decodeIfPresent([String].self, forKey: .antonyms) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case partOfSpeech
        case definitions
        case synonyms
        case antonyms
    }
}

private struct DictionaryAPIDefinition: Decodable {
    let definition: String
    let example: String?
    let synonyms: [String]
    let antonyms: [String]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        definition = try container.decode(String.self, forKey: .definition)
        example = try container.decodeIfPresent(String.self, forKey: .example)
        synonyms = try container.decodeIfPresent([String].self, forKey: .synonyms) ?? []
        antonyms = try container.decodeIfPresent([String].self, forKey: .antonyms) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case definition
        case example
        case synonyms
        case antonyms
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0.lowercased()).inserted }
    }
}

private extension Array where Element == URL {
    func uniquedURLs() -> [URL] {
        var seen = Set<String>()
        return filter { seen.insert($0.absoluteString).inserted }
    }
}
