import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../validation.dart';
import '../widgets/item_card.dart';
import '../widgets/feedback.dart';
import '../widgets/not_found_screen.dart';

class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key, required this.itemId});
  final String itemId;

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _evidence = TextEditingController();

  @override
  void dispose() {
    _evidence.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    showNotice(
      context,
      'Заявка проверена. Открыт пример переписки без отправки.',
    );
    context.pushReplacement('/items/${widget.itemId}/preview');
  }

  @override
  Widget build(BuildContext context) {
    final item = allItems.where((item) => item.id == widget.itemId).firstOrNull;
    if (item == null ||
        item.userId == currentUserId ||
        item.statusLabel == 'Возвращено') {
      return const NotFoundScreen();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Заявка владельца')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Узнали свою вещь?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ItemCard(item: item),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('claim-evidence'),
                controller: _evidence,
                minLines: 4,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Доказательство владения',
                  alignLabelWithHint: true,
                  hintText: 'Вспомните примету, которой нет на фотографии.',
                ),
                validator: validateEvidence,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => showNotice(
                  context,
                  'Прикрепление файлов появится на этапе работы с сервером.',
                ),
                icon: const Icon(Icons.attach_file),
                label: const Text('Прикрепить подтверждение'),
              ),
              const SizedBox(height: 16),
              const Text(
                'После проверки откроется пример переписки. Заявка пока не отправляется автору.',
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('claim-submit'),
                onPressed: _submit,
                child: const Text('Это моё, отправить заявку'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
