import SwiftUI

struct MenuBarRootView: View {
    private enum PanelView {
        case home
        case favorites
        case recents
    }

    @Bindable var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @State private var query = ""
    @State private var panelView: PanelView = .home

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            panelContent
            footerActions
        }
        .padding(18)
        .frame(width: 420)
        .task {
            await model.start()
        }
    }

    private var header: some View {
        HStack {
            Text("Wordbook")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                openWindow(id: "main")
            } label: {
                Image(systemName: "rectangle.on.rectangle")
            }
            .help("Open Dictionary")
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var panelContent: some View {
        switch panelView {
        case .home:
            homePanel
        case .favorites:
            libraryPanel(
                title: "Favorites",
                emptyTitle: "No Favorites Yet",
                emptyDescription: "Star words you want to keep close.",
                items: model.favorites.map(\.entry)
            )
        case .recents:
            libraryPanel(
                title: "Recents",
                emptyTitle: "No Recent Searches",
                emptyDescription: "Look up a word and it will appear here.",
                items: model.history.map(\.entry)
            )
        }
    }

    private var homePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            searchField

            if let searchResult = model.menuSearchResult {
                quickResult(entry: searchResult)
            } else if model.shouldShowWordOfDayCard, let wordOfDay = model.wordOfDay {
                WordOfDayCardView(wordOfDay: wordOfDay) {
                    model.applyWordOfDaySelection()
                } dismiss: {
                    model.dismissWordOfDayCard()
                }
            }
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Look up an English word", text: $query)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await model.search(for: query)
                        }
                    }

                if query.isEmpty == false || model.menuSearchResult != nil {
                    Button {
                        query = ""
                        model.clearMenuSearchResult()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            if model.isSearching {
                ProgressView()
                    .controlSize(.small)
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func quickResult(entry: DictionaryEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.word)
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(.primary)
                        Text(entry.subtitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        if let audioURL = entry.primaryAudioURL {
                            Button {
                                AudioPlayer.shared.play(url: audioURL)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                            }
                            .help("Play pronunciation")
                        }

                        Button {
                            model.toggleFavorite(entry)
                        } label: {
                            Image(systemName: model.isFavorite(entry) ? "star.fill" : "star")
                        }
                        .help(model.isFavorite(entry) ? "Remove favorite" : "Add favorite")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if entry.phonetics.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(entry.phonetics) { phonetic in
                                phoneticChip(phonetic)
                            }
                        }
                    }
                }

                ForEach(entry.meanings) { meaning in
                    menuMeaningSection(meaning)
                }
            }
            .padding(14)
        }
        .frame(height: 380)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.separator.opacity(0.55), lineWidth: 1)
        }
    }

    private func phoneticChip(_ phonetic: PhoneticOption) -> some View {
        HStack(spacing: 6) {
            if let text = phonetic.text {
                Text(text)
            }

            if let audioURL = phonetic.audioURL {
                Button {
                    AudioPlayer.shared.play(url: audioURL)
                } label: {
                    Image(systemName: "waveform")
                }
                .buttonStyle(.plain)
                .help("Play this pronunciation")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.background, in: Capsule())
        .overlay {
            Capsule().stroke(.separator.opacity(0.5), lineWidth: 1)
        }
    }

    private func menuMeaningSection(_ meaning: MeaningGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meaning.partOfSpeech)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            ForEach(meaning.definitions) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.definition)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let example = item.example {
                        Text("\"\(example)\"")
                            .font(.caption)
                            .italic()
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.separator.opacity(0.35))
                        .frame(height: 1)
                }
            }

            if meaning.synonyms.isEmpty == false {
                compactTags(title: "Synonyms", values: meaning.synonyms, searchable: true)
            }

            if meaning.antonyms.isEmpty == false {
                compactTags(title: "Antonyms", values: meaning.antonyms, searchable: true)
            }
        }
    }

    private func compactTags(title: String, values: [String], searchable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 6, alignment: .leading)], alignment: .leading, spacing: 6) {
                ForEach(values, id: \.self) { value in
                    Button {
                        if searchable {
                            query = value
                            Task {
                                await model.search(for: value)
                            }
                        }
                    } label: {
                        Text(value)
                            .font(.caption)
                            .foregroundStyle(searchable ? AppColors.accent : .secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.background, in: Capsule())
                            .overlay {
                                Capsule().stroke(.separator.opacity(0.45), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(searchable == false)
                    .help("Look up \(value)")
                }
            }
        }
    }

    private func libraryPanel(title: String, emptyTitle: String, emptyDescription: String, items: [DictionaryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            if items.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: title == "Favorites" ? "star" : "clock",
                    description: Text(emptyDescription)
                )
                .frame(height: 160)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(items) { entry in
                            libraryRow(entry)
                        }
                    }
                }
                .frame(maxHeight: 380)
            }
        }
    }

    private func libraryRow(_ entry: DictionaryEntry) -> some View {
        Button {
            query = entry.word
            panelView = .home
            Task {
                await model.search(for: entry.word)
            }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.word)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(entry.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var footerActions: some View {
        HStack {
            Button {
                panelView = .home
            } label: {
                Label("Home", systemImage: "magnifyingglass")
            }
            .labelStyle(.iconOnly)
            .help("Search")
            .foregroundStyle(panelView == .home ? AppColors.accent : .secondary)

            Button {
                panelView = .favorites
            } label: {
                Label("Favorites", systemImage: "star")
            }
            .labelStyle(.iconOnly)
            .help("Favorites")
            .foregroundStyle(panelView == .favorites ? AppColors.accent : .secondary)

            Button {
                panelView = .recents
            } label: {
                Label("Recents", systemImage: "clock")
            }
            .labelStyle(.iconOnly)
            .help("Recents")
            .foregroundStyle(panelView == .recents ? AppColors.accent : .secondary)

            Spacer()

            Menu {
                Button("Open Dictionary") {
                    activateApp()
                    openWindow(id: "main")
                }

                Button("Settings") {
                    activateApp()
                    openSettings()
                }

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .help("More")
        }
        .font(.callout)
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private func activateApp() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
