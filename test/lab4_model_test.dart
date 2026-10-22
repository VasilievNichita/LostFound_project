import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/data/entities.dart';
import 'package:lost_found/data/mock_repositories.dart';
import 'package:lost_found/data/result.dart';
import 'package:lost_found/models/lost_found_model.dart';

void main() {
  late MockStore store;
  late MockItemRepository items;
  late MockClaimRepository claims;
  late MockMessageRepository messages;
  late LostFoundModel model;
  setUp(() {
    store = MockStore(delay: Duration.zero);
    items = MockItemRepository(store);
    claims = MockClaimRepository(store);
    messages = MockMessageRepository(store);
    model = LostFoundModel(items, claims, messages);
  });
  tearDown(() => model.dispose());
  Item draft() => Item(
    'ignored',
    'u-nichita',
    'found',
    'Футляр для очков',
    'Синяя ткань',
    '',
    'Библиотека',
    '',
    '',
  );

  test(
    'Загрузка извещает о начале и конце, наружу коллекции read-only',
    () async {
      final loading = <bool>[];
      model.addListener(() => loading.add(model.isLoading));
      await model.load();
      expect(loading, [true, false]);
      expect(model.items.length, 16);
      expect(() => model.items.clear(), throwsUnsupportedError);
      expect(() => model.claims.clear(), throwsUnsupportedError);
      expect(() => model.messages.clear(), throwsUnsupportedError);
      expect(() => model.campus!.locations.clear(), throwsUnsupportedError);
      expect(() => model.campus!.names.clear(), throwsUnsupportedError);
    },
  );
  test(
    'Поиск по примете, типу и месту; фильтры сохраняются после загрузки',
    () async {
      await model.load();
      model.filter(query: ' ЗЕЛЕНЫЙ ', location: 'Библиотека');
      expect(model.visibleItems, isEmpty);
      model.filter(type: 'lost', query: 'флешка');
      expect(model.visibleItems.single.id, 'i10');
      await model.load();
      expect(model.visibleItems.single.id, 'i10');
      model.resetFilters();
      expect(model.visibleItems.length, 8);
    },
  );
  test('CRUD выдаёт ID, обновляет подписчиков, отсутствующие ID возвращают Failure', () async {
    await model.load();
    var changes = 0;
    model.addListener(() => changes++);
    expect(await model.saveItem(draft(), editing: false), isNull);
    final created = model.items.first;
    expect(created.id, isNot('ignored'));
    expect(model.myItems.length, 9);
    expect(
      await model.saveItem(
        created.copyWith(title: 'Синий футляр'),
        editing: true,
      ),
      isNull,
    );
    expect(model.byId(created.id)!.title, 'Синий футляр');
    expect(await model.closeItem(model.byId(created.id)!), isNull);
    expect(model.byId(created.id)!.statusLabel, 'Возвращено');
    expect(await model.removeItem(created.id), isNull);
    expect(model.myItems.length, 8);
    expect(changes, 8);
    expect(await items.fetchById(created.id), isA<Failure<Item>>());
    expect(await items.delete(created.id), isA<Failure<void>>());
    expect(await items.update(created), isA<Failure<Item>>());
  });
  test(
    'Авария всех методов не меняет данные, retry восстанавливает загрузку',
    () async {
      await model.load();
      final before = model.items;
      store.simulateError = true;
      expect(await items.fetchCampus(), isA<Failure<CampusData>>());
      expect(await items.fetchById('i1'), isA<Failure<Item>>());
      expect(await model.saveItem(draft(), editing: false), isNotNull);
      expect(await model.removeItem('i9'), isNotNull);
      expect(await model.closeItem(model.byId('i9')!), isNotNull);
      expect(await claims.fetchAll(), isA<Failure<List<Claim>>>());
      expect(await claims.fetchById('c1'), isA<Failure<Claim>>());
      expect(
        await claims.create(
          const Claim('', 'i2', 'u-nichita', 'Синяя метка внутри', ''),
        ),
        isA<Failure<Claim>>(),
      );
      expect(await claims.update(model.claims.first), isA<Failure<Claim>>());
      expect(await claims.delete('c1'), isA<Failure<void>>());
      expect(await messages.fetchAll(), isA<Failure<List<Message>>>());
      expect(
        await messages.create(
          const Message('', 'c1', 'u-nichita', 'Привет', ''),
        ),
        isA<Failure<Message>>(),
      );
      expect(await messages.delete('m1'), isA<Failure<void>>());
      expect(model.items, before);
      await model.load();
      expect(model.error, isNotNull);
      expect(model.isLoading, isFalse);
      store.simulateError = false;
      await model.load();
      expect(model.error, isNull);
      expect(model.items, before);
    },
  );
  test(
    'Заявка и сообщения связаны, удаление заявки убирает её переписку',
    () async {
      await model.load();
      expect(
        await model.addClaim(
          const Claim(
            '',
            'i2',
            'u-nichita',
            'На обратной стороне номер 42',
            '',
          ),
        ),
        isNull,
      );
      final claim = model.claims.first;
      expect(
        await model.send(
          Message('', claim.id, model.userId, 'Встречаемся у входа', ''),
        ),
        isNull,
      );
      expect(model.thread(claim.id).single.text, 'Встречаемся у входа');
      expect(model.thread('c1').length, 8);
      expect(
        await model.addClaim(
          const Claim(
            '',
            'i2',
            'u-nichita',
            'На обратной стороне номер 42',
            '',
          ),
        ),
        isNotNull,
      );
      expect(await model.removeClaim(claim.id), isNull);
      expect(model.thread(claim.id), isEmpty);
      expect(
        (await messages.fetchAll() as Success<List<Message>>).value.any(
          (m) => m.claimId == claim.id,
        ),
        isFalse,
      );
    },
  );
  test('Закрытая вещь, чужая запись и отсутствующая заявка защищены', () async {
    await model.load();
    expect(
      await model.addClaim(
        const Claim('', 'i4', 'u-nichita', 'Наклейка на дне', ''),
      ),
      isNotNull,
    );
    expect(
      await model.addClaim(
        const Claim('', 'i9', 'u-nichita', 'Наклейка на дне', ''),
      ),
      isNotNull,
    );
    expect(await model.removeItem('i1'), isNotNull);
    expect(
      await model.saveItem(
        model.byId('i1')!.copyWith(userId: model.userId),
        editing: true,
      ),
      isNotNull,
    );
    expect(
      await model.send(const Message('', 'absent', 'u-nichita', 'Привет', '')),
      isNotNull,
    );
    expect(await model.removeMessage('m2'), isNotNull);
    expect(await model.removeMessage('m1'), isNull);
    expect(model.thread('c1').length, 7);
  });
  test(
    'Повторная запись блокируется, reload не затирает ожидаемую мутацию',
    () async {
      await model.load();
      final pending = model.saveItem(draft(), editing: false);
      expect(await model.saveItem(draft(), editing: false), isNotNull);
      await model.load();
      await pending;
      expect(model.items.length, 17);
      final freshStore = MockStore(delay: Duration.zero);
      expect(
        (await MockItemRepository(freshStore).fetchAll() as Success<List<Item>>)
            .value
            .length,
        16,
      );
    },
  );
}
