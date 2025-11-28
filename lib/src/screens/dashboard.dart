// lib/src/screens/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:kasir/src/screens/customers.dart';
import 'package:kasir/src/screens/gudang.dart';
import 'package:kasir/src/screens/produk_form_page.dart';
import 'package:kasir/src/screens/report.dart';
import 'package:kasir/src/screens/sales.dart';
import 'package:kasir/src/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final dashboardService = SupabaseService();
  final supabase = Supabase.instance.client;

  String role = "kasir";
  String username = "User";

  double todaySales = 0;
  int totalStock = 0;
  List<double> weeklySales = List.generate(7, (_) => 0.0);
  List<Map<String, dynamic>> recentTrans = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
    loadData();
  }

  Future<void> loadUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final profileRes = await supabase
      .from('user_profiles')
      .select('full_name, role')
      .eq('id', user.id)
      .single();
      if (profileRes != null) {
        final profile = profileRes;
        setState(() {
          role = (profile['role'] ?? 'kasir') as String;
          username = (profile['full_name'] ?? 'User') as String;
        });
      }
    }
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final t = await dashboardService.getTodaySales();
      final s = await dashboardService.getTotalStock();
      final w = await dashboardService.getWeeklySales();
      final r = await dashboardService.getRecentTransactions(5);

      setState(() {
        todaySales = t;
        totalStock = s;
        weeklySales = (w.length == 7) ? w : List.generate(7, (i) => (i < w.length ? w[i] : 0.0));
        recentTrans = r;
      });
    } catch (e) {
      print('loadData error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return role == "admin"
        ? DashboardAdminUI(
            username: username,
            todaySales: todaySales,
            totalStock: totalStock,
            weeklySales: weeklySales,
            recentTrans: recentTrans,
            onRefresh: loadData,
          )
        : DashboardKasirUI(
            username: username,
            todaySales: todaySales,
            totalStock: totalStock,
            weeklySales: weeklySales,
            recentTrans: recentTrans,
            onRefresh: loadData,
          );
  }
}

//////////////////////////////////////////////////////////////////
///                      DASHBOARD ADMIN                       ///
//////////////////////////////////////////////////////////////////
class DashboardAdminUI extends StatelessWidget {
  final String username;
  final double todaySales;
  final int totalStock;
  final List<double> weeklySales;
  final List<Map<String, dynamic>> recentTrans;
  final Future<void> Function() onRefresh;
  void _onNavTap(BuildContext context, int index) {
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
        MaterialPageRoute(builder: (_) => const ProdukPage(isAdmin: true)),
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReportPage()),
      );
      break;
  }
}



  const DashboardAdminUI({
    super.key,
    required this.username,
    required this.todaySales,
    required this.totalStock,
    required this.weeklySales,
    required this.recentTrans,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeader(context, username),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopStats(),
              const SizedBox(height: 20),
              _buildChart(),
              const SizedBox(height: 20),
              _buildRecentTransaction(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (i) => _onNavTap(context, i),
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

  AppBar _buildHeader(BuildContext context, String username) {
    return AppBar(
      backgroundColor: const Color(0xFF074A86),
      elevation: 0,
      title: Row(
        children: [
          Image.asset("images/sparemart_logo.png", height: 42),
          const SizedBox(width: 8),
          const Text("Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text("Halo, $username",
              style: const TextStyle(fontSize: 13, color: Colors.white70)),
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.monetization_on,
            color: Colors.amber.shade700,
            label: "Penjualan Hari Ini",
            value: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(todaySales),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.inventory_2,
            color: Colors.lightBlue,
            label: "Total stok produk",
            value: totalStock.toString(),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,3))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // prepare bars
    final maxVal = weeklySales.reduce((a, b) => a > b ? a : b);
    final safeMax = (maxVal <= 0) ? 100.0 : maxVal * 1.2;

    // Labels Sen..Min
    final labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Grafik Penjualan Mingguan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: safeMax,
                alignment: BarChartAlignment.spaceAround,
                barGroups: List.generate(7, (i) {
                  final value = weeklySales[i];
                  // gaya: biru gelap untuk actual, beri shadow grey tinggi (perbandingan)
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        rodStackItems: [],
                        // warna biru gelap
                        // fl_chart wants Color, so set here
                        color: const Color(0xFF0C2B52),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  );
                }),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(labels[i], style: const TextStyle(fontSize: 12)),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: safeMax / 4),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransaction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text("Daftar Transaksi Terbaru", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...recentTrans.map((t) {
          final created = DateTime.tryParse(t['created_at'] ?? '') ?? DateTime.now();
          final formatted = DateFormat('dd/MM/yyyy HH:mm').format(created);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['transaction_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(formatted, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ]),
                ),
                Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                    .format((t['total'] ?? 0) as num), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

//////////////////////////////////////////////////////////////////
///                      DASHBOARD KASIR                       ///
//////////////////////////////////////////////////////////////////
class DashboardKasirUI extends StatelessWidget {
  final String username;
  final double todaySales;
  final int totalStock;
  final List<double> weeklySales;
  final List<Map<String, dynamic>> recentTrans;
  final Future<void> Function() onRefresh;
  void _onNavTap(BuildContext context, int index) {
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
        MaterialPageRoute(builder: (_) => const ProdukPage(isAdmin: false)),
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
        MaterialPageRoute(builder: (_) => const ReportPage()),
      );
      break;
  }
}



  const DashboardKasirUI({
    super.key,
    required this.username,
    required this.todaySales,
    required this.totalStock,
    required this.weeklySales,
    required this.recentTrans,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: const Color(0xFF074A86),
        actions: [
          Center(child: Text("Halo, $username   ", style: const TextStyle(fontSize: 14, color: Colors.white70))),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _statCardKasir("Penjualan Hari Ini", NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(todaySales)),
              const SizedBox(height: 12),
              _statCardKasir("Total Stok Produk", totalStock.toString()),
              const SizedBox(height: 20),
              _buildChart(),
              const SizedBox(height: 20),
              _buildRecentTransaction(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (i) => _onNavTap(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Sparepart"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Pelanggan"),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: "Kasir"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Laporan"),
        ],
      ),
    );
  }

  Widget _statCardKasir(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.info, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // simple placeholder for kasir (reuse weeklySales optionally)
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Grafik Penjualan Mingguan", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          SizedBox(height: 120, child: Center(child: Text("Lihat tampilan admin untuk grafik detail"))),
        ],
      ),
    );
  }

  Widget _buildRecentTransaction() {
    return Column(
      children: recentTrans.map((t) {
        final created = DateTime.tryParse(t['created_at'] ?? '') ?? DateTime.now();
        final formatted = DateFormat('dd/MM/yyyy HH:mm').format(created);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t['transaction_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)), Text(formatted, style: const TextStyle(fontSize: 12))])),
              Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format((t['total'] ?? 0) as num), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
