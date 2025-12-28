import 'dart:convert';
import 'dart:io';

import 'package:filmfan/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

int page = 1;

Future<List<Map<String, dynamic>>> fetchMovies() async {
  final apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  var moviesData = await http.get(Uri.parse(
      'https://api.themoviedb.org/3/movie/now_playing?api_key=$apiKey&language=en-US&page=$page'));
  List<Map<String, dynamic>> movieslist = [];

  var moviesjson = jsonDecode(moviesData.body)['results'] as List;

  for (var u in moviesjson) {
    Map<String, dynamic> movie = {
      "id": u['id'],
      "title": u['title'],
      "poster_path": u['poster_path'],
      "release_date": u['release_date'],
      "vote_average": u['vote_average'],
    };

    movieslist.add(movie);
  }
  movieslist.sort(
      (a, b) => a['title'].toLowerCase().compareTo(b['title'].toLowerCase()));
  return movieslist;
}

class _HomeState extends State<Home> {
  // Check internet connectivity asynchronously
  Future<bool> hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return FutureBuilder<bool>(
        future: hasNetwork(),
        builder: (context, connectivitySnapshot) {
          // Show loading while checking connectivity
          if (connectivitySnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final isInternetAvailable = connectivitySnapshot.data ?? false;

          return isInternetAvailable
              ? Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    title: Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  body: FutureBuilder<List<Map<String, dynamic>>>(
                      initialData: const [],
                      future: fetchMovies(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ));
                        } else {
                          return ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                var singleMovie = snapshot.data![index];

                                return GestureDetector(
                                  onTap: () {
                                    Map<String, dynamic> singleMovieParams = {
                                      "id": singleMovie['id'],
                                      "title": singleMovie['title']
                                    };
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) => Movie(
                                                params: singleMovieParams)));
                                  },
                                  child: Card(
                                      child: Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      Text("${singleMovie['title']}",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Image.network(
                                        "https://image.tmdb.org/t/p/w500/${singleMovie['poster_path']}",
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                          "Release date: ${singleMovie['release_date']}",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.blue)),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        "Vote average: ${singleMovie['vote_average']}",
                                        style: const TextStyle(
                                            fontSize: 20, color: Colors.grey),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  )),
                                );
                              });
                        }
                      }),
                  bottomNavigationBar: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                          onPressed: page > 1
                              ? () {
                                  setState(() {
                                    page = page - 1;
                                  });
                                }
                              : null,
                          child: const Text("Previous")),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              page = page + 1;
                            });
                          },
                          child: const Text("Next")),
                    ],
                  ),
                )
              : Container(
                  child: const Center(
                      child: Text("No internet connection!",
                          style: TextStyle(
                              decoration: TextDecoration.none, fontSize: 18))));
        },
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
            initialData: const [],
            future: fetchMovies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                  strokeWidth: 3,
                ));
              } else {
                return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var singleMovie = snapshot.data![index];

                      return GestureDetector(
                        onTap: () {
                          Map<String, dynamic> singleMovieParams = {
                            "id": singleMovie['id'],
                            "title": singleMovie['title']
                          };
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  Movie(params: singleMovieParams)));
                        },
                        child: Card(
                            child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Text("${singleMovie['title']}",
                                style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(
                              height: 10,
                            ),
                            Image.network(
                              "https://image.tmdb.org/t/p/w500/${singleMovie['poster_path']}",
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text("Release date: ${singleMovie['release_date']}",
                                style: const TextStyle(
                                    fontSize: 20, color: Colors.blue)),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Vote average: ${singleMovie['vote_average']}",
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.grey),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        )),
                      );
                    });
              }
            }),
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
                onPressed: page > 1
                    ? () {
                        setState(() {
                          page = page - 1;
                        });
                      }
                    : null,
                child: const Text("Previous")),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    page = page + 1;
                  });
                },
                child: const Text("Next")),
          ],
        ),
      );
    }
  }
}
