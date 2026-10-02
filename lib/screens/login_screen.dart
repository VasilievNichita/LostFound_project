import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../validation.dart';
import '../widgets/feedback.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.register = false});
  final bool register;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    showNotice(
      context,
      widget.register
          ? 'Данные регистрации проверены. Открыт учебный режим.'
          : 'Форма проверена. Открыт учебный режим.',
    );
    context.go('/items');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.register ? 'Регистрация' : 'Вход в LostFound'),
    ),
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.travel_explore_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              widget.register ? 'Знакомимся' : 'Снова на связи',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Объявления о вещах, потерянных и найденных в кампусе.'),
            const SizedBox(height: 24),
            if (widget.register) ...[
              TextFormField(
                key: const Key('name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Имя'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Введите имя, хотя бы 2 символа'
                    : null,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              key: const Key('email'),
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Почта',
                hintText: 'name@utm.md',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('password'),
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: widget.register
                  ? TextInputAction.next
                  : TextInputAction.done,
              validator: validatePassword,
              onFieldSubmitted: (_) {
                if (!widget.register) _submit();
              },
            ),
            if (widget.register) ...[
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('confirmation'),
                controller: _confirmation,
                decoration: const InputDecoration(
                  labelText: 'Повторите пароль',
                ),
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                validator: (value) => value != _password.text
                    ? 'Пароли не совпадают'
                    : validatePassword(value),
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('auth-submit'),
              onPressed: _submit,
              child: Text(widget.register ? 'Зарегистрироваться' : 'Войти'),
            ),
            TextButton(
              onPressed: () => widget.register
                  ? context.go('/login')
                  : context.push('/register'),
              child: Text(
                widget.register
                    ? 'Уже есть аккаунт? Войти'
                    : 'Нет аккаунта? Зарегистрируйтесь',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Учебный режим: поля проверяются локально. Аккаунт на сервере пока не создаётся.',
            ),
          ],
        ),
      ),
    ),
  );
}
