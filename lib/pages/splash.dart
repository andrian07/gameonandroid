import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gameon/pages/login.dart';
// import 'package:gameon/pages/dashboard.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    startSplash();
  }

  Future<void> startSplash() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090414),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/branding/splashscreen.png",
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
