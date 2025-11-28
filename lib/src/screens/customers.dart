import 'package:flutter/material.dart';
import 'package:kasir/src/screens/gudang.dart';
import '../services/supabase_service.dart';
import 'dashboard.dart';
import 'produk_form_page.dart';
import 'sales.dart';
import 'report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PelangganPage extends StatefulWidget {
  const PelangganPage({super.key});

  @override
  State<PelangganPage> createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> {
  List<Map<String, dynamic>> pelanggan = [];
  bool loading = true;

  String username = "Admin";

  @override
  void initState() {
    super.initState();
    loadUser();
    loadPelanggan();
  }

  Future<void> loadUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();

      setState(() {
        username = profile['full_name'] ?? "Admin";
      });
    }
  }

  Future<void> loadPelanggan() async {
    final data = await SupabaseService.getCustomers();
    setState(() {
      pelanggan = data;
      loading = false;
    });
  }

  Color getAvatarColor(int index) {
    final colors = [
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // ✅ FLOATING BUTTON +
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {
          // nanti bisa kamu isi ke form tambah pelanggan
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),

      // ✅ BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProdukPage(isAdmin: true),
                ),
              );
              break;
            case 2:
              return;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TransaksiPage()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GudangPage()),
              );
              break;
            case 5:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ReportPage()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Sparepart"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Pelanggan"),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: "Kasir"),
          BottomNavigationBarItem(icon: Icon(Icons.home_work),label: "Gudang"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Laporan"),
        ],
      ),

      // ✅ APPBAR SESUAI GAMBAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF074A86),
        elevation: 0,
        title: Row(
          children: [
            Image.asset("images/sparemart_logo.png", height: 40),
            const SizedBox(width: 8),
            const Text(
              "Pelanggan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              "Halo, $username",
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            IconButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ],
        ),
      ),

      // ✅ BODY LIST PELANGGAN
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: pelanggan.length,
        itemBuilder: (context, i) {
          final p = pelanggan[i];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // ✅ AVATAR BULAT
                CircleAvatar(
                  radius: 22,
                  backgroundColor: getAvatarColor(i),
                ),

                const SizedBox(width: 12),

                // ✅ NAMA & NO HP
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (p['name'] ?? 'Tanpa Nama').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (p['phone'] ?? '-').toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
