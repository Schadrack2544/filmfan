import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FavoritesStore {
  static const _key = 'favorite_movies';

  Future<List<Map<String, dynamic>>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_key) ?? <String>[];
    final movies = <Map<String, dynamic>>[];
    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is! Map || decoded['id'] is! num) continue;
        movies.add({
          'id': (decoded['id'] as num).toInt(),
          'title': decoded['title'] is String ? decoded['title'] : 'Untitled',
          'poster_path':
              decoded['poster_path'] is String ? decoded['poster_path'] : null,
          'release_date':
              decoded['release_date'] is String ? decoded['release_date'] : '',
          'vote_average':
              decoded['vote_average'] is num ? decoded['vote_average'] : 0.0,
        });
      } on FormatException {
        continue;
      }
    }
    return movies;
  }

  Future<void> saveMovie(Map<String, dynamic> movie) async {
    final movies = await load();
    movies.removeWhere((item) => item['id'] == movie['id']);
    movies.add(movie);
    await _save(movies);
  }

  Future<void> removeMovie(int id) async {
    final movies = await load();
    movies.removeWhere((movie) => movie['id'] == id);
    await _save(movies);
  }

  Future<bool> contains(int id) async {
    final movies = await load();
    return movies.any((movie) => movie['id'] == id);
  }

  Future<void> _save(List<Map<String, dynamic>> movies) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key,
      movies.map(jsonEncode).toList(),
    );
  }
}
