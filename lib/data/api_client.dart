import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'result.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

class TokenStore {
  TokenStore(this.preferences) : token = preferences.getString('auth_token');
  final SharedPreferences preferences;
  String? token;
  Future<void> save(String value) async {
    await preferences.setString('auth_token', value);
    token = value;
  }

  Future<void> clear() async {
    token = null;
    await preferences.remove('auth_token');
  }
}

class ApiClient {
  ApiClient(
    this.tokens, {
    http.Client? client,
    this.baseUrl = apiBaseUrl,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 8),
  }) : client = client ?? http.Client();
  final TokenStore tokens;
  final http.Client client;
  final String baseUrl;
  final Duration timeout;
  final void Function()? onUnauthorized;
  void close() => client.close();
  Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Result<T>> request<T>(
    String method,
    String path,
    T Function(dynamic) decode, {
    Object? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) => _guard(() async {
    final usedToken = authenticated ? tokens.token : null;
    final request = http.Request(method, uri(path, query));
    request.headers['Content-Type'] = 'application/json';
    if (usedToken != null) {
      request.headers['Authorization'] = 'Bearer $usedToken';
    }
    if (body != null) request.body = jsonEncode(body);
    final response = await (() async => http.Response.fromStream(
      await client.send(request),
    ))().timeout(timeout);
    return _response(response, decode, authenticated, usedToken);
  });

  Future<Result<String>> upload(List<int> bytes, String name) =>
      _guard(() async {
        if (bytes.length > 5 * 1024 * 1024) {
          return const Failure('Фото должно быть не больше 5 МБ.');
        }
        final ext = name.split('.').last.toLowerCase();
        final mime = {
          'jpg': 'jpeg',
          'jpeg': 'jpeg',
          'png': 'png',
          'webp': 'webp',
        }[ext];
        if (mime == null) {
          return const Failure('Выберите фотографию JPG, PNG или WebP.');
        }
        final usedToken = tokens.token;
        final request = http.MultipartRequest('POST', uri('/files'));
        if (usedToken != null) {
          request.headers['Authorization'] = 'Bearer $usedToken';
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: name,
            contentType: MediaType('image', mime),
          ),
        );
        final response = await (() async => http.Response.fromStream(
          await client.send(request),
        ))().timeout(const Duration(seconds: 20));
        return _response(
          response,
          (json) => json['url'] as String,
          true,
          usedToken,
        );
      });

  Future<Result<T>> _response<T>(
    http.Response response,
    T Function(dynamic) decode,
    bool authenticated,
    String? usedToken,
  ) async {
    if (response.statusCode == 401 && authenticated) {
      // Поздний ответ старой сессии не должен завершать новый вход.
      if (usedToken != null && usedToken == tokens.token) {
        await tokens.clear();
        onUnauthorized?.call();
      }
      return const Failure('Сессия закончилась. Войдите снова.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204) return Success(decode(null));
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return Success(decode(json));
    }
    if (response.statusCode == 401) {
      return const Failure('Неверная почта или пароль.');
    }
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final code = (json['error'] as Map<String, dynamic>)['code'];
    return Failure(switch (code) {
      'EMAIL_TAKEN' => 'Эта почта уже зарегистрирована.',
      'NOT_FOUND' => 'Запись удалена или недоступна.',
      'OWN_ITEM' => 'Это ваше объявление. Заявка не нужна.',
      'CLAIM_EXISTS' => 'У вас уже есть заявка на эту вещь.',
      'ITEM_CLOSED' ||
      'THREAD_CLOSED' => 'Вещь уже возвращена или заявка закрыта.',
      'VALIDATION_ERROR' => 'Проверьте заполненные поля.',
      'FILE_TOO_LARGE' => 'Фото должно быть не больше 5 МБ.',
      _ =>
        'Сервер не выполнил запрос (${response.statusCode}). Попробуйте ещё раз.',
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on TimeoutException {
      return const Failure('Сервер долго не отвечает. Попробуйте ещё раз.');
    } on SocketException {
      return const Failure('Нет связи с сервером. Проверьте подключение.');
    } on http.ClientException {
      return const Failure('Нет связи с сервером. Проверьте подключение.');
    } on FormatException {
      return const Failure('Сервер прислал некорректные данные.');
    } on TypeError {
      return const Failure('Формат ответа сервера изменился.');
    }
  }
}

class AuthApi {
  AuthApi(this.api, this.onSignedIn);
  final ApiClient api;
  final void Function() onSignedIn;
  Future<Result<void>> signIn(
    String email,
    String password, {
    String? name,
  }) async {
    final result = await api.request<String>(
      'POST',
      name == null ? '/auth/login' : '/auth/register',
      (json) => json['token'] as String,
      authenticated: false,
      body: {'email': email, 'password': password, 'name': ?name},
    );
    switch (result) {
      case Success(:final value):
        await api.tokens.save(value);
        onSignedIn();
        return const Success(null);
      case Failure(:final message):
        return Failure(message);
    }
  }

  Future<void> logout() async {
    await api.tokens.clear();
    api.onUnauthorized?.call();
  }
}
