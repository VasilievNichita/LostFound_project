import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';
import '../widgets/data_state.dart';
import '../data/api_client.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      await context.read<AuthApi>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = context.watch<LostFoundModel>();
    final campus = model.campus;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль пользователя')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                  campus.name
                      .split(' ')
                      .where((part) => part.isNotEmpty)
                      .take(2)
                      .map((part) => part[0])
                      .join(),
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
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Как вернуть вещь'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Договоритесь о возврате'),
                content: const Text(
                  'В заявке укажите приметы, которых нет в объявлении. Обсудите встречу в переписке. После передачи автор объявления нажимает «Вещь возвращена».',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Понятно'),
                  ),
                ],
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
