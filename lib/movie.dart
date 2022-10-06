import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;

class Movie extends StatefulWidget {
  const Movie({Key? key, required this.params}) : super(key: key);
  final Map<String, dynamic> params;
  @override
  State<Movie> createState() => _MovieState();
}

class _MovieState extends State<Movie> {
  double? _ratingValue;

  Future<Map<String, dynamic>> getSingleMovieDetails(id) async {
    var response = await http.get(Uri.parse(
        "https://api.themoviedb.org/3/movie/${id}?api_key=3553ae58190d4f33ec8d93058342b190"));
    var singleMovie = jsonDecode(response.body) as Map<String, dynamic>;
    print("Igerageza :" + singleMovie.toString());
    return singleMovie;
  }

  @override
  Widget build(BuildContext context) {
    // print("Testing here: "+getSingleMovieDetails(widget.id).toString());
    //var movie = getSingleMovieDetails(widget.id);
    var movieId = widget.params['id'];
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.params['title']),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: FutureBuilder<dynamic>(
              future: getSingleMovieDetails(movieId),
              builder: (context, snapshot) {
                if (snapshot.connectionState==ConnectionState.waiting) {
                  return  Center(
                  
                      child: Column(
                        crossAxisAlignment:CrossAxisAlignment.center,
                        mainAxisAlignment:MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                    color: Colors.redAccent,
                    strokeWidth: 6,
                  ),
                        ],
                      ));
                } else {
                  Map<String, dynamic>? movie = snapshot.data;
                  print("hahahaah: ${movie!['genres'][0]['name']}");
                  return Card(
                    color: Colors.amber,
                    child: Column(children: [
                      SizedBox(height: 20),
                      Text(
                        " ${movie['title']}",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Image.network(
                        "https://image.tmdb.org/t/p/w500/" +
                            movie['poster_path'],
                        height: MediaQuery.of(context).size.height * 0.75,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text("Year of release :" + movie['release_date'],
                          textAlign: TextAlign.left),
                      SizedBox(
                        height: 20,
                      ),
                      Text("Genre: " + movie['genres'][0]['name'],
                          textAlign: TextAlign.left),
                      SizedBox(
                        height: 20,
                      ),
                      Text("Rating: " + movie['vote_average'].toString(),
                          textAlign: TextAlign.left),
                      SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: Container(
                          color: Colors.black,
                          width: MediaQuery.of(context).size.width * 0.72,
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                              "Movie overview: \n\n" +
                                  movie['overview'].toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300),
                              textAlign: TextAlign.left),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text("Actors: ", textAlign: TextAlign.left),
                      SizedBox(
                        height: 15,
                      ),
                      Text("You may rate us here"),
                      SizedBox(
                        height: 10,
                      ),
                      RatingBar(
                          initialRating: 0,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          ratingWidget: RatingWidget(
                              full:
                                  const Icon(Icons.star, color: Colors.orange),
                              half: const Icon(
                                Icons.star_half,
                                color: Colors.orange,
                              ),
                              empty: const Icon(
                                Icons.star_outline,
                                color: Colors.orange,
                              )),
                          onRatingUpdate: (value) {
                            setState(() {
                              _ratingValue = value;
                            });
                          }),
                      const SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // http.post(
                          //   Uri.parse(
                          //       "https://api.themoviedb.org/3/movie/${id}?api_key=3553ae58190d4f33ec8d93058342b190"),
                          //       headers:{}
                          // );
                        },
                        child: const Text("Add to favourites"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ]),
                  );
                }
              },
            ),
          ),
        ));
  }
}
