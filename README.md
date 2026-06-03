# Wordbook

Wordbook is a native macOS English dictionary app built with SwiftUI.

It is designed as a menu-bar-first utility, with a full dictionary window when you want more room to read. The app uses the free [Dictionary API](https://dictionaryapi.dev/) for English word lookups.

## Features

- Menu bar lookup with fast pronunciation playback
- Full word detail view with meanings, examples, synonyms, and antonyms
- Favorites and recents
- Word of the Day
- Native macOS settings and launch-at-login support

## Screenshots

### Menu Bar

![Wordbook menu bar home](docs/screenshots/menu-bar-home.png)

![Wordbook menu bar search results](docs/screenshots/menu-bar-search-results.png)

![Wordbook menu bar favorites](docs/screenshots/menu-bar-favorites.png)

![Wordbook menu bar recents](docs/screenshots/menu-bar-recents.png)

### Windows

![Wordbook settings](docs/screenshots/settings.png)

![Wordbook main window](docs/screenshots/main-window.png)

## Development

Run tests:

```bash
swift test
```

Build and launch the app bundle:

```bash
./script/build_and_run.sh
```

Verify launch:

```bash
./script/build_and_run.sh --verify
```

## Requirements

- macOS on Apple Silicon
- Xcode with Swift 6 toolchain support
