import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/not_found_screen.dart';
import '../validation.dart';
import '../widgets/feedback.dart';
import '../widgets/status_badge.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.claimId, this.itemId});
  final String? claimId, itemId;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    showNotice(
      context,
      'Сообщение проверено. Отправка появится на следующем этапе.',
    );
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final claimId = widget.claimId;
    final itemId = widget.itemId;
    final claim = claims.where((claim) => claim.id == claimId).firstOrNull;
    final item = allItems
        .where((item) => item.id == (claim?.itemId ?? itemId))
        .firstOrNull;
    if (item == null || (claimId != null && claim == null)) {
      return const NotFoundScreen();
    }
    final thread = messages
        .where((message) => message.claimId == claimId)
        .toList();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Сообщения по заявке')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    child: Text(
                      'LF',
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userNames[item.userId] ?? item.userId,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(item.title, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  StatusBadge(label: claimId ?? 'Пример'),
                ],
              ),
            ),
            const Divider(height: 1),
            if (thread.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Сообщений пока нет. Здесь будет переписка по этой вещи.',
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: thread.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = thread[index];
                  final mine = message.senderId == currentUserId;
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: .84,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mine
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: mine
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                message.sentAt,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('message-text'),
                        controller: _text,
                        validator: validateMessage,
                        textInputAction: TextInputAction.send,
                        onFieldSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Сообщение',
                          contentPadding: EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _send,
                      tooltip: 'Отправить',
                      icon: const Icon(Icons.arrow_upward),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
