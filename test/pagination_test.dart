import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lost_found/data/api_client.dart';
import 'package:lost_found/data/http_repositories.dart';
import 'package:lost_found/models/lost_found_model.dart';

import 'support/mock_repositories.dart';

Map<String, Object> row(int id, {String title = 'Футляр'}) => {
  'id': id,
  'userId': 1,
  'type': 'found',
  'title': title,
  'description': '',
  'imageUrl': '',
  'location': 'Библиотека',
  'status': 'open',
  'createdAt': '2026-10-04T10:00:00Z',
};
http.Response page(List<Map<String, Object>> items) =>
    http.Response.bytes(utf8.encode(jsonEncode({'items': items})), 200);

void main() {
  late TokenStore tokens;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'auth_token': 'test'});
    tokens = TokenStore(await SharedPreferences.getInstance());
  });
  LostFoundModel model(ApiClient api) {
    final store = MockStore(delay: Duration.zero);
    return LostFoundModel(
      HttpItemRepository(api),
      MockClaimRepository(store),
      MockMessageRepository(store),
      serverPaging: true,
    );
  }

  test(
    'paging appends in server order, deduplicates and stops at last page',
    () async {
      final requested = <int>[];
      final api = ApiClient(
        tokens,
        client: MockClient((r) async {
          final n = int.parse(r.url.queryParameters['page']!);
          requested.add(n);
          return page(
            n == 1
                ? [for (var id = 20; id >= 1; id--) row(id)]
                : [row(1), row(21)],
          );
        }),
      );
      final state = model(api);
      await state.loadBoard();
      expect(state.visibleItems.length, 20);
      expect(state.hasMore, isTrue);
      await Future.wait([
        state.loadBoard(more: true),
        state.loadBoard(more: true),
      ]);
      expect(requested, [1, 2]);
      expect(state.visibleItems.length, 21);
      expect(state.visibleItems.first.id, '20');
      expect(state.visibleItems.last.id, '21');
      expect(state.hasMore, isFalse);
      state.dispose();
      api.close();
    },
  );
  test(
    'failed next page preserves content and retries the same page',
    () async {
      var fail = true;
      final requested = <int>[];
      final api = ApiClient(
        tokens,
        client: MockClient((r) async {
          final n = int.parse(r.url.queryParameters['page']!);
          requested.add(n);
          if (n == 2 && fail) throw http.ClientException('offline');
          return page(
            n == 1 ? [for (var id = 1; id <= 20; id++) row(id)] : [row(21)],
          );
        }),
      );
      final state = model(api);
      await state.loadBoard();
      await state.loadBoard(more: true);
      expect(state.visibleItems.length, 20);
      expect(state.boardError, isNotNull);
      fail = false;
      await state.loadBoard(more: true);
      expect(requested, [1, 2, 2]);
      expect(state.visibleItems.length, 21);
      expect(state.boardError, isNull);
      state.dispose();
      api.close();
    },
  );
  test('late search response cannot replace a newer search', () async {
    final old = Completer<http.Response>();
    final api = ApiClient(
      tokens,
      client: MockClient((r) async {
        return r.url.queryParameters['search'] == 'старый'
            ? old.future
            : page([row(2, title: 'новый футляр')]);
      }),
    );
    final state = model(api);
    state.filter(query: 'старый');
    final pending = state.loadBoard();
    state.filter(query: 'новый');
    await state.loadBoard();
    old.complete(page([row(1, title: 'старый футляр')]));
    await pending;
    expect(state.visibleItems.single.id, '2');
    expect(state.loadingMore, isFalse);
    state.dispose();
    api.close();
  });
}
