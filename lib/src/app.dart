// lib/src/app.dart
import 'package:flutter/material.dart';
import 'screens/splash.dart';

class SpareMartApp extends StatelessWidget {
  const SpareMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPAREMART',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003366)),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const SplashScreen(),
    );
  }
}
