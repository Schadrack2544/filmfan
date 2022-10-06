import 'dart:async';

import 'package:filmfan/home.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
        const Duration(seconds: 5),
        () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: ((context) => const Home(title: 'Film Fan')))));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        child:  Center(
            child: Column(
              mainAxisAlignment:MainAxisAlignment.center,
              children: [
                const Text(
          "Film Fan",
          style: TextStyle(color: Colors.redAccent,fontSize:24,decoration:TextDecoration.none ),
        ),
        SizedBox(height:30,),
        const CircularProgressIndicator(strokeWidth: 4,)
              ],
            )));
  }
}
