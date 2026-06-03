import SwiftUI

struct EntryDetailView: View {
    let entry: DictionaryEntry?
    let isFavorite: Bool
    let onFavoriteToggle: (DictionaryEntry) -> Void
    let onPlayAudio: (URL) -> Void
    let onLookupRelatedWord: (String) -> Void

    var body: some View {
        Group {
            if let entry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        hero(for: entry)

                        ForEach(entry.meanings) { meaning in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(meaning.partOfSpeech)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                ForEach(meaning.definitions) { item in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(item.definition)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)

                                        if let example = item.example {
                                            Text("“\(example)”")
                                                .font(.callout)
                                                .italic()
                                                .foregroundStyle(.secondary)
                                        }

                                        if item.synonyms.isEmpty == false {
                                            tagRow(title: "Synonyms", values: item.synonyms)
                                        }

                                        if item.antonyms.isEmpty == false {
                                            tagRow(title: "Antonyms", values: item.antonyms)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }

                                if meaning.synonyms.isEmpty == false {
                                    tagRow(title: "More related words", values: meaning.synonyms)
                                }

                                if meaning.antonyms.isEmpty == false {
                                    tagRow(title: "Opposites", values: meaning.antonyms)
                                }
                            }
                        }

                        if entry.sourceURLs.isEmpty == false {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Sources")
                                    .font(.headline)

                                ForEach(entry.sourceURLs, id: \.absoluteString) { sourceURL in
                                    Link(sourceURL.absoluteString, destination: sourceURL)
                                        .font(.callout)
                                        .foregroundStyle(AppColors.accent)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(28)
                }
            } else {
                ContentUnavailableView(
                    "Look Up an English Word",
                    systemImage: "text.book.closed",
                    description: Text("Search from the menu bar or the main window to see definitions, examples, and pronunciations.")
                )
            }
        }
        .background(
            LinearGradient(
                colors: [
                    AppColors.warmTint.opacity(0.12),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    @ViewBuilder
    private func hero(for entry: DictionaryEntry) -> some View {
        GlassEffectContainer(spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.word)
                            .font(.system(size: 38, weight: .semibold, design: .serif))
                            .foregroundStyle(.primary)

                        Text(entry.primaryPhoneticText ?? "English pronunciation")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        if let audioURL = entry.primaryAudioURL {
                            Button {
                                onPlayAudio(audioURL)
                            } label: {
                                Label("Play", systemImage: "speaker.wave.2.fill")
                            }
                        }

                        Button {
                            onFavoriteToggle(entry)
                        } label: {
                            Label(isFavorite ? "Favorited" : "Favorite", systemImage: isFavorite ? "star.fill" : "star")
                        }
                    }
                    .labelStyle(.iconOnly)
                }

                if entry.phonetics.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(entry.phonetics) { phonetic in
                                HStack(spacing: 8) {
                                    if let text = phonetic.text {
                                        Text(text)
                                    }
                                    if let audioURL = phonetic.audioURL {
                                        Button {
                                            onPlayAudio(audioURL)
                                        } label: {
                                            Image(systemName: "waveform")
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .font(.callout)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.thinMaterial, in: Capsule())
                                .glassEffect()
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private func tagRow(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            FlowLayout(values: values, onLookup: onLookupRelatedWord)
        }
    }
}

private struct FlowLayout: View {
    let values: [String]
    let onLookup: (String) -> Void

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack {
                wrappedContent
            }
            VStack(alignment: .leading) {
                wrappedContent
            }
        }
    }

    private var wrappedContent: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8, alignment: .leading)], alignment: .leading, spacing: 8) {
            ForEach(values, id: \.self) { value in
                Button {
                    onLookup(value)
                } label: {
                    Text(value)
                        .font(.callout)
                        .foregroundStyle(AppColors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Look up \(value)")
            }
        }
    }
}
