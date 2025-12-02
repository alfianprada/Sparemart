import 'package:flutter/material.dart';
import 'package:kasir/src/screens/customers.dart';
import 'package:kasir/src/screens/sales.dart';
import '../services/supabase_service.dart';
import 'dashboard.dart';
import 'produk_form_page.dart';
import 'report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class GudangPage extends StatefulWidget {
  const GudangPage({super.key});

  @override
  State<GudangPage> createState() => _GudangPageState();
}

class _GudangPageState extends State<GudangPage> {
  final supabase = SupabaseService();
  List dataStok = [];
  bool isLoading = true;

  String username = "User";

  @override
  void initState() {
    super.initState();
    loadStok();
    loadUser();
  }

  Future<void> _confirmLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari akun?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      );
    },
  );

  if (result == true) {
    // tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }
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
        username = profile['full_name'] ?? "User";
      });
    }
  }

  Future<void> loadStok() async {
    final result = await supabase.getStokGudang();
    setState(() {
      dataStok = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ======================
      // APPBAR
      // ======================
      appBar: AppBar(
        backgroundColor: const Color(0xFF074A86),
        elevation: 0,
        title: Row(
          children: [
            Image.asset("images/sparemart_logo.png", height: 90),
            const SizedBox(width: 8),
            const Text(
              "Gudang",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              "Halo, $username",
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            IconButton(
  onPressed: () => _confirmLogout(context),
  icon: const Icon(Icons.logout, color: Colors.white),
),
          ],
        ),
      ),

      // ======================
      // BODY
      // ======================
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dataStok.isEmpty
              ? const Center(child: Text("Data stok kosong"))
              : RefreshIndicator(
                  onRefresh: loadStok,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: dataStok.length,
                    itemBuilder: (context, index) {
                      final item = dataStok[index];
                      final nama = item['name'] ?? "-";
                      final stok = item['stock'] ?? 0;

                      return ItemStok(
                        nama: nama,
                        stok: stok,
                      );
                    },
                  ),
                ),

      // ======================
      // BOTTOM NAVBAR
      // ======================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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
                    builder: (_) => const ProdukPage(isAdmin: true)),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PelangganPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TransaksiPage()),
              );
              break;
            case 4:
              return;
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
    );
  }
}

// ==========================
// WIDGET CARD STOK
// ==========================
class ItemStok extends StatelessWidget {
  final String nama;
  final int stok;

  const ItemStok({
    super.key,
    required this.nama,
    required this.stok,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          )
        ],
      ),
      child: Row(
        children: [
          // ICON KUNING
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2),
          ),

          const SizedBox(width: 12),

          // NAMA & STOK
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nama,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text("Stok: $stok"),
            ],
          )
        ],
      ),
    );
  }
}
