import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/item_card.dart';

import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';
import '../widgets/data_state.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _search.text = context.read<LostFoundModel>().query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LostFoundModel>();
    final visible = model.visibleItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доска объявлений'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: model.busy
                ? null
                : () => context.read<LostFoundModel>().load(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Добавить объявление',
            onPressed: model.busy || model.campus == null
                ? null
                : () => context.push('/items/new'),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body:
          dataState(context, model) ??
          NotificationListener<ScrollNotification>(
            onNotification: (event) {
              if (event.metrics.extentAfter < 180 &&
                  model.hasMore &&
                  !model.loadingMore &&
                  model.boardError == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) model.loadBoard(more: true);
                });
              }
              return false;
            },
            child: CustomScrollView(
              key: const PageStorageKey('board-scroll'),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Найдем. Вернем. Поможем.',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('board-search'),
                          controller: _search,
                          onChanged: (text) => context
                              .read<LostFoundModel>()
                              .filter(query: text),
                          decoration: const InputDecoration(
                            hintText: 'Название или примета вещи',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: 'lost',
                              label: Text('Потеряно'),
                            ),
                            ButtonSegment(
                              value: 'found',
                              label: Text('Найдено'),
                            ),
                          ],
                          selected: {model.type},
                          onSelectionChanged: (value) => context
                              .read<LostFoundModel>()
                              .filter(type: value.single),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey('filter-${model.location}'),
                          initialValue: model.location ?? '',
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Место'),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Все места'),
                            ),
                            for (final place in model.locations)
                              DropdownMenuItem(
                                value: place,
                                child: Text(place),
                              ),
                          ],
                          onChanged: (place) =>
                              context.read<LostFoundModel>().filter(
                                location: place,
                                clearLocation: place == '',
                              ),
                        ),
                        if (model.query.isNotEmpty || model.location != null)
                          TextButton(
                            onPressed: () {
                              _search.clear();
                              context.read<LostFoundModel>().resetFilters();
                            },
                            child: const Text('Сбросить поиск и место'),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'На доске: ${visible.length}',
                          key: const Key('board-count'),
                        ),
                        if (visible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              'Подходящих вещей пока нет. Попробуйте другое место или запрос.',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (model.loadingMore) const LinearProgressIndicator(),
                      if (model.boardError != null)
                        ErrorView(
                          message: model.boardError!,
                          onRetry: model.retryBoard,
                        ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    itemBuilder: (_, index) => ItemCard(
                      key: ValueKey(visible[index].id),
                      item: visible[index],
                      onTap: () => context.push('/items/${visible[index].id}'),
                    ),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                  ),
                ),
                if (model.hasMore)
                  SliverToBoxAdapter(
                    child: TextButton(
                      onPressed: model.loadingMore
                          ? null
                          : () => model.loadBoard(more: true),
                      child: const Text('Показать ещё'),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}
