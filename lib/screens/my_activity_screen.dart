import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/item_card.dart';
import '../widgets/status_badge.dart';

class MyActivityScreen extends StatelessWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Мои объявления и заявки')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Все под рукой', style: theme.textTheme.headlineSmall),
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
              itemBuilder: (_, index) => ItemCard(item: myItems[index]),
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
                final item = allItems.firstWhere(
                  (item) => item.id == claim.itemId,
                );
                return Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(claim.message),
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
