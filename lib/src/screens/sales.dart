import 'package:flutter/material.dart';
import 'package:kasir/src/screens/customers.dart';
import 'package:kasir/src/screens/gudang.dart';
import 'dashboard.dart';
import 'produk_form_page.dart';
import 'report.dart';
import '../services/supabase_service.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  List<Map<String, dynamic>> produk = [];
  List<Map<String, dynamic>> keranjang = [];

  bool loading = true;

  String selectedCustomer = "Walk-in";
  String metodeBayar = "Cash";

  @override
  void initState() {
    super.initState();
    loadProduk();
  }

  Future<void> loadProduk() async {
    final data = await SupabaseService.getProducts();
    setState(() {
      produk = data;
      loading = false;
    });
  }

  void tambahKeKeranjang(Map<String, dynamic> item) {
    int index = keranjang.indexWhere((e) => e['id'] == item['id']);

    if (index == -1) {
      keranjang.add({...item, 'qty': 1});
    } else {
      keranjang[index]['qty']++;
    }

    setState(() {});
  }

  double get subtotal {
    double total = 0;
    for (var item in keranjang) {
      total += (item['price'] * item['qty']);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // ✅ APPBAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF074A86),
        title: const Text("Kasir", style: TextStyle(fontWeight: FontWeight.bold)),
      ),

      // ✅ BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
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
              return;
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

      // ✅ BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // PILIH PELANGGAN
            // =========================
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedCustomer,
                    items: const [
                      DropdownMenuItem(value: "Walk-in", child: Text("Walk-in")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selectedCustomer = val.toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Pilih Pelanggan",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                  ),
                  onPressed: () {},
                  child: const Text("Walk-in"),
                )
              ],
            ),

            const SizedBox(height: 14),

            // =========================
            // GRID PRODUK
            // =========================
            SizedBox(
              height: 320,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: produk.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, i) {
                  final p = produk[i];
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
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
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            p['image_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Rp.${p['price']}"),
                        const SizedBox(height: 6),
                        ElevatedButton(
                          onPressed: () => tambahKeKeranjang(p),
                          child: const Text("Tambah"),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // KERANJANG
            // =========================
            const Text(
              "Keranjang",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...keranjang.map((item) {
              return ListTile(
                title: Text(item['name']),
                subtitle: Text(
                    "Rp.${item['price']} x ${item['qty']}"),
                trailing: Text(
                  "Rp.${item['price'] * item['qty']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),

            const Divider(),

            // =========================
            // TOTAL & PEMBAYARAN
            // =========================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal"),
                Text("Rp.${subtotal.toStringAsFixed(0)}"),
              ],
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField(
              value: metodeBayar,
              items: const [
                DropdownMenuItem(value: "Cash", child: Text("Cash")),
                DropdownMenuItem(value: "QRIS", child: Text("QRIS")),
                DropdownMenuItem(value: "Transfer", child: Text("Transfer")),
              ],
              onChanged: (val) {
                setState(() {
                  metodeBayar = val.toString();
                });
              },
              decoration: const InputDecoration(
                labelText: "Metode Pembayaran",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: () {},
                child: const Text(
                  "Bayar",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
