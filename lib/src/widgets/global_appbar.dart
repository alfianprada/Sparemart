import 'package:flutter/material.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String role;
  final VoidCallback? onLogout;
  const GlobalAppBar({super.key, required this.title, required this.role, this.onLogout});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(children: [
        Image.asset('images/logo2.png', height: 30, errorBuilder: (_,__,___) => const SizedBox.shrink()),
        const SizedBox(width: 10),
        Expanded(child: Text(title)),
      ]),
      actions: [
        Center(child: Text('Halo, ${role == 'admin' ? 'Admin' : 'Kasir'}')),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: onLogout ?? () => Navigator.pushReplacementNamed(context, '/'),
        ),
      ],
    );
  }
}
