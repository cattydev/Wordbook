import Foundation

struct DictionaryEntry: Codable, Equatable, Identifiable, Sendable {
    let word: String
    let phonetic: String?
    let phonetics: [PhoneticOption]
    let meanings: [MeaningGroup]
    let sourceURLs: [URL]

    var id: String {
        word.lowercased()
    }

    var primaryAudioURL: URL? {
        phonetics.first(where: { $0.audioURL != nil })?.audioURL
    }

    var subtitle: String {
        let leadingMeaning = meanings.first?.partOfSpeech
        let pronunciation = primaryPhoneticText

        switch (pronunciation, leadingMeaning) {
        case let (.some(pronunciation), .some(leadingMeaning)):
            return "\(pronunciation) • \(leadingMeaning)"
        case let (.some(pronunciation), nil):
            return pronunciation
        case let (nil, .some(leadingMeaning)):
            return leadingMeaning
        default:
            return "English dictionary entry"
        }
    }

    var primaryPhoneticText: String? {
        if let phonetic, phonetic.isEmpty == false {
            return phonetic
        }

        return phonetics.compactMap(\.text).first
    }
}

struct PhoneticOption: Codable, Equatable, Identifiable, Sendable {
    let text: String?
    let audioURL: URL?

    var id: String {
        "\(text ?? "phonetic")|\(audioURL?.absoluteString ?? "none")"
    }
}

struct MeaningGroup: Codable, Equatable, Identifiable, Sendable {
    let partOfSpeech: String
    let definitions: [DefinitionItem]
    let synonyms: [String]
    let antonyms: [String]

    var id: String {
        "\(partOfSpeech)|\(definitions.first?.definition ?? "empty")"
    }
}

struct DefinitionItem: Codable, Equatable, Identifiable, Sendable {
    let definition: String
    let example: String?
    let synonyms: [String]
    let antonyms: [String]

    var id: String {
        "\(definition)|\(example ?? "none")"
    }
}
