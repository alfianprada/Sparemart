import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const BottomNavbar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icons = [Icons.inventory, Icons.receipt_long, Icons.analytics];
    final labels = ['Produk', 'Transaksi', 'Laporan'];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: List.generate(3, (i) {
        final active = currentIndex == i;
        return BottomNavigationBarItem(
          icon: Icon(icons[i], color: active ? Colors.amber : Colors.grey),
          label: labels[i],
        );
      }),
    );
  }
}
