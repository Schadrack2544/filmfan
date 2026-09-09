const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

String requireTmdbApiKey() {
  if (tmdbApiKey.isEmpty) {
    throw StateError(
      'TMDB_API_KEY is not configured. Build with '
      '--dart-define=TMDB_API_KEY=your_key.',
    );
  }
  return tmdbApiKey;
}
