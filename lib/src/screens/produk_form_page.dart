import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class ProdukPage extends StatefulWidget {
  final bool isAdmin;
  const ProdukPage({super.key, required this.isAdmin});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  List<Map<String, dynamic>> produk = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await SupabaseService.getProducts();
    setState(() {
      produk = data;
      loading = false;
    });
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
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
              if (bytes != null) {
                imageUrl = await SupabaseService.uploadImage(
                    bytes!, '${DateTime.now().millisecondsSinceEpoch}.png');
              }

              final data = {
                'name': nameCtrl.text,
                'price': double.parse(priceCtrl.text),
                'stock': int.parse(stockCtrl.text),
                'image_url': imageUrl
              };

              if (item == null) {
                await SupabaseService.addProduct(data);
              } else {
                await SupabaseService.updateProduct(item['id'], data);
              }

              if (context.mounted) Navigator.pop(context);
              loadProducts();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteProduct(int id) async {
    await SupabaseService.deleteProduct(id);
    loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Produk"),
        actions: [
          if (widget.isAdmin)
            IconButton(icon: const Icon(Icons.add), onPressed: () => addOrEdit()),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8),
        itemCount: produk.length,
        itemBuilder: (context, i) {
          final p = produk[i];
          return Card(
            child: Column(
              children: [
                Expanded(
                  child: Image.network(p['image_url'] ?? '',
                      width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Rp ${p['price']}'),
                      Text('Stok: ${p['stock']}'),
                      if (widget.isAdmin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => addOrEdit(item: p)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteProduct(p['id'])),
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
