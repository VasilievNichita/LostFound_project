import 'package:flutter/material.dart';

import 'login_screen.dart';

import 'board_screen.dart';

import 'item_detail_screen.dart';

import 'item_form_screen.dart';

import 'claim_screen.dart';

import 'messages_screen.dart';

// SCREEN_IMPORTS

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = <(String, IconData, Widget)>[
      ('Вход / регистрация', Icons.login_rounded, const LoginScreen()),
      ('Доска объявлений', Icons.dashboard_outlined, const BoardScreen()),
      ('Карточка вещи', Icons.backpack_outlined, const ItemDetailScreen()),
      (
        'Создание / редактирование',
        Icons.edit_note_rounded,
        const ItemFormScreen(),
      ),
      ('Заявка владельца', Icons.pan_tool_outlined, const ClaimScreen()),
      ('Сообщения по заявке', Icons.forum_outlined, const MessagesScreen()),
      // SCREEN_ENTRIES
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('LostFound')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Вещи возвращаются.\nИстории продолжаются.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Кампус ТУМ · Бюро находок',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Text(
            'Экраны приложения',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Меню демонстрации статических макетов'),
          const SizedBox(height: 16),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card.filled(
                child: ListTile(
                  minTileHeight: 62,
                  leading: Icon(entry.$2, color: scheme.primary),
                  title: Text(entry.$1),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => entry.$3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
