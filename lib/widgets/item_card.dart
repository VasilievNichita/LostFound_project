import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import 'status_badge.dart';

class ItemVisual extends StatelessWidget {
  const ItemVisual({super.key, required this.item, this.size = 72});
  final Item item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icons = [
      Icons.backpack_outlined,
      Icons.key_outlined,
      Icons.headphones_outlined,
      Icons.coffee_outlined,
      Icons.visibility_outlined,
      Icons.power_outlined,
      Icons.umbrella_outlined,
      Icons.menu_book_outlined,
      Icons.badge_outlined,
      Icons.usb_rounded,
      Icons.calculate_outlined,
      Icons.sports_handball_outlined,
      Icons.water_drop_outlined,
      Icons.checkroom_outlined,
      Icons.cable_outlined,
      Icons.draw_outlined,
    ];
    final index = (int.parse(item.id.substring(1)) - 1) % icons.length;
    return Semantics(
      label: 'Иллюстрация вещи: ${item.title}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icons[index],
          size: size * .48,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, this.onTap});
  final Item item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemVisual(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(item.location, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      item.dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusBadge(
                      label: item.statusLabel,
                      resolved: item.statusLabel == 'Возвращено',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
