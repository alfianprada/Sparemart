import 'package:flutter/material.dart';
import 'package:kasir/src/screens/customers.dart';
import 'package:kasir/src/screens/dashboard.dart';
import 'package:kasir/src/screens/gudang.dart';
import 'package:kasir/src/screens/produk_form_page.dart';
import 'package:kasir/src/screens/sales.dart';
import '../services/supabase_service.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final supabase = SupabaseService();
  List laporan = [];
  double totalPendapatan = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLaporan();
  }

  Future<void> loadLaporan() async {
    final data = await supabase.getRecentTransactions();

    double total = 0;
    for (var item in data) {
      final nilai = item['total'];
      if (nilai != null) {
        total += (nilai as num).toDouble();
      }
    }

    setState(() {
      laporan = data;
      totalPendapatan = total;
      isLoading = false;
    });
  }

  // ============================
  // EXPORT PDF
  // ============================
  Future<void> exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "LAPORAN PENJUALAN",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                "Tanggal Cetak: ${DateTime.now().toString().substring(0, 10)}",
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Text(
                  "Total Pendapatan: Rp ${totalPendapatan.toStringAsFixed(0)}",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: ["No", "No Transaksi", "Tanggal", "Total", "Metode"],
                data: List.generate(laporan.length, (index) {
                  final trx = laporan[index];
                  return [
                    (index + 1).toString(),
                    trx['transaction_number'] ?? "-",
                    trx['created_at'].toString().substring(0, 10),
                    "Rp ${trx['total']}",
                    trx['payment_method'] ?? "-"
                  ];
                }),
              ),
              pw.Spacer(),
              pw.Text(
                "Dicetak dari Aplikasi Kasir",
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ======================
      // APPBAR (SAMA SEPERTI GUDANG)
      // ======================
      appBar: AppBar(
        backgroundColor: const Color(0xFF074A86),
        title: const Text(
          "Laporan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
          )
        ],
      ),

      // ======================
      // BODY (SAMA STRUKTUR GUDANG)
      // ======================
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : laporan.isEmpty
              ? const Center(child: Text("Belum ada transaksi"))
              : RefreshIndicator(
                  onRefresh: loadLaporan,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: laporan.length + 1,
                    itemBuilder: (context, index) {
                      // CARD TOTAL DI ATAS
                      if (index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                              const Text("Total Pendapatan"),
                              const SizedBox(height: 6),
                              Text(
                                "Rp ${totalPendapatan.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final trx = laporan[index - 1];
                      final tanggal = trx['created_at']
                          .toString()
                          .substring(0, 10);

                      return ItemLaporan(
                        nomor: trx['transaction_number'] ?? "-",
                        total: trx['total'] ?? 0,
                        metode: trx['payment_method'] ?? "-",
                        tanggal: tanggal,
                      );
                    },
                  ),
                ),

      // ======================
      // BOTTOM NAVBAR (WARNA ORANGE AKTIF)
      // ======================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 5, // ✅ AKTIF DI LAPORAN
        selectedItemColor: Colors.amber, // ✅ ORANGE
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GudangPage()),
              );
              break;
            case 5:
              return;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), label: "Sparepart"),
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: "Pelanggan"),
          BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale), label: "Kasir"),
          BottomNavigationBarItem(
              icon: Icon(Icons.store), label: "Gudang"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt), label: "Laporan"),
        ],
      ),
    );
  }
}

// ==========================
// CARD LAPORAN (SAMA MODEL GUDANG)
// ==========================
class ItemLaporan extends StatelessWidget {
  final String nomor;
  final String tanggal;
  final int total;
  final String metode;

  const ItemLaporan({
    super.key,
    required this.nomor,
    required this.tanggal,
    required this.total,
    required this.metode,
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
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Rp $total",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text("$nomor | $tanggal"),
              Text("Metode: $metode"),
            ],
          )
        ],
      ),
    );
  }
}
