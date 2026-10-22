import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Consumer<LostFoundModel>(
          builder: (_, model, _) => model.isSaving
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
        Expanded(child: navigationShell),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      destinations: [
        const NavigationDestination(icon: Icon(Icons.search), label: 'Доска'),
        NavigationDestination(
          icon: Consumer<LostFoundModel>(
            builder: (_, model, child) =>
                Badge(label: Text('${model.myItems.length}'), child: child!),
            child: const Icon(Icons.inventory_2_outlined),
          ),
          label: 'Мои',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Профиль',
        ),
      ],
    ),
  );
}
