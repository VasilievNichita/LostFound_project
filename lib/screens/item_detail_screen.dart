import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/item_card.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final item = foundItems.first;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка вещи'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share),
            tooltip: 'Поделиться',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                ItemVisual(item: item, size: 120),
                const SizedBox(height: 8),
                const Text(
                  'Изображение вещи',
                  semanticsLabel: 'Иллюстрация рюкзака',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(label: item.statusLabel),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(item.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Место находки',
                    value: item.location,
                  ),
                  InfoRow(
                    icon: Icons.schedule,
                    label: 'Когда найдено',
                    value: item.dateLabel,
                  ),
                  const InfoRow(
                    icon: Icons.person_outline,
                    label: 'Опубликовала',
                    value: 'Ана Русу · студентка ТУМ',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.pan_tool_outlined),
            label: const Text('Это моя вещь'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.task_alt),
            label: const Text('Отметить возврат'),
          ),
        ],
      ),
    );
  }
}
