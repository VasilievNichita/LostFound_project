import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:lost_found/main.dart';
import 'package:lost_found/data/api_client.dart';
import 'package:lost_found/data/entities.dart';
import 'package:lost_found/data/result.dart';
import 'package:lost_found/models/lost_found_model.dart';
import 'package:lost_found/screens/board_screen.dart';
import 'package:lost_found/screens/login_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('L5: live API, two users, paging, persistence, outage and 401', (
    tester,
  ) async {
    Future<dynamic> request(
      String method,
      String path, {
      Object? body,
      String? token,
    }) async {
      final req = http.Request(method, Uri.parse('$apiBaseUrl$path'));
      req.headers['Content-Type'] = 'application/json';
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      if (body != null) req.body = jsonEncode(body);
      final response = await http.Response.fromStream(await req.send());
      expect(
        response.statusCode,
        inInclusiveRange(200, 299),
        reason: response.body,
      );
      return response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
    }

    Future<void> control(String action) async {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:8082/$action'),
        headers: {'X-Test-Key': 'lostfound-local-integration'},
      );
      expect(res.statusCode, 200);
      if (action != 'stop') {
        for (var n = 0; n < 40; n++) {
          try {
            if ((await http.get(Uri.parse('$apiBaseUrl/health'))).statusCode ==
                200) {
              return;
            }
          } catch (_) {
            /* server starting */
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        fail('Backend did not start');
      }
    }

    await control('start');
    final tag = DateTime.now().microsecondsSinceEpoch.toString();
    final owner = await request(
      'POST',
      '/auth/register',
      body: {
        'email': 'owner$tag@example.org',
        'password': 'sample123',
        'name': 'Ирина, библиотека',
      },
    );
    final ownerToken = owner['token'] as String;
    final created = <String>[];
    for (var n = 0; n < 25; n++) {
      final item = await request(
        'POST',
        '/items',
        token: ownerToken,
        body: {
          'title': 'Синий футляр, полка ${n + 1}',
          'type': 'found',
          'description': 'Синяя ткань, серия $tag. Нашла возле окна.',
          'location': 'Библиотека',
        },
      );
      created.add('${item['id']}');
    }
    final prefs = await SharedPreferences.getInstance();
    final tokens = TokenStore(prefs);
    await tokens.clear();
    await tester.pumpWidget(LostFoundRoot(tokens: tokens));
    await tester.pumpAndSettle();
    Future<void> fill(String key, String value) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.enterText(find.byKey(Key(key)), value);
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    Future<void> waitFor(Finder finder) async {
      for (var n = 0; n < 100 && finder.evaluate().isEmpty; n++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(finder, findsOneWidget);
    }

    var converted = false;
    Future<void> capture(String name) async {
      if (!converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
        await tester.pump();
      }
      await binding.takeScreenshot(name);
    }

    await fill('email', 'missing$tag@example.org');
    await fill('password', 'incorrect123');
    await tap(find.byKey(const Key('auth-submit')));
    await waitFor(find.text('Неверная почта или пароль.'));
    await capture('01_login_error');
    GoRouter.of(tester.element(find.byType(LoginScreen))).go('/register');
    await tester.pumpAndSettle();
    await fill('name', 'Никита');
    final email = 'student$tag@example.org';
    await fill('email', email);
    await fill('password', 'sample123');
    await fill('confirmation', 'sample123');
    await tap(find.byKey(const Key('auth-submit')));
    await waitFor(find.byType(BoardScreen));
    final boardContext = tester.element(find.byType(BoardScreen));
    var model = boardContext.read<LostFoundModel>();
    final navigation = GoRouter.of(boardContext);
    final api = boardContext.read<ApiClient>();
    await capture('02_board');
    await tester.enterText(find.byKey(const Key('board-search')), tag);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(model.visibleItems.length, 20);
    await model.loadBoard(more: true);
    await tester.pumpAndSettle();
    expect(model.visibleItems.length, 25);
    expect(model.visibleItems.map((i) => i.id).toSet().length, 25);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await capture('03_server_search');
    final itemId = created.first;
    expect(
      await model.addClaim(
        Claim(
          '',
          itemId,
          model.userId,
          'Внутри футляра есть наклейка с моими инициалами.',
          '',
        ),
      ),
      isNull,
    );
    final claim = model.myClaims.first;
    expect(
      await model.send(
        Message(
          '',
          claim.id,
          model.userId,
          'Могу подойти после третьей пары.',
          '',
        ),
      ),
      isNull,
    );
    await request(
      'POST',
      '/messages',
      token: ownerToken,
      body: {
        'claimId': int.parse(claim.id),
        'text': 'Хорошо, буду у стойки библиотеки.',
      },
    );
    await model.load();
    expect(
      model.error,
      isNull,
      reason: 'refresh after the second user replied',
    );
    expect(model.thread(claim.id).length, 2);
    navigation.go('/activity/claims/${claim.id}/messages');
    await tester.pumpAndSettle();
    expect(find.text('Хорошо, буду у стойки библиотеки.'), findsOneWidget);
    await capture('04_messages');
    final image = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAFElEQVR4nGMUz45mwAaYsIoOWgkAsbIA7T4gIL4AAAAASUVORK5CYII=',
    );
    final codec = await ui.instantiateImageCodec(image);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 8);
    frame.image.dispose();
    codec.dispose();
    final upload = await api.upload(image, 'fixture.png');
    expect(upload, isA<Success<String>>());
    final photoUrl = (upload as Success<String>).value;
    navigation.go('/items/new');
    await tester.pumpAndSettle();
    await tap(find.byKey(const Key('item-type')));
    await tap(find.text('Потерял').last);
    await fill('item-title', 'Ключи от комнаты');
    await fill('item-description', 'Брелок с номером 17');
    await tap(find.byKey(const Key('item-location')));
    await tap(find.text('Общежитие №1').last);
    await tap(find.byKey(const Key('item-submit')));
    expect(model.myItems.single.title, 'Ключи от комнаты');
    expect(
      await model.saveItem(
        model.myItems.single.copyWith(imageUrl: photoUrl),
        editing: true,
      ),
      isNull,
    );
    final ownId = model.myItems.first.id;
    expect(
      (await http.get(Uri.parse('$apiBaseUrl$photoUrl'))).bodyBytes,
      image,
    );
    navigation.go('/items');
    await tester.pumpAndSettle();
    await control('stop');
    await model.load();
    await tester.pumpAndSettle();
    expect(find.textContaining('Нет связи с сервером'), findsOneWidget);
    expect(tokens.token, isNotNull);
    await capture('05_server_stopped');
    await control('start');
    await tap(find.text('Повторить'));
    expect(model.error, isNull);
    expect(model.byId(ownId)?.title, 'Ключи от комнаты');
    await capture('06_retry');
    // Rebuild the root with the token restored from real device preferences.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await prefs.reload();
    final restored = TokenStore(prefs);
    expect(restored.token, isNotNull);
    await tester.pumpWidget(LostFoundRoot(tokens: restored));
    await tester.pumpAndSettle();
    model = tester.element(find.byType(BoardScreen)).read<LostFoundModel>();
    expect(model.myItems.any((i) => i.id == ownId), isTrue);
    await control('rotate');
    await model.load();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(restored.token, isNull);
    expect(prefs.containsKey('auth_token'), isFalse);
    await capture('07_expired_session');
    await fill('email', email);
    await fill('password', 'sample123');
    await tap(find.byKey(const Key('auth-submit')));
    await waitFor(find.byType(BoardScreen));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
