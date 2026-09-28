import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Вход / регистрация')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.travel_explore_rounded,
                size: 40,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Снова на связи', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Войдите в LostFound, чтобы ваши вещи\nнашли дорогу домой.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Университетская почта',
              hintText: 'name@iis.utm.md',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: () {}, child: const Text('Войти')),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Text('Нет аккаунта? Зарегистрируйтесь'),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.school_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Для студентов и сотрудников ТУМ. '
                  'Один кампус — сообщество, которое помогает.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
