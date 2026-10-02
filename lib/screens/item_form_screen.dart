import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
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

  @override
  void initState() {
    super.initState();
    _item = allItems.where((item) => item.id == widget.itemId).firstOrNull;
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    showNotice(
      context,
      'Проверено: ${_title.text.trim()}. Учебный список не изменён.',
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/items');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemId != null &&
        (_item == null || _item!.userId != currentUserId)) {
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
                items: locations
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
              const Text(
                'На этом этапе проверяем форму. Объявления ещё не сохраняются.',
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('item-submit'),
                onPressed: _submit,
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
