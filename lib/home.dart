import 'dart:convert';
import 'dart:io';

import 'package:filmfan/favorites.dart';
import 'package:filmfan/movie.dart';
import 'package:filmfan/services/tmdb_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchMovies(int page) async {
  final apiKey = requireTmdbApiKey();
  final response = await http.get(Uri.parse(
    'https://api.themoviedb.org/3/movie/now_playing?api_key=$apiKey&language=en-US&page=$page',
  ));
  if (response.statusCode != 200) {
    throw HttpException('TMDB returned ${response.statusCode}');
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map) {
    throw const FormatException('Invalid TMDB response');
  }
  final results = decoded['results'] is List ? decoded['results'] as List : [];
  final movies = results
      .whereType<Map>()
      .map(_normalizeMovie)
      .whereType<Map<String, dynamic>>()
      .toList();
  movies.sort((a, b) => (a['title'] as String)
      .toLowerCase()
      .compareTo((b['title'] as String).toLowerCase()));
  return movies;
}

Map<String, dynamic>? _normalizeMovie(Map movie) {
  final id = movie['id'];
  if (id is! num) return null;
  final title = movie['title'];
  final releaseDate = movie['release_date'];
  final voteAverage = movie['vote_average'];
  return {
    'id': id.toInt(),
    'title': title is String && title.isNotEmpty ? title : 'Untitled',
    'poster_path': movie['poster_path'] is String ? movie['poster_path'] : null,
    'release_date': releaseDate is String ? releaseDate : '',
    'vote_average': voteAverage is num ? voteAverage : 0.0,
  };
}

class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _movies = [];
  int _page = 1;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _initialError;
  Object? _loadMoreError;
  int _selectedTab = 0;
  String _query = '';
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    final generation = ++_requestGeneration;
    setState(() {
      _page = 1;
      _movies = [];
      _loadingInitial = true;
      _hasMore = true;
      _initialError = null;
      _loadMoreError = null;
    });
    try {
      final movies = await fetchMovies(1);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _movies = movies;
        _loadingInitial = false;
        _hasMore = movies.isNotEmpty;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadingInitial = false;
        _initialError = error;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 600 ||
        _loadingMore ||
        !_hasMore) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loadingInitial) return;
    final generation = _requestGeneration;
    final distanceFromBottom = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels
        : 0.0;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final nextMovies = await fetchMovies(nextPage);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _page = nextPage;
        _hasMore = nextMovies.isNotEmpty;
        _loadMoreError = null;
        final existingIds = _movies.map((movie) => movie['id']).toSet();
        _movies = [
          ..._movies,
          ...nextMovies.where((movie) => existingIds.add(movie['id'])),
        ];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final position = _scrollController.position;
        final targetOffset =
            (position.maxScrollExtent - distanceFromBottom).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        _scrollController.jumpTo(targetOffset.toDouble());
      });
    } catch (error) {
      if (mounted && generation == _requestGeneration) {
        setState(() => _loadMoreError = error);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openMovie(Map<String, dynamic> movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => Movie(params: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _selectedTab == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(isHome ? widget.title : 'Favorites'),
        actions: [
          if (isHome)
            IconButton(
              tooltip: 'Refresh movies',
              onPressed: _loadMovies,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: isHome ? _buildHomeContent() : Favorites(onMovieTap: _openMovie),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Now playing',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search now-playing movies',
            leading: const Icon(Icons.search),
            trailing: [
              if (_query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.clear),
                ),
            ],
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(child: _buildMovieList()),
      ],
    );
  }

  Widget _buildMovieList() {
    if (_loadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_initialError != null) {
      return _MessageState(
        icon: Icons.cloud_off,
        title: 'Could not load movies',
        message: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: _loadMovies,
      );
    }

    final filtered = _movies
        .where((movie) => (movie['title'] as String)
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
    if (filtered.isEmpty) {
      return _MessageState(
        icon: Icons.search_off,
        title: _query.isEmpty ? 'No movies available' : 'No matches',
        message: _query.isEmpty
            ? 'Try refreshing in a moment.'
            : _hasMore
                ? 'Load another page to continue searching.'
                : 'Try a different movie title.',
        actionLabel: _query.isEmpty
            ? 'Retry'
            : _hasMore
                ? 'Load more results'
                : null,
        onAction: _query.isEmpty
            ? _loadMovies
            : _hasMore
                ? _loadMore
                : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovies,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 600
                  ? 3
                  : 2;
          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.55,
            ),
            itemCount: filtered.length +
                (_loadingMore || _loadMoreError != null ? 1 : 0),
            itemBuilder: (_, index) {
              if (index < filtered.length) {
                return _MovieCard(
                  movie: filtered[index],
                  onTap: () => _openMovie(filtered[index]),
                );
              }
              return _LoadMoreCard(
                error: _loadMoreError != null,
                onRetry: _loadMore,
              );
            },
          );
        },
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie, required this.onTap});

  final Map<String, dynamic> movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final posterPath = movie['poster_path'] as String?;
    return Semantics(
      button: true,
      label: 'Open ${movie['title']}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: posterPath == null
                    ? const _PosterPlaceholder()
                    : Image.network(
                        'https://image.tmdb.org/t/p/w500$posterPath',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _PosterPlaceholder(),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                child: Text(
                  movie['title'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text((movie['vote_average'] as num).toStringAsFixed(1)),
                    const Spacer(),
                    Text(
                      (movie['release_date'] as String).split('-').first,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMoreCard extends StatelessWidget {
  const _LoadMoreCard({required this.error, required this.onRetry});

  final bool error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: error ? onRetry : null,
        child: Center(
          child: error
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off),
                    SizedBox(height: 8),
                    Text('Tap to retry'),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF252533),
      child: Center(
        child: Icon(Icons.movie_outlined, size: 44, color: Colors.white54),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                  onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
