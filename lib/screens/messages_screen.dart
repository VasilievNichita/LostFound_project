import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';
import '../widgets/data_state.dart';
import '../data/entities.dart';
import '../widgets/confirm_action.dart';
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

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final model = context.read<LostFoundModel>();
    if (model.busy || widget.claimId == null) return;
    final error = await model.send(
      Message('', widget.claimId!, model.userId, _text.text.trim(), ''),
    );
    if (!mounted) return;
    if (error != null) {
      showNotice(context, error);
      return;
    }
    _text.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LostFoundModel>();
    final state = dataState(context, model);
    if (state != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Сообщения по заявке'),
          actions: [
            IconButton(
              tooltip: 'Обновить переписку',
              onPressed: model.busy ? null : model.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: state,
      );
    }
    final claimId = widget.claimId;
    final claim = claimId == null ? null : model.claimById(claimId);
    final item = model.byId(claim?.itemId ?? widget.itemId ?? '');
    if (item == null || claim == null) return const NotFoundScreen();
    final thread = model.thread(claim.id);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сообщения по заявке'),
        actions: [
          IconButton(
            tooltip: 'Обновить переписку',
            onPressed: model.busy ? null : model.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
                          model.userName(item.userId),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(item.title, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  StatusBadge(label: claim.status),
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
                  final mine = message.senderId == model.userId;
                  return GestureDetector(
                    key: ValueKey(message.id),
                    onLongPress: !mine || model.busy
                        ? null
                        : () => _remove(message.id),
                    child: Align(
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
                      onPressed:
                          model.busy ||
                              claim.status == 'Закрыта' ||
                              item.statusLabel == 'Возвращено'
                          ? null
                          : _send,
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

  Future<void> _remove(String id) async {
    if (!await confirmAction(
          context,
          'Удалить сообщение?',
          'Сообщение исчезнет из этой переписки.',
        ) ||
        !mounted) {
      return;
    }
    final error = await context.read<LostFoundModel>().removeMessage(id);
    if (mounted && error != null) showNotice(context, error);
  }
}
