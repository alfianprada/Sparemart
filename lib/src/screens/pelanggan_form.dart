import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class PelangganFormPage extends StatefulWidget {
  final Map<String, dynamic>? pelanggan; // null = tambah | ada data = edit

  const PelangganFormPage({super.key, this.pelanggan});

  @override
  State<PelangganFormPage> createState() => _PelangganFormPageState();
}

class _PelangganFormPageState extends State<PelangganFormPage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  bool loading = false;

  bool get isEdit => widget.pelanggan != null;

  @override
  void initState() {
    super.initState();

    // ✅ MODE EDIT
    if (isEdit) {
      nameCtrl.text = widget.pelanggan!['name'] ?? '';
      phoneCtrl.text = widget.pelanggan!['phone'] ?? '';
      addressCtrl.text = widget.pelanggan!['address'] ?? '';
    }
  }

  void showError(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Validasi Gagal"),
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


  Future<void> saveCustomer() async {
  final name = nameCtrl.text.trim();
  final phone = phoneCtrl.text.trim();
  final address = addressCtrl.text.trim();

  if (name.isEmpty) {
    showError("Nama wajib diisi!");
    return;
  }

  // ✅ VALIDASI NO TELEPON MINIMAL 10 DIGIT
  if (phone.isEmpty) {
    showError("No. Telepon wajib diisi!");
    return;
  }

  if (phone.length < 10) {
    showError("No. Telepon minimal 10 digit!");
    return;
  }

  setState(() => loading = true);

  final data = {
    'name': name,
    'phone': phone,
    'address': address,
  };

  try {
    if (isEdit) {
      await SupabaseService.updateCustomer(widget.pelanggan!['id'], data);
    } else {
      await SupabaseService.addCustomer(data);
    }

    if (!mounted) return;
    Navigator.pop(context, true); // ✅ auto refresh
  } catch (e) {
    showError("Gagal menyimpan pelanggan: $e");
  }

  setState(() => loading = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Pelanggan" : "Tambah Pelanggan"),
        backgroundColor: const Color(0xFF074A86),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            const SizedBox(height: 10),
            TextField(
  controller: phoneCtrl,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(labelText: "No HP"),
),
            const SizedBox(height: 10),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: "Alamat"),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : saveCustomer,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? "Update" : "Simpan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
