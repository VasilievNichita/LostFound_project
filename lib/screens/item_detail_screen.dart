import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';
import '../widgets/data_state.dart';
import '../data/entities.dart';
import '../widgets/confirm_action.dart';
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
    final model = context.watch<LostFoundModel>();
    final state = dataState(context, model);
    if (state != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Карточка вещи')),
        body: state,
      );
    }
    final item = model.byId(id);
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
                    value: model.userName(item.userId),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                item.userId == model.userId || item.statusLabel == 'Возвращено'
                ? null
                : () => context.push('/items/$id/claim'),
            icon: const Icon(Icons.pan_tool_outlined),
            label: const Text('Это моя вещь'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: item.userId == model.userId
                ? () => context.push('/items/$id/edit')
                : null,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Редактировать'),
          ),
          if (item.userId == model.userId) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('item-close'),
              onPressed: model.busy || item.statusLabel == 'Возвращено'
                  ? null
                  : () => _change(context, item, false),
              icon: const Icon(Icons.check),
              label: const Text('Вещь возвращена'),
            ),
            TextButton.icon(
              key: const Key('item-delete'),
              onPressed: model.busy ? null : () => _change(context, item, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить объявление'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _change(BuildContext context, Item item, bool deleting) async {
    final confirmed = await confirmAction(
      context,
      deleting ? 'Удалить объявление?' : 'Вещь уже вернули?',
      deleting
          ? 'Будут удалены объявление и связанные переписки.'
          : 'Объявление останется в списке с отметкой о возврате.',
    );
    if (!confirmed || !context.mounted) return;
    final model = context.read<LostFoundModel>();
    final error = await (deleting
        ? model.removeItem(item.id)
        : model.closeItem(item));
    if (!context.mounted) return;
    if (error != null) {
      showNotice(context, error);
      return;
    }
    if (deleting) context.go('/activity');
  }
}
