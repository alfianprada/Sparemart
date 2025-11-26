import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/stat_card.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  // dummy data for now
  List<int> get weekly => [50, 80, 70, 120, 90, 60, 150];

  static String fmtNum(num v) {
    final s = v.toStringAsFixed(0);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }

  @override
  Widget build(BuildContext context) {
    final today = weekly.last * 1000;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 100,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            const SizedBox(width: 8),
            SizedBox(width: 260, child: StatCard(title: 'Penjualan Hari Ini', value: 'Rp ${fmtNum(today)}', icon: Icons.attach_money, color: Colors.amber)),
            const SizedBox(width: 12),
            SizedBox(width: 220, child: StatCard(title: 'Total Stok Produk', value: '375', icon: Icons.inventory, color: Colors.lightBlue)),
            const SizedBox(width: 12),
            SizedBox(width: 220, child: StatCard(title: 'Pelanggan Aktif', value: '42', icon: Icons.people, color: Colors.black87)),
            const SizedBox(width: 8),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Grafik Penjualan Mingguan', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(height: 200, child: Card(child: Padding(padding: const EdgeInsets.all(12.0), child: BarChart(_barData(weekly))))),
        const SizedBox(height: 16),
        const Text('Daftar Transaksi Terbaru', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(5, (i) => Card(child: ListTile(leading: const Icon(Icons.receipt_long), title: Text('TRX${1000+i}'), subtitle: Text('Walk-in • 12/10 09:3${i}'), trailing: Text('Rp ${ (i+1)*15000 }')))),
      ]),
    );
  }

  BarChartData _barData(List<int> weekly) {
    final maxY = (weekly.reduce((a,b)=>a>b?a:b).toDouble()*1.2).ceilToDouble();
    return BarChartData(
      maxY: maxY <= 0 ? 10 : maxY,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,meta) {
          const days=['Sen','Sel','Rab','Kam','Jum','Sab','Min'];
          final i=v.toInt().clamp(0,6);
          return Text(days[i], style: const TextStyle(fontSize: 12));
        }, reservedSize: 28)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: true),
      barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: weekly[i].toDouble(), width: 14, color: Colors.blue.shade900)])),
    );
  }
}
