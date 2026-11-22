import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lost_found/data/api_client.dart';
import 'package:lost_found/data/http_repositories.dart';
import 'package:lost_found/data/entities.dart';
import 'package:lost_found/data/result.dart';

void main() {
  late TokenStore tokens;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'auth_token': 'session-one'});
    tokens = TokenStore(await SharedPreferences.getInstance());
  });
  test('JWT attached, Cyrillic query encoded, server id retained', () async {
    final api = ApiClient(
      tokens,
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer session-one');
        expect(
          request.url.queryParameters,
          containsPair('search', 'Синий футляр'),
        );
        expect(request.url.queryParameters['page'], '2');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 42,
                'userId': 7,
                'type': 'found',
                'title': 'Синий футляр',
                'description': '',
                'imageUrl': '',
                'location': 'Библиотека',
                'status': 'open',
                'createdAt': '2026-10-04T10:00:00Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final result = await HttpItemRepository(api)
        .fetchAll(page: 2, search: 'Синий футляр');
    expect((result as Success<List<Item>>).value.single.id, '42');
    api.close();
  });
  test('204 does not decode an empty body', () async {
    final api = ApiClient(
      tokens,
      client: MockClient((_) async => http.Response('', 204)),
    );
    expect(await HttpItemRepository(api).delete('42'), isA<Success<void>>());
    api.close();
  });
  test('parallel protected 401 clears JWT and navigates only once', () async {
    var callbacks = 0;
    final api = ApiClient(
      tokens,
      onUnauthorized: () => callbacks++,
      client: MockClient((_) async => http.Response('', 401)),
    );
    await Future.wait([
      api.request('GET', '/items', (j) => j),
      api.request('GET', '/claims', (j) => j),
    ]);
    expect(tokens.token, isNull);
    expect(tokens.preferences.containsKey('auth_token'), isFalse);
    expect(callbacks, 1);
    api.close();
  });
  test('a late 401 from an old token cannot clear a new session', () async {
    final response = Completer<http.Response>();
    var callbacks = 0;
    final api = ApiClient(
      tokens,
      onUnauthorized: () => callbacks++,
      client: MockClient((_) => response.future),
    );
    final pending = api.request('GET', '/items', (j) => j);
    await tokens.save('session-two');
    response.complete(http.Response('', 401));
    await pending;
    expect(tokens.token, 'session-two');
    expect(callbacks, 0);
    api.close();
  });
  test('wrong login is translated without ending another session', () async {
    var callbacks = 0;
    final api = ApiClient(
      tokens,
      onUnauthorized: () => callbacks++,
      client: MockClient((_) async => http.Response('', 401)),
    );
    final result = await AuthApi(
      api,
      () {},
    ).signIn('one@example.org', 'incorrect');
    expect((result as Failure<void>).message, 'Неверная почта или пароль.');
    expect(callbacks, 0);
    api.close();
  });
  test('registration stores JWT only, no password or email', () async {
    final api = ApiClient(
      tokens,
      client: MockClient((r) async {
        expect(r.headers.containsKey('Authorization'), isFalse);
        return http.Response('{"token":"new-session"}', 201);
      }),
    );
    var signedIn = false;
    expect(
      await AuthApi(
        api,
        () => signedIn = true,
      ).signIn('one@example.org', 'password123', name: 'Никита'),
      isA<Success<void>>(),
    );
    expect(tokens.preferences.getKeys(), {'auth_token'});
    expect(tokens.token, 'new-session');
    expect(signedIn, isTrue);
    api.close();
  });
  for (final mode in [
    'transport',
    'timeout',
    'invalid json',
    'wrong shape',
    'conflict',
    'null body',
    'null item',
  ]) {
    test('$mode becomes a readable Failure', () async {
      final api = ApiClient(
        tokens,
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) async {
          if (mode == 'transport') throw http.ClientException('offline');
          if (mode == 'timeout') {
            await Future<void>.delayed(const Duration(milliseconds: 40));
          }
          if (mode == 'conflict') {
            return http.Response('{"error":{"code":"CLAIM_EXISTS"}}', 409);
          }
          if (mode == 'null body') {
            return http.Response('null', 200);
          }
          if (mode == 'null item') {
            return http.Response('{"items":[null]}', 200);
          }
          return http.Response(
            mode == 'wrong shape' ? '{"items":7}' : 'not JSON',
            200,
          );
        }),
      );
      final result = await HttpItemRepository(api).fetchAll();
      expect(result, isA<Failure<List<Item>>>());
      expect((result as Failure).message, isNotEmpty);
      api.close();
    });
  }
  test('write payload excludes ids and author controlled by server', () {
    final json = itemToJson(
      const Item(
        '999',
        'forged',
        'found',
        'Ключи',
        '',
        '',
        'Библиотека',
        '',
        'Возвращено',
      ),
    );
    expect(json.containsKey('id'), isFalse);
    expect(json.containsKey('userId'), isFalse);
    expect(json['status'], 'returned');
  });
  test('oversize upload is rejected before transport', () async {
    final api = ApiClient(
      tokens,
      client: MockClient((_) async => throw StateError('must not send')),
    );
    expect(
      await api.upload(List.filled(5 * 1024 * 1024 + 1, 0), 'photo.png'),
      isA<Failure<String>>(),
    );
    api.close();
  });
}
