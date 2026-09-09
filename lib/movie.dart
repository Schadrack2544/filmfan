import 'dart:convert';

import 'package:filmfan/services/favorites_store.dart';
import 'package:filmfan/services/tmdb_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;

class Movie extends StatefulWidget {
  const Movie({super.key, required this.params});

  final Map<String, dynamic> params;

  @override
  State<Movie> createState() => _MovieState();
}

class _MovieState extends State<Movie> {
  final _favorites = FavoritesStore();
  late Future<Map<String, dynamic>> _details;
  bool _isFavorite = false;
  bool _favoriteBusy = false;
  double _rating = 0;

  @override
  void initState() {
    super.initState();
    final id = _movieId(widget.params);
    _details = _loadDetails(id);
    _loadFavorite(id);
  }

  Future<Map<String, dynamic>> _loadDetails(int id) async {
    final apiKey = requireTmdbApiKey();
    final response = await http.get(
      Uri.parse('https://api.themoviedb.org/3/movie/$id?api_key=$apiKey'),
    );
    if (response.statusCode != 200) {
      throw Exception('Movie details unavailable (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid TMDB response');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _loadFavorite(int id) async {
    try {
      final favorite = await _favorites.contains(id);
      if (mounted) setState(() => _isFavorite = favorite);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load favorites.')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> movie) async {
    if (_favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    try {
      if (_isFavorite) {
        await _favorites.removeMovie(_movieId(movie));
      } else {
        await _favorites.saveMovie({
          'id': movie['id'],
          'title': movie['title'] ?? widget.params['title'],
          'poster_path': movie['poster_path'],
          'release_date': movie['release_date'] ?? '',
          'vote_average': movie['vote_average'] ?? 0,
        });
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update favorites.')),
        );
      }
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.params['title'] as String),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Remove favorite' : 'Add favorite',
            onPressed: _favoriteBusy
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final movie = await _details;
                      await _toggleFavorite(movie);
                    } catch (_) {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Movie details are unavailable.')),
                        );
                      }
                    }
                  },
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text('Could not load movie details.'),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => setState(() {
                        _details = _loadDetails(_movieId(widget.params));
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildDetails(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Map<String, dynamic> movie) {
    final posterPath =
        movie['poster_path'] is String ? movie['poster_path'] as String : null;
    final genres =
        (movie['genres'] is List ? movie['genres'] as List : const [])
            .whereType<Map>()
            .map((genre) => genre['name'])
            .whereType<String>()
            .toList();
    final voteAverage = movie['vote_average'];
    final rating = voteAverage is num ? voteAverage.toStringAsFixed(1) : '—';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: posterPath == null
                  ? const SizedBox(
                      height: 360,
                      width: 240,
                      child: _DetailsPlaceholder(),
                    )
                  : Image.network(
                      'https://image.tmdb.org/t/p/w500$posterPath',
                      height: 420,
                      width: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          height: 360, child: _DetailsPlaceholder()),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(movie['title'] is String ? movie['title'] as String : 'Untitled',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                Icons.calendar_today,
                movie['release_date'] is String &&
                        (movie['release_date'] as String).isNotEmpty
                    ? movie['release_date'] as String
                    : 'Unknown',
              ),
              _InfoChip(Icons.star, '$rating / 10'),
              ...genres.map((genre) => _InfoChip(Icons.local_movies, genre)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Overview', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(movie['overview'] is String &&
                  (movie['overview'] as String).isNotEmpty
              ? movie['overview'] as String
              : 'No overview available.'),
          const SizedBox(height: 28),
          Text('Your rating', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 0.5,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 34,
            itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _favoriteBusy ? null : () => _toggleFavorite(movie),
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              label:
                  Text(_isFavorite ? 'Saved to favorites' : 'Add to favorites'),
            ),
          ),
        ],
      ),
    );
  }

  int _movieId(Map<String, dynamic> movie) {
    final id = movie['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    throw const FormatException('Movie is missing a valid id');
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(label));
  }
}

class _DetailsPlaceholder extends StatelessWidget {
  const _DetailsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF252533),
      child: Center(child: Icon(Icons.movie_outlined, size: 60)),
    );
  }
}
