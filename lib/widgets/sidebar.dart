import 'package:flutter/material.dart';
import 'dart:io';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTap;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onItemTap,
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_shopping_cart_outlined),
                selectedIcon: Icon(Icons.add_shopping_cart),
                label: Text('Penjualan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Daftar Barang'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('History'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Analitik'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.backup_outlined),
                selectedIcon: Icon(Icons.backup),
                label: Text('Backup'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Pengaturan'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        InkWell(
          onTap: () => exit(0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: cs.error,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                children: [
                  Icon(Icons.exit_to_app, color: cs.onError),
                  const SizedBox(height: 8),
                  Text(
                    'Keluar',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
