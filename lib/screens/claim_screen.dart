import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';
import '../widgets/data_state.dart';
import '../data/entities.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final model = context.read<LostFoundModel>();
    if (model.busy) return;
    FocusScope.of(context).unfocus();
    final error = await model.addClaim(
      Claim(
        '',
        widget.itemId,
        model.userId,
        _evidence.text.trim(),
        'Проверяется',
      ),
    );
    if (!mounted) return;
    if (error != null) {
      showNotice(context, error);
      return;
    }
    final claim = model.myClaims.firstWhere(
      (c) => c.itemId == widget.itemId && c.status != 'Закрыта',
    );
    context.go('/activity/claims/${claim.id}/messages');
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LostFoundModel>();
    final state = dataState(context, model);
    if (state != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Заявка владельца')),
        body: state,
      );
    }
    final item = model.byId(widget.itemId);
    if (item == null ||
        item.userId == model.userId ||
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
                'Заявка и переписка сохраняются в памяти до перезапуска.',
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('claim-submit'),
                onPressed: model.busy ? null : _submit,
                child: const Text('Это моё, отправить заявку'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
