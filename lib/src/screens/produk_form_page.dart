import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasir/src/screens/customers.dart';
import 'package:kasir/src/screens/dashboard.dart';
import 'package:kasir/src/screens/gudang.dart';
import 'package:kasir/src/screens/produk_input.dart';
import 'package:kasir/src/screens/report.dart';
import 'package:kasir/src/screens/sales.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProdukPage extends StatefulWidget {
  final bool isAdmin;
  const ProdukPage({super.key, required this.isAdmin});

  @override
  State<ProdukPage> createState() => _ProdukPageState();

}

class _ProdukPageState extends State<ProdukPage> {
  List<Map<String, dynamic>> produk = [];
  bool loading = true;


  String username = "User";

  @override
  void initState() {
    super.initState();
    loadProducts();
    loadUser();

  }

  void showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Terjadi Kesalahan"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
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

    try {
  await Supabase.instance.client.auth.signOut();
} catch (e) {
  Navigator.pop(context);
  showErrorDialog("Logout gagal:\n$e");
  return;
}


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

  Future<void> loadProducts() async {
  try {
    final data = await SupabaseService.getProducts();
    setState(() {
      produk = data;
      loading = false;
    });
  } catch (e) {
    loading = false;
    showErrorDialog("Gagal memuat data produk:\n$e");
  }
}


  Future<void> addOrEdit({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final priceCtrl = TextEditingController(text: item?['price']?.toString() ?? '');
    final stockCtrl = TextEditingController(text: item?['stock']?.toString() ?? '');
    Uint8List? bytes;
    String? imageUrl = item?['image_url'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Tambah Produk' : 'Edit Produk'),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')),
            TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final file = await picker.pickImage(source: ImageSource.gallery);
                if (file != null) bytes = await file.readAsBytes();
              },
              child: const Text("Pilih Gambar"),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
  onPressed: () async {
    try {
      if (nameCtrl.text.isEmpty) {
        showErrorDialog("Nama produk wajib diisi!");
        return;
      }

      if (priceCtrl.text.isEmpty) {
        showErrorDialog("Harga produk wajib diisi!");
        return;
      }

      if (stockCtrl.text.isEmpty) {
        showErrorDialog("Stok produk wajib diisi!");
        return;
      }

      if (item == null && bytes == null) {
        showErrorDialog("Gambar produk wajib diupload!");
        return;
      }

      if (bytes != null) {
        imageUrl = await SupabaseService.uploadImage(
          bytes!,
          '${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }

      final data = {
        'name': nameCtrl.text,
        'price': double.parse(priceCtrl.text),
        'stock': int.parse(stockCtrl.text),
        'image_url': imageUrl,
      };

      if (item == null) {
        await SupabaseService.addProduct(data);
      } else {
        await SupabaseService.updateProduct(item['id'], data);
      }

      if (!mounted) return;
      Navigator.pop(context);
      loadProducts();
    } catch (e) {
      showErrorDialog("Gagal menyimpan produk:\n$e");
    }
  },
  child: const Text("Simpan"),
),

        ],
      ),
    );
  }

  Future<void> deleteProductConfirm(int id) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Hapus Produk"),
      content: const Text("Yakin ingin menghapus produk ini?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Hapus"),
        ),
      ],
    ),
  );

  if (result == true) {
  try {
    await SupabaseService.deleteProduct(id);
    loadProducts();
  } catch (e) {
    showErrorDialog("Gagal menghapus produk:\n$e");
  }
}

}

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
      selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                );
                break;
              case 1:
                return;
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

      appBar: AppBar(
        backgroundColor: const Color(0xFF074A86),
      elevation: 0,
      title: Row(
        children: [
          Image.asset("images/sparemart_logo.png", height: 90),
          const SizedBox(width: 8),
          const Text("Sparepart",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text("Halo, $username",
              style: const TextStyle(fontSize: 13, color: Colors.white70)),
          IconButton(
  onPressed: () => _confirmLogout(context),
  icon: const Icon(Icons.logout),
),
        ],
      ),
      ),
      floatingActionButton: widget.isAdmin
      ? FloatingActionButton(
        backgroundColor: Colors.amberAccent,
            onPressed: () async {
  final result = await Navigator.pushNamed(context, '/produk-form');
  if (result == true) {
    loadProducts(); // ✅ AUTO REFRESH SETELAH TAMBAH
  }
          },
          child: const Icon(Icons.add),
        )
      : null,
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: produk.length,
        itemBuilder: (context, i) {
          final p = produk[i];

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ GAMBAR PRODUK DARI SUPABASE STORAGE
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    p['image_url'] ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 40),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'stok: ${p['stock']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Rp.${p['price']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),

                      if (widget.isAdmin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProdukFormPage(product: p),
                                ),
                              );

                              if (result == true) {
                                loadProducts(); // ✅ auto refresh
                              }
                            },

                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => deleteProductConfirm(p['id']),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
