import 'package:flutter/material.dart';
import 'package:kasir/src/screens/customers.dart';
import 'package:kasir/src/screens/sales.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'dashboard.dart';
import 'produk_form_page.dart';
import 'report.dart';

class GudangPage extends StatefulWidget {
  const GudangPage({super.key});

  @override
  State<GudangPage> createState() => _GudangPageState();
}

class _GudangPageState extends State<GudangPage> {
  final supabase = SupabaseService();
  List dataStok = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStok();
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
        title: const Text(
          "Gudang",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.logout),
          )
        ],
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
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), label: "Sparepart"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Pelanggan"),
          BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale), label: "Kasir"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Gudang"),
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
