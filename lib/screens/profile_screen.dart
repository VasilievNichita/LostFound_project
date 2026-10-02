import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = [
      (Icons.edit_outlined, 'Редактировать профиль'),
      (Icons.notifications_outlined, 'Уведомления'),
      (Icons.bookmark_border, 'Сохраненные поиски'),
      (Icons.help_outline, 'Как вернуть вещь'),
      (Icons.support_agent, 'Связаться с поддержкой'),
      (Icons.info_outline, 'О LostFound'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль пользователя')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                'НВ',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Никита Васильев',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text('Студент · CR-232', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(label: '${myItems.length} объявлений'),
                StatusBadge(label: '${claims.length} заявок'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Card.outlined(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.alternate_email,
                    label: 'Почта',
                    value: 'nichita.vasiliev@iis.utm.md',
                  ),
                  InfoRow(
                    icon: Icons.school_outlined,
                    label: 'Университет',
                    value: 'Технический университет Молдовы',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Ваше пространство', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                options[index].$1,
                color: theme.colorScheme.primary,
              ),
              title: Text(options[index].$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}
