import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';
import '../widgets/data_state.dart';
import '../widgets/confirm_action.dart';
import '../widgets/feedback.dart';
import '../widgets/item_card.dart';
import '../widgets/status_badge.dart';

class MyActivityScreen extends StatelessWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = context.watch<LostFoundModel>();
    final myItems = model.myItems;
    final claims = model.myClaims;
    return Scaffold(
      appBar: AppBar(title: const Text('Мои объявления и заявки')),
      body:
          dataState(context, model) ??
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Все под рукой',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('Ваши публикации и обращения к владельцам'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(label: '${myItems.length} объявлений'),
                          StatusBadge(label: '${claims.length} заявок'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Мои объявления', style: theme.textTheme.titleLarge),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: myItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => Dismissible(
                    key: ValueKey(myItems[index].id),
                    direction: model.busy
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    background: const ColoredBox(
                      color: Color(0xFFFFDAD6),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
                    confirmDismiss: (_) async {
                      final confirmed = await confirmAction(
                        context,
                        'Удалить объявление?',
                        'Будут удалены и связанные переписки.',
                      );
                      if (!confirmed || !context.mounted) return false;
                      final error = await context
                          .read<LostFoundModel>()
                          .removeItem(myItems[index].id);
                      if (context.mounted && error != null) {
                        showNotice(context, error);
                      }
                      // Список обновляет модель. При отказе карточка остаётся на месте.
                      return false;
                    },
                    child: ItemCard(
                      item: myItems[index],
                      onTap: () => context.push('/items/${myItems[index].id}'),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Text(
                    'Мои заявки · ${claims.length}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList.separated(
                  itemCount: claims.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final claim = claims[index];
                    final item = model.byId(claim.itemId);
                    return Card.outlined(
                      key: ValueKey(claim.id),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item?.title ?? 'Объявление удалено',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(claim.message),
                            TextButton(
                              onPressed: () => context.push(
                                '/activity/claims/${claim.id}/messages',
                              ),
                              child: const Text('Открыть переписку'),
                            ),
                            TextButton(
                              onPressed: model.busy
                                  ? null
                                  : () async {
                                      final confirmed = await confirmAction(
                                        context,
                                        'Удалить заявку?',
                                        'Переписка по заявке тоже будет удалена.',
                                      );
                                      if (!confirmed || !context.mounted) {
                                        return;
                                      }
                                      final error = await context
                                          .read<LostFoundModel>()
                                          .removeClaim(claim.id);
                                      if (context.mounted && error != null) {
                                        showNotice(context, error);
                                      }
                                    },
                              child: const Text('Удалить заявку'),
                            ),
                            const SizedBox(height: 12),
                            StatusBadge(
                              label: claim.status,
                              resolved: claim.status == 'Закрыта',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
