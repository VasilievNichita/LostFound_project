import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';
import '../widgets/data_state.dart';
import '../data/entities.dart';
import '../validation.dart';
import '../widgets/feedback.dart';
import '../widgets/not_found_screen.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.itemId});
  final String? itemId;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  Item? _item;
  String? _type, _location;

  bool _prefilled = false;
  void _prefill(LostFoundModel model) {
    if (_prefilled) return;
    _prefilled = true;
    _item = widget.itemId == null ? null : model.byId(widget.itemId!);
    if (_item case final item?) {
      _title.text = item.title;
      _description.text = item.description;
      _type = item.type;
      _location = item.location;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final model = context.read<LostFoundModel>();
    if (model.busy) return;
    FocusScope.of(context).unfocus();
    final draft = Item(
      _item?.id ?? '',
      model.userId,
      _type!,
      _title.text.trim(),
      _description.text.trim(),
      _item?.imageUrl ?? '',
      _location!,
      _item?.dateLabel ?? '',
      _item?.statusLabel == 'Возвращено'
          ? 'Возвращено'
          : (_type == 'found' ? 'Ищет владельца' : 'Поиск'),
    );
    final error = await model.saveItem(draft, editing: widget.itemId != null);
    if (!mounted) return;
    if (error != null) {
      showNotice(context, error);
      return;
    }
    showNotice(context, 'Объявление сохранено в памяти приложения.');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/activity');
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LostFoundModel>();
    final state = dataState(context, model);
    if (state != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Объявление')),
        body: state,
      );
    }
    _prefill(model);
    if (widget.itemId != null &&
        (_item == null || _item!.userId != model.userId)) {
      return const NotFoundScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemId == null
              ? 'Новое объявление'
              : 'Редактирование объявления',
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Расскажите о вещи',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('item-type'),
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Тип объявления *',
                ),
                items: const [
                  DropdownMenuItem(value: 'lost', child: Text('Потерял')),
                  DropdownMenuItem(value: 'found', child: Text('Нашёл')),
                ],
                onChanged: (value) => _type = value,
                validator: (value) =>
                    value == null ? 'Выберите: потерял или нашёл' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('item-title'),
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  hintText: 'Например, серый рюкзак',
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: validateTitle,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('item-description'),
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  alignLabelWithHint: true,
                ),
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                minLines: 3,
                maxLines: 5,
                validator: (value) => (value?.trim().length ?? 0) > 500
                    ? 'Сократите описание до 500 символов'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('item-location'),
                initialValue: _location,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Место *'),
                items: model.locations
                    .map(
                      (place) =>
                          DropdownMenuItem(value: place, child: Text(place)),
                    )
                    .toList(),
                onChanged: (value) => _location = value,
                validator: (value) =>
                    value == null ? 'Укажите место в кампусе' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => showNotice(
                  context,
                  'Загрузка фотографий появится после подключения сервера.',
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Добавить фото'),
              ),
              const SizedBox(height: 16),
              const Text('Изменения хранятся до перезапуска приложения.'),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('item-submit'),
                onPressed: model.busy ? null : _submit,
                child: Text(
                  widget.itemId == null
                      ? 'Опубликовать'
                      : 'Сохранить изменения',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
