import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widgets/item_card.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доска объявлений'),
        actions: [
          IconButton(
            onPressed: () => context.push('/items/new'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Добавить объявление',
          ),
        ],
      ),
      body: CustomScrollView(
        key: const PageStorageKey('board-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Найдем. Вернем. Поможем.',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text('Вещи и люди рядом — в вашем кампусе'),
                  const SizedBox(height: 20),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Что вы потеряли?',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: 'lost',
                        label: Text('Потеряно'),
                        icon: Icon(Icons.search_rounded),
                      ),
                      ButtonSegment(
                        value: 'found',
                        label: Text('Найдено'),
                        icon: Icon(Icons.check_circle_outline),
                      ),
                    ],
                    selected: const {'found'},
                    onSelectionChanged: (_) {},
                  ),
                  const SizedBox(height: 12),
                  DropdownMenu<String>(
                    width: double.infinity,
                    initialSelection: 'Все места',
                    label: const Text('Место'),
                    leadingIcon: const Icon(Icons.location_on_outlined),
                    dropdownMenuEntries: ['Все места', ...locations]
                        .map(
                          (place) =>
                              DropdownMenuEntry(value: place, label: place),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Найдено в кампусе · ${foundItems.length}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.separated(
              itemCount: foundItems.length,
              itemBuilder: (_, index) => ItemCard(
                item: foundItems[index],
                onTap: () => context.push('/items/${foundItems[index].id}'),
              ),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
            ),
          ),
        ],
      ),
    );
  }
}
