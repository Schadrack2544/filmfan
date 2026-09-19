import 'package:filmfan/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _movie(int id) => {
      'id': id,
      'title': 'Movie $id',
      'poster_path': null,
      'release_date': '2026-01-01',
      'vote_average': 7.0,
    };

Widget _testApp({
  required MoviePageFetcher moviePageFetcher,
}) {
  return MaterialApp(
    home: Home(
      title: 'Film Fan',
      moviePageFetcher: moviePageFetcher,
    ),
  );
}

void main() {
  testWidgets('loads the next page when the movie grid is scrolled near bottom',
      (tester) async {
    final requestedPages = <int>[];
    final pageOne = List.generate(12, (index) => _movie(index));
    final pageTwo = List.generate(12, (index) => _movie(index + 12));

    await tester.pumpWidget(
      _testApp(
        moviePageFetcher: (page) async {
          requestedPages.add(page);
          return page == 1 ? pageOne : pageTwo;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedPages, [1]);
    expect(find.text('Movie 0'), findsOneWidget);

    await tester.drag(find.byType(GridView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(requestedPages, contains(2));
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.estimatedChildCount, 24);
  });
}
