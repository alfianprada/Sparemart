import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const supabaseUrl =
      'https://lqvdykrjbgdeghoiuuto.supabase.co';
  static const supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxdmR5a3JqYmdkZWdob2l1dXRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyNDI4ODIsImV4cCI6MjA3NjgxODg4Mn0.HrRPqdO-JKwZADhsbwmLM5CNc0XfLddjvPaX5TXMvow';

  static late SupabaseClient client;

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    client = Supabase.instance.client;
  }

  Future<double> getTodaySales() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final response = await client
        .from('transactions')
        .select('total')
        .eq('created_at::date', today);

    double totalSales = 0;
    for (var t in response) {
      totalSales += (t['total'] as num).toDouble();
    }
    return totalSales;
  }

   // Total stok produk
  Future<int> getTotalStock() async {
    final response = await client.from('products').select('stock');
    int total = 0;
    for (var p in response) {
      total += p['stock'] as int;
    }
    return total;
  }

  // Grafik mingguan
  Future<List<double>> getWeeklySales() async {
  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 30));

  // Langsung ambil data 7 hari terakhir dengan SQL filter
  final response = await client
      .from('transactions')
      .select('total, created_at')
      .gte('created_at', sevenDaysAgo.toIso8601String())
      .lte('created_at', now.toIso8601String())
      .order('created_at', ascending: true);

  final data = List<Map<String, dynamic>>.from(response);

  // Buat array untuk 7 hari (Senin - Minggu)
  List<double> dailyTotals = List.filled(7, 0);

  for (var item in data) {
    final createdAt = DateTime.parse(item['created_at']);

    // Normalisasi tanggal (hilangkan jam)
    final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final nowDate = DateTime(now.year, now.month, now.day);

    final difference = nowDate.difference(createdDate).inDays;

    if (difference >= 0 && difference < 7) {
      int index = 6 - difference;
      dailyTotals[index] += (item['total'] as num).toDouble();
    }
  }

  return dailyTotals;
}


  // Transaksi terbaru
  Future<List<Map<String, dynamic>>> getRecentTransactions([int limit = 50]) async {
    try {
    final response = await client
        .from('transactions')
        .select('id, transaction_number, total, discount, payment_method,created_at')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("ERROR getRecentTrannsactions: $e");
      return[];
    }
  }

  // ==============================
  // PELANGGAN
  // ==============================
  static Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final res = await client
          .from('customers') // ✅ pastikan nama tabel ini benar
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print("Error getCustomers: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStokGudang() async {
  final res = await Supabase.instance.client
      .from('products')
      .select('name, stock')
      .order('name');

  return List<Map<String, dynamic>>.from(res);
}

Future<double> getTotalSalesAllTime() async {
  final res = await client.from('transactions').select('total');

  double total = 0;
  for (var item in res) {
    total += (item['total'] as num).toDouble();
  }
  return total;
}

Future<List<Map<String, dynamic>>> getAllTransactions() async {
  final res = await client
      .from('transactions')
      .select('*')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(res);
}



  // ------------------------------
  // LOGIN ASLI SUPABASE AUTH
  // ------------------------------
    Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final uid = res.user!.id;

      final profile = await client
          .from('user_profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (profile == null) {
        print("⚠️ User profile tidak ditemukan");
        return null;
      }

      profile['role'] = (profile['role'] ?? 'kasir').toString();
      return profile;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    await client.auth.signOut();
  }

  // ------------------------------
  // REGISTER USER BARU
  // ------------------------------
  static Future<bool> register(String email, String password, String name) async {
    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
      );

      final uid = res.user!.id;

      await client.from('user_profiles').insert({
        'id': uid,
        'full_name': name,
        'role': 'kasir',
      });

      return true;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final res = await client
          .from('products')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print("Error getProducts: $e");
      return [];
    }
  }

  static Future<bool> addProduct(Map<String, dynamic> data) async {
    try {
      await client.from('products').insert(data);
      return true;
    } catch (e) {
      print("Error addProduct: $e");
      return false;
    }
  }

  static Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      await client.from('products').update(data).eq('id', id);
      return true;
    } catch (e) {
      print("Error updateProduct: $e");
      return false;
    }
  }

  static Future<bool> deleteProduct(int id) async {
    try {
      await client.from('products').delete().eq('id', id);
      return true;
    } catch (e) {
      print("Error deleteProduct: $e");
      return false;
    }
  }

  static Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    try {
      final path = 'products/$fileName'; 

      await client.storage.from('product_images').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final url = client.storage.from('product_images').getPublicUrl(path);
      return url;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  static Future<void> addCustomer(Map<String, dynamic> data) async {
  await Supabase.instance.client.from('customers').insert(data);
}

static Future<void> updateCustomer(int id, Map<String, dynamic> data) async {
  await Supabase.instance.client.from('customers').update(data).eq('id', id);
}

static Future<void> deleteCustomer(int id) async {
  await Supabase.instance.client.from('customers').delete().eq('id', id);
}

}
