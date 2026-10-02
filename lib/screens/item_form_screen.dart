import 'package:flutter/material.dart';

import '../data/mock_data.dart';

class ItemFormScreen extends StatelessWidget {
  const ItemFormScreen({super.key, this.itemId});
  final String? itemId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Объявление')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Расскажите о вещи', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Несколько деталей помогут найти владельца быстрее.'),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'lost',
                label: Text('Потерял'),
                icon: Icon(Icons.search),
              ),
              ButtonSegment(
                value: 'found',
                label: Text('Нашёл'),
                icon: Icon(Icons.check_circle_outline),
              ),
            ],
            selected: const {'found'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 20),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Название *',
              hintText: 'Например, серый рюкзак',
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Описание',
              alignLabelWithHint: true,
              hintText: 'Цвет, размер и заметные особенности',
            ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            width: double.infinity,
            label: const Text('Место *'),
            initialSelection: locations.first,
            dropdownMenuEntries: locations
                .map((place) => DropdownMenuEntry(value: place, label: place))
                .toList(),
          ),
          const SizedBox(height: 20),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  const Text('Фотография вещи'),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Добавить фото'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '* Название, тип и место нужны для объявления.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: () {}, child: const Text('Опубликовать')),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Сохранить изменения'),
          ),
        ],
      ),
    );
  }
}
