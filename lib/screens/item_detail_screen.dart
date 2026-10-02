import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widgets/not_found_screen.dart';
import '../widgets/feedback.dart';
import '../widgets/item_card.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final item = allItems.where((item) => item.id == id).firstOrNull;
    if (item == null) return const NotFoundScreen();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка вещи'),
        actions: [
          IconButton(
            onPressed: () =>
                showNotice(context, 'Адрес объявления: /items/$id'),
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
                const Text('Изображение вещи'),
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
                    label: 'Место',
                    value: item.location,
                  ),
                  InfoRow(
                    icon: Icons.schedule,
                    label: 'Дата',
                    value: item.dateLabel,
                  ),
                  InfoRow(
                    icon: Icons.person_outline,
                    label: 'Автор',
                    value: userNames[item.userId] ?? item.userId,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                item.userId == currentUserId || item.statusLabel == 'Возвращено'
                ? null
                : () => context.push('/items/$id/claim'),
            icon: const Icon(Icons.pan_tool_outlined),
            label: const Text('Это моя вещь'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: item.userId == currentUserId
                ? () => context.push('/items/$id/edit')
                : null,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Редактировать'),
          ),
        ],
      ),
    );
  }
}
