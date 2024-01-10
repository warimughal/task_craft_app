// ignore_for_file: file_names, prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import

import 'dart:async';

import 'package:flutter/material.dart';

import '../on_boarding_screen/on_boarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 4), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => OnBoardingScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Text(
                  "TC",
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
            SizedBox(width: 4),
            Text(
              "TaskCraft",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
