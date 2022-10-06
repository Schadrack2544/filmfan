import 'dart:convert';

import 'package:filmfan/models/movies.dart';
import 'package:filmfan/movie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

int page = 1;
Future<List<Map<String, dynamic>>> fetchMovies() async {
  var moviesData = await http.get(Uri.parse(
      // 'https://api.themoviedb.org/3/discover/movie/?api_key=3553ae58190d4f33ec8d93058342b190'
      'https://api.themoviedb.org/3/movie/now_playing?api_key=3553ae58190d4f33ec8d93058342b190&language=en-US&page=${page}'));
  List<Map<String, dynamic>> movieslist = [];

  var moviesjson = jsonDecode(moviesData.body)['results'] as List;

  // //Map<String, dynamic> Mj = moviesjson;
  // // print("Tested  data are  ${moviesjson}");
  for (var u in moviesjson) {
    Map<String, dynamic> movie = {
      "id": u['id'],
      "title": u['title'],
      "poster_path": u['poster_path'],
      "release_date": u['release_date'],
      "vote_average": u['vote_average'],
    };
    //   Movies movie = Movies(u['id'], u['title'], u['poster_path'],
    //       u['release_date'], u['vote_average']);

    movieslist.add(movie);
  }
  // // movieslist = movieslist.sort();
  // // print("list of movie is ${movieslist}");
  movieslist.sort(
      (a, b) => a['title'].toLowerCase().compareTo(b['title'].toLowerCase()));
  return movieslist;
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          initialData: [],
          future: fetchMovies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // EasyLoading.show(status: "Loading...");
              return const Center(
                  child: CircularProgressIndicator(
                strokeWidth: 6,
              ));
            } else {
              // EasyLoading.dismiss();
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var singleMovie = snapshot.data![index];
                    // var moviePath = singleMovie.poster_path;

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
                            "https://image.tmdb.org/t/p/w500/" +
                                singleMovie['poster_path'],
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                              "Release date :" +
                                  singleMovie['release_date'].toString(),
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.blue)),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Vote average :" +
                                singleMovie['vote_average'].toString(),
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
              onPressed: () {
                setState(() {
                  page = page - 1;
                });
              },
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
