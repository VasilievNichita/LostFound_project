String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Укажите почту для входа';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Проверьте адрес, например name@utm.md';
  }
  return null;
}

String? validatePassword(String? value) {
  if ((value ?? '').length < 6) return 'В пароле нужно хотя бы 6 символов';
  return null;
}

String? validateTitle(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Напишите, какая вещь потеряна или найдена';
  if (text.length > 80) return 'Сократите название до 80 символов';
  return null;
}

String? validateEvidence(String? value) {
  final text = value?.trim() ?? '';
  if (text.length < 10) {
    return 'Опишите особую примету вещи, хотя бы 10 символов';
  }
  if (text.length > 600) return 'Сократите описание приметы до 600 символов';
  return null;
}

String? validateMessage(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Напишите сообщение автору объявления';
  if (text.length > 1000) {
    return 'Сообщение должно быть не длиннее 1000 символов';
  }
  return null;
}
