import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class ProdukFormPage extends StatefulWidget {
  final Map<String, dynamic>? product; // null = tambah | ada data = edit

  const ProdukFormPage({super.key, this.product});

  @override
  State<ProdukFormPage> createState() => _ProdukFormPageState();
}

class _ProdukFormPageState extends State<ProdukFormPage> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController();

  Uint8List? imageBytes;
  String? imageUrl;

  bool loading = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    // ✅ JIKA MODE EDIT
    if (isEdit) {
      nameCtrl.text = widget.product!['name'] ?? '';
      priceCtrl.text = widget.product!['price'].toString();
      stockCtrl.text = widget.product!['stock'].toString();
      imageUrl = widget.product!['image_url']; // ✅ tampilkan gambar lama
    }
  }

  // ✅ PILIH GAMBAR
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      imageBytes = await file.readAsBytes();
      setState(() {});
    }
  }

  // ✅ SIMPAN / UPDATE PRODUK + UPLOAD GAMBAR
  Future<void> saveProduct() async {
  if (nameCtrl.text.isEmpty ||
      priceCtrl.text.isEmpty ||
      stockCtrl.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Semua data wajib diisi!")),
    );
    return;
  }

  // ✅ WAJIB UPLOAD GAMBAR SAAT TAMBAH
  if (!isEdit && imageBytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gambar produk wajib diupload!")),
    );
    return;
  }

  setState(() => loading = true);

  try {
    // ✅ UPLOAD GAMBAR JIKA ADA
    if (imageBytes != null) {
      final uploadedUrl = await SupabaseService.uploadImage(
        imageBytes!,
        "${DateTime.now().millisecondsSinceEpoch}.png",
      );

      if (uploadedUrl == null) {
        throw Exception("Upload gambar gagal!");
      }

      imageUrl = uploadedUrl; // ✅ DIJAMIN TERISI
    }

    final data = {
      'name': nameCtrl.text,
      'price': double.parse(priceCtrl.text),
      'stock': int.parse(stockCtrl.text),
      'image_url': imageUrl, // ✅ TIDAK AKAN NULL
    };

    if (isEdit) {
      await SupabaseService.updateProduct(widget.product!['id'], data);
    } else {
      await SupabaseService.addProduct(data);
    }

    if (!mounted) return;

    setState(() => loading = false);
    Navigator.pop(context, true);
  } catch (e) {
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gagal menyimpan produk: $e")),
    );
  }
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF074A86),
      elevation: 0,
      title: Row(
        children: [
          Image.asset("images/sparemart_logo.png", height: 40),
          const SizedBox(width: 10),
          Text(
            isEdit ? "Edit Produk" : "Tambah Produk",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ✅ PREVIEW GAMBAR
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.black12),
                image: imageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(imageBytes!),
                        fit: BoxFit.cover,
                      )
                    : imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: imageBytes == null && imageUrl == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 40),
                          SizedBox(height: 8),
                          Text("Tap untuk pilih gambar"),
                        ],
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 25),

          // ✅ INPUT DALAM CARD (BIAR MIRIP PRODUK PAGE)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nama Produk",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: "Harga",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: stockCtrl,
                    decoration: const InputDecoration(
                      labelText: "Stok",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ✅ TOMBOL SIMPAN STYLE DASHBOARD
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: loading ? null : saveProduct,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      isEdit ? "Update Produk" : "Simpan Produk",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
}