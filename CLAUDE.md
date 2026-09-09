# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Film Fan — a Flutter app that lists now-playing movies (via TMDB) and shows movie details. Small, early-stage codebase (~6 Dart files in `lib/`).

## Commands

```bash
flutter pub get              # install dependencies
flutter run                  # run on a connected device/emulator (or -d chrome/linux/etc.)
flutter analyze              # static analysis (uses analysis_options.yaml / flutter_lints)
flutter test                 # run all tests
flutter test test/widget_test.dart   # run a single test file
flutter build apk|ios|web|linux|windows|macos   # platform builds
```

Note: `test/widget_test.dart` is the default Flutter counter-app smoke test and does not match this app's actual UI (it looks for a "0"/"1" counter that doesn't exist here) — it will fail as-is. If asked to add/fix tests, this file needs to be rewritten against the real widgets, not just patched.

## Configuration

- TMDB API access requires a `TMDB_API_KEY` entry in `.env` at the repo root, loaded via `flutter_dotenv` in `main.dart` before `runApp`. `.env` is declared as a Flutter asset in `pubspec.yaml` and is currently tracked in git — be careful not to leak the key when editing or committing it.

## Architecture

- **Entry flow**: `main.dart` loads `.env`, then boots `SplashScreen` (`lib/utils/splash_screen.dart`). After a fixed 5-second timer, the splash screen replaces itself with `Home` (`lib/home.dart`).
- **Home screen** (`lib/home.dart`): fetches "now playing" movies from the TMDB API (`fetchMovies()`), sorts them client-side by title, and renders them in a `ListView`. Pagination is driven by a module-level `int page` variable (not per-instance state) toggled by Previous/Next buttons via `setState`. On mobile platforms (`defaultTargetPlatform` is Android/iOS) it first checks connectivity via a raw DNS lookup (`InternetAddress.lookup`) and shows a "No internet connection!" message if that fails; desktop/web platforms skip this check and go straight to the movie list. Tapping a movie pushes `Movie` with the movie's `id`/`title`.
- **Movie details** (`lib/movie.dart`): fetches full details for a single movie by id from TMDB (`getSingleMovieDetails`) and renders poster, release date, genre, rating, overview, and a `flutter_rating_bar` star-rating widget. The "Add to favourites" button and rating currently have no wired-up behavior (no persistence, no favorites list).
- **Favorites** (`lib/favorites.dart`): scaffolded but unimplemented (empty `Scaffold`/`Container`) — not yet reachable from any navigation.
- **Model** (`lib/models/movies.dart`): a plain `Movies` data class. It is currently unused — both `home.dart` and `movie.dart` pass raw `Map<String, dynamic>` around instead of using this model.
- **Networking pattern**: both `home.dart` and `movie.dart` call the TMDB REST API directly with `package:http` and `jsonDecode`, each duplicating API-key retrieval from `dotenv.env['TMDB_API_KEY']` and base URL construction — there is no shared API client/service layer yet.
- **Navigation**: plain `Navigator.push`/`pushReplacement` with `MaterialPageRoute`, no named routes or router package.
- **State management**: local `StatefulWidget`/`setState` only; no external state management library.

## Platform targets

Standard Flutter multi-platform scaffolding is present for android, ios, linux, macos, windows, and web — generated boilerplate, not hand-maintained application code. `flutter_launcher_icons` config in `pubspec.yaml` generates app icons from `assets/Filmfan.PNG` across all platforms (`flutter pub run flutter_launcher_icons` to regenerate after changing the source image).
