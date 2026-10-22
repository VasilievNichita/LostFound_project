import 'entities.dart';
import 'mock_data.dart' as seed;
import 'repositories.dart';
import 'result.dart';

// Одно хранилище для связей вещь -> заявка -> сообщения.
// На перезапуске создаётся заново; диска и сети в L4 нет.
class MockStore {
  MockStore({this.delay = const Duration(milliseconds: 650)});
  final Duration delay;
  bool simulateError = false;
  final _items = List<Item>.of(seed.allItems);
  final _claims = List<Claim>.of(seed.claims);
  final _messages = List<Message>.of(seed.messages);
  int _itemSequence = 100, _claimSequence = 100, _messageSequence = 100;
  final campus = CampusData(
    userId: seed.currentUserId,
    name: 'Никита Васильев',
    email: 'nichita.vasiliev@iis.utm.md',
    group: 'Студент · CR-232',
    university: 'Технический университет Молдовы',
    locations: seed.locations,
    names: seed.userNames,
  );

  Future<Result<T>> request<T>(Result<T> Function() action) async {
    await Future<void>.delayed(delay);
    if (simulateError) {
      return const Failure('Хранилище недоступно. Попробуйте ещё раз.');
    }
    return action();
  }

  void removeClaim(String id) {
    _claims.removeWhere((c) => c.id == id);
    _messages.removeWhere((m) => m.claimId == id);
  }
}

class MockItemRepository implements ItemRepository {
  MockItemRepository(this.store);
  final MockStore store;
  @override
  Future<Result<CampusData>> fetchCampus() =>
      store.request(() => Success(store.campus));
  @override
  Future<Result<List<Item>>> fetchAll() =>
      store.request(() => Success(List.unmodifiable(store._items)));
  @override
  Future<Result<Item>> fetchById(String id) => store.request(() {
    final item = store._items.where((i) => i.id == id).firstOrNull;
    return item == null
        ? const Failure('Объявление не найдено.')
        : Success(item);
  });
  String? _check(Item item) {
    if (item.title.trim().isEmpty ||
        item.title.trim().length > 80 ||
        item.description.trim().length > 500 ||
        !['lost', 'found'].contains(item.type) ||
        !store.campus.locations.contains(item.location)) {
      return 'Проверьте название, тип и место объявления.';
    }
    if (item.userId != store.campus.userId) {
      return 'Можно менять только свои объявления.';
    }
    return null;
  }

  @override
  Future<Result<Item>> create(Item draft) => store.request(() {
    final error = _check(draft);
    if (error != null) return Failure(error);
    final now = DateTime.now();
    final item = draft.copyWith(
      id: 'i${store._itemSequence++}',
      title: draft.title.trim(),
      description: draft.description.trim(),
      dateLabel: '${now.day}.${now.month}.${now.year}',
      statusLabel: draft.type == 'found' ? 'Ищет владельца' : 'Поиск',
    );
    store._items.insert(0, item);
    return Success(item);
  });
  @override
  Future<Result<Item>> update(Item item) => store.request(() {
    final index = store._items.indexWhere((i) => i.id == item.id);
    if (index < 0) return const Failure('Объявление не найдено.');
    if (store._items[index].userId != store.campus.userId) {
      return const Failure('Это чужое объявление.');
    }
    final error = _check(item);
    if (error != null) return Failure(error);
    store._items[index] = item;
    return Success(item);
  });
  @override
  Future<Result<void>> delete(String id) => store.request(() {
    final item = store._items.where((i) => i.id == id).firstOrNull;
    if (item == null) return const Failure('Объявление не найдено.');
    if (item.userId != store.campus.userId) {
      return const Failure('Это чужое объявление.');
    }
    for (final claim in store._claims.where((c) => c.itemId == id).toList()) {
      store.removeClaim(claim.id);
    }
    store._items.removeWhere((i) => i.id == id);
    return const Success(null);
  });
}

class MockClaimRepository implements ClaimRepository {
  MockClaimRepository(this.store);
  final MockStore store;
  @override
  Future<Result<List<Claim>>> fetchAll() =>
      store.request(() => Success(List.unmodifiable(store._claims)));
  @override
  Future<Result<Claim>> fetchById(String id) => store.request(() {
    final claim = store._claims.where((c) => c.id == id).firstOrNull;
    return claim == null ? const Failure('Заявка не найдена.') : Success(claim);
  });
  @override
  Future<Result<Claim>> create(Claim draft) => store.request(() {
    final item = store._items.where((i) => i.id == draft.itemId).firstOrNull;
    if (item == null) return const Failure('Объявление удалено.');
    if (item.userId == store.campus.userId ||
        item.statusLabel == 'Возвращено') {
      return const Failure(
        'На своё или закрытое объявление нельзя подать заявку.',
      );
    }
    if (draft.userId != store.campus.userId ||
        draft.message.trim().length < 10 ||
        draft.message.trim().length > 600) {
      return const Failure('Опишите примету вещи: от 10 до 600 символов.');
    }
    if (store._claims.any(
      (c) =>
          c.itemId == draft.itemId &&
          c.userId == draft.userId &&
          c.status != 'Закрыта',
    )) {
      return const Failure(
        'У вас уже есть открытая заявка. Переписка находится в разделе «Мои».',
      );
    }
    final claim = draft.copyWith(
      id: 'c${store._claimSequence++}',
      message: draft.message.trim(),
      status: 'Проверяется',
    );
    store._claims.insert(0, claim);
    return Success(claim);
  });
  @override
  Future<Result<Claim>> update(Claim claim) => store.request(() {
    final index = store._claims.indexWhere((c) => c.id == claim.id);
    if (index < 0) return const Failure('Заявка не найдена.');
    final old = store._claims[index];
    if (old.userId != store.campus.userId ||
        claim.userId != old.userId ||
        claim.itemId != old.itemId ||
        !['Проверяется', 'Обсуждение', 'Закрыта'].contains(claim.status) ||
        claim.message.trim().length < 10 ||
        claim.message.trim().length > 600) {
      return const Failure('Недопустимое изменение заявки.');
    }
    store._claims[index] = claim;
    return Success(claim);
  });
  @override
  Future<Result<void>> delete(String id) => store.request(() {
    final claim = store._claims.where((c) => c.id == id).firstOrNull;
    if (claim == null) return const Failure('Заявка не найдена.');
    if (claim.userId != store.campus.userId) {
      return const Failure('Это чужая заявка.');
    }
    store.removeClaim(id);
    return const Success(null);
  });
}

class MockMessageRepository implements MessageRepository {
  MockMessageRepository(this.store);
  final MockStore store;
  @override
  Future<Result<List<Message>>> fetchAll() =>
      store.request(() => Success(List.unmodifiable(store._messages)));
  @override
  Future<Result<Message>> create(Message draft) => store.request(() {
    final claim = store._claims.where((c) => c.id == draft.claimId).firstOrNull;
    if (claim == null) return const Failure('Заявка удалена.');
    final item = store._items.where((i) => i.id == claim.itemId).firstOrNull;
    if (claim.status == 'Закрыта' ||
        item == null ||
        item.statusLabel == 'Возвращено') {
      return const Failure('Переписка закрыта.');
    }
    if (draft.senderId != store.campus.userId ||
        (claim.userId != draft.senderId && item.userId != draft.senderId)) {
      return const Failure('Это чужая переписка.');
    }
    if (draft.text.trim().isEmpty || draft.text.trim().length > 1000) {
      return const Failure('Введите сообщение до 1000 символов.');
    }
    final now = DateTime.now();
    final message = draft.copyWith(
      id: 'm${store._messageSequence++}',
      text: draft.text.trim(),
      sentAt:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    store._messages.add(message);
    return Success(message);
  });
  @override
  Future<Result<void>> delete(String id) => store.request(() {
    final message = store._messages.where((m) => m.id == id).firstOrNull;
    if (message == null) return const Failure('Сообщение не найдено.');
    if (message.senderId != store.campus.userId) {
      return const Failure('Это чужое сообщение.');
    }
    store._messages.removeWhere((m) => m.id == id);
    return const Success(null);
  });
}
