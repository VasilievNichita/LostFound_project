import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/item_card.dart';

class ClaimScreen extends StatelessWidget {
  const ClaimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Заявка владельца')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Узнали свою вещь?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Расскажите о деталях, которые знаете только вы.'),
          const SizedBox(height: 20),
          ItemCard(item: foundItems.first),
          const SizedBox(height: 24),
          const TextField(
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Доказательство владения',
              alignLabelWithHint: true,
              hintText: 'Что внутри? Есть ли особая отметка или наклейка?',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.attach_file),
            label: const Text('Прикрепить подтверждение'),
          ),
          const SizedBox(height: 20),
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.forum_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'После отправки заявки вы сможете '
                      'обсудить возврат с автором объявления.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {},
            child: const Text('Это моё — отправить заявку'),
          ),
        ],
      ),
    );
  }
}
