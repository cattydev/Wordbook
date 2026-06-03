import SwiftUI

struct MainWindowView: View {
    @Bindable var model: AppModel
    @State private var selection: SidebarDestination?
    @State private var sidebarQuery = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if model.settings.wordOfDayEnabled, model.wordOfDay != nil {
                    Section("Today") {
                        Label("Word of the Day", systemImage: "sun.max")
                            .tag(SidebarDestination.wordOfDay)
                    }
                }

                if model.favorites.isEmpty == false {
                    Section("Favorites") {
                        ForEach(model.favorites) { favorite in
                            entryRow(entry: favorite.entry)
                                .tag(SidebarDestination.favorite(favorite.entry.id))
                        }
                    }
                }

                if model.history.isEmpty == false {
                    Section("Recent") {
                        ForEach(model.history) { item in
                            entryRow(entry: item.entry)
                                .tag(SidebarDestination.history(item.entry.id))
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Library")
        } detail: {
            EntryDetailView(
                entry: model.selectedEntry ?? model.wordOfDay?.entry,
                isFavorite: model.selectedEntry.map(model.isFavorite) ?? false,
                onFavoriteToggle: { model.toggleFavorite($0) },
                onPlayAudio: { AudioPlayer.shared.play(url: $0) },
                onLookupRelatedWord: { word in
                    sidebarQuery = word
                    Task {
                        await model.search(for: word)
                    }
                }
            )
            .navigationTitle(model.selectedEntry?.word ?? "Dictionary")
        }
        .searchable(text: $sidebarQuery, prompt: "Look up an English word")
        .onSubmit(of: .search) {
            Task {
                await model.search(for: sidebarQuery)
            }
        }
        .onChange(of: selection) { _, newValue in
            apply(selection: newValue)
        }
        .toolbar {
            ToolbarItemGroup {
                if let selectedEntry = model.selectedEntry {
                    Button {
                        model.toggleFavorite(selectedEntry)
                    } label: {
                        Label(
                            model.isFavorite(selectedEntry) ? "Remove Favorite" : "Add Favorite",
                            systemImage: model.isFavorite(selectedEntry) ? "star.fill" : "star"
                        )
                    }
                }

                Button {
                    Task {
                        await model.refreshWordOfDayIfNeeded(force: true)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .task {
            await model.start()
            syncSelectionFromModel()
        }
    }

    private func entryRow(entry: DictionaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.word)
                .font(.body.weight(.medium))
            Text(entry.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func apply(selection: SidebarDestination?) {
        guard let selection else {
            return
        }

        switch selection {
        case .wordOfDay:
            model.applyWordOfDaySelection()
        case let .favorite(id):
            if let entry = model.favorites.first(where: { $0.entry.id == id })?.entry {
                model.select(entry: entry)
            }
        case let .history(id):
            if let entry = model.history.first(where: { $0.entry.id == id })?.entry {
                model.select(entry: entry)
            }
        }
    }

    private func syncSelectionFromModel() {
        if let selectedEntry = model.selectedEntry {
            if model.favorites.contains(where: { $0.entry.id == selectedEntry.id }) {
                selection = .favorite(selectedEntry.id)
            } else if model.history.contains(where: { $0.entry.id == selectedEntry.id }) {
                selection = .history(selectedEntry.id)
            }
        } else if model.wordOfDay != nil {
            selection = .wordOfDay
        }
    }
}
