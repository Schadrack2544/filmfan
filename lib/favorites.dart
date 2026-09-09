import 'package:filmfan/services/favorites_store.dart';
import 'package:flutter/material.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key, required this.onMovieTap});

  final ValueChanged<Map<String, dynamic>> onMovieTap;

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  final _store = FavoritesStore();
  late Future<List<Map<String, dynamic>>> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = _store.load();
  }

  Future<void> _reload() async {
    setState(() => _favorites = _store.load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _favorites,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not load favorites. Please try again.'),
          );
        }
        final movies = snapshot.data ?? [];
        if (movies.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Your favorites are empty',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'Save movies from their detail page to find them here.',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final movie = movies[index];
              final poster = movie['poster_path'] as String?;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  onTap: () => widget.onMovieTap(movie),
                  contentPadding: const EdgeInsets.all(8),
                  leading: SizedBox(
                    width: 56,
                    height: 80,
                    child: poster == null
                        ? const _FavoritePlaceholder()
                        : Image.network(
                            'https://image.tmdb.org/t/p/w185$poster',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _FavoritePlaceholder(),
                          ),
                  ),
                  title: Text(movie['title'] as String,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${(movie['release_date'] as String).split('-').first}  •  ${(movie['vote_average'] as num).toStringAsFixed(1)} ★',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove favorite',
                    onPressed: () async {
                      await _store.removeMovie(movie['id'] as int);
                      await _reload();
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FavoritePlaceholder extends StatelessWidget {
  const _FavoritePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF252533),
      child: Icon(Icons.movie_outlined, color: Colors.white54),
    );
  }
}
