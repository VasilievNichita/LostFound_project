import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';
import '../widgets/data_state.dart';
import '../data/mock_repositories.dart';
import '../widgets/feedback.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _simulateError = false;
  @override
  void initState() {
    super.initState();
    _simulateError = context.read<MockStore>().simulateError;
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы вернётесь на экран входа.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Да, выйти'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = context.watch<LostFoundModel>();
    final campus = model.campus;
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
          SwitchListTile(
            key: const Key('simulate-error'),
            title: const Text('Симулировать сбой сети'),
            subtitle: const Text('Учебная проверка отказа хранилища'),
            value: _simulateError,
            onChanged: (value) {
              setState(() => _simulateError = value);
              context.read<MockStore>().simulateError = value;
            },
          ),
          if (model.isLoading) const LinearProgressIndicator(),
          if (model.error != null)
            ErrorView(
              message: model.error!,
              onRetry: () => context.read<LostFoundModel>().load(),
            ),
          if (campus != null) ...[
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  campus.name.split(' ').take(2).map((part) => part[0]).join(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              campus.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(campus.group, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(label: '${model.myItems.length} объявлений'),
                  StatusBadge(label: '${model.myClaims.length} заявок'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card.outlined(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.alternate_email,
                      label: 'Почта',
                      value: campus.email,
                    ),
                    InfoRow(
                      icon: Icons.school_outlined,
                      label: 'Университет',
                      value: campus.university,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
              onTap: () => showNotice(
                context,
                '${options[index].$2}: этот раздел пока в разработке.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}
