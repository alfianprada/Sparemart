import 'package:flutter/material.dart';
import 'package:kasir/src/screens/customers.dart';
import 'package:kasir/src/screens/gudang.dart';
import 'dashboard.dart';
import 'produk_form_page.dart';
import 'report.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String username = "User";

  double diskonTotal = 0;

  @override
  void initState() {
    super.initState();
    loadProduk();
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
      keranjang.add({
        ...item,
        'qty': 1,
        'diskon': 0.0,
      });
    } else {
      keranjang[index]['qty']++;
    }

    setState(() {});
  }

  double get subtotal {
    double total = 0;
    for (var item in keranjang) {
      double itemTotal =
          item['price'] * item['qty'] * (1 - (item['diskon'] / 100));
      total += itemTotal;
    }
    return total;
  }

  double get totalAkhir {
    return subtotal * (1 - (diskonTotal / 100));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF074A86),
        elevation: 0,
        title: Row(
          children: [
            Image.asset("images/sparemart_logo.png", height: 90),
            const SizedBox(width: 8),
            const Text("Kasir", style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text("Halo, $username",
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
            IconButton(
  onPressed: () => _confirmLogout(context),
  icon: const Icon(Icons.logout, color: Colors.white),
),
          ],
        ),
      ),

      // ✅ NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()));
              break;
            case 1:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProdukPage(isAdmin: true)));
              break;
            case 2:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const PelangganPage()));
              break;
            case 3:
              return;
            case 4:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const GudangPage()));
              break;
            case 5:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ReportPage()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Sparepart"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Pelanggan"),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: "Kasir"),
          BottomNavigationBarItem(icon: Icon(Icons.home_work), label: "Gudang"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Laporan"),
        ],
      ),

      // ✅ BODY SESUAI FIGMA
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // PILIH PELANGGAN
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
                  onPressed: () {},
                  child: const Text("Walk-in"),
                )
              ],
            ),

            const SizedBox(height: 14),

            // PRODUK HORIZONTAL
            SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: produk.length,
                itemBuilder: (context, i) {
                  final p = produk[i];
                  return Container(
                    width: 180,
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
                        Text(p['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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

            // KERANJANG BOX
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Keranjang",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 8),

                  ...keranjang.map((item) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item['name'])),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (item['qty'] > 1) {
                                  setState(() => item['qty']--);
                                }
                              },
                              icon: const Icon(Icons.remove),
                            ),
                            Text("${item['qty']}"),
                            IconButton(
                              onPressed: () {
                                setState(() => item['qty']++);
                              },
                              icon: const Icon(Icons.add),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => keranjang.remove(item));
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),

                  const Divider(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Diskon Total (%)"),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              diskonTotal = double.tryParse(val) ?? 0;
                            });
                          },
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total"),
                      Text("Rp.${totalAkhir.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.bold))
                    ],
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField(
                    value: metodeBayar,
                    items: const [
                      DropdownMenuItem(value: "Cash", child: Text("Cash")),
                      DropdownMenuItem(value: "QRIS", child: Text("QRIS")),
                      DropdownMenuItem(
                          value: "Transfer", child: Text("Transfer")),
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

                  const SizedBox(height: 10),

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
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
