import 'package:flutter/material.dart';
import 'package:kasir/src/screens/customers.dart';
import 'package:kasir/src/screens/dashboard.dart';
import 'package:kasir/src/screens/login.dart';
import 'package:kasir/src/screens/produk_form_page.dart';
import 'package:kasir/src/screens/report.dart';
import 'package:kasir/src/screens/sales.dart';
import 'package:kasir/src/screens/splash.dart';
import 'src/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const KasirApp());
}

class KasirApp extends StatelessWidget {
  const KasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpareMart Kasir',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade100,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false
    );
  }
}
