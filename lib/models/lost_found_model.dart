import 'package:flutter/foundation.dart';

import '../data/entities.dart';
import '../data/repositories.dart';
import '../data/result.dart';

class LostFoundModel extends ChangeNotifier {
  LostFoundModel(
    this._itemsRepository,
    this._claimsRepository,
    this._messagesRepository,
  );
  final ItemRepository _itemsRepository;
  final ClaimRepository _claimsRepository;
  final MessageRepository _messagesRepository;
  List<Item> _items = [];
  List<Claim> _claims = [];
  List<Message> _messages = [];
  CampusData? _campus;
  bool _loading = false, _saving = false, _disposed = false;
  String? _error;
  String _type = 'found', _query = '';
  String? _location;
  List<Item> get items => List.unmodifiable(_items);
  List<Claim> get claims => List.unmodifiable(_claims);
  List<Message> get messages => List.unmodifiable(_messages);
  CampusData? get campus => _campus;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  bool get busy => _loading || _saving;
  String? get error => _error;
  String get type => _type;
  String get query => _query;
  String? get location => _location;
  String get userId => _campus?.userId ?? '';
  List<String> get locations => _campus?.locations ?? const [];
  String userName(String id) => _campus?.names[id] ?? id;
  Item? byId(String id) => _items.where((i) => i.id == id).firstOrNull;
  Claim? claimById(String id) => _claims.where((c) => c.id == id).firstOrNull;
  List<Item> get myItems =>
      List.unmodifiable(_items.where((i) => i.userId == userId));
  List<Claim> get myClaims => List.unmodifiable(
    _claims.where(
      (c) => c.userId == userId || byId(c.itemId)?.userId == userId,
    ),
  );
  List<Message> thread(String id) =>
      List.unmodifiable(_messages.where((m) => m.claimId == id));
  List<Item> get visibleItems => List.unmodifiable(
    _items.where(
      (i) =>
          i.type == _type &&
          (_location == null || i.location == _location) &&
          '${i.title} ${i.description}'.toLowerCase().contains(
            _query.trim().toLowerCase(),
          ),
    ),
  );

  void filter({
    String? type,
    String? query,
    String? location,
    bool clearLocation = false,
  }) {
    _type = type ?? _type;
    _query = query ?? _query;
    _location = clearLocation ? null : location ?? _location;
    _notify();
  }

  void resetFilters() {
    _query = '';
    _location = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (busy) return;
    _loading = true;
    _error = null;
    _notify();
    // Запросы независимы, но публикуем один согласованный набор данных.
    final itemRequest = _itemsRepository.fetchAll();
    final claimRequest = _claimsRepository.fetchAll();
    final messageRequest = _messagesRepository.fetchAll();
    final campusRequest = _itemsRepository.fetchCampus();
    final results = (
      await itemRequest,
      await claimRequest,
      await messageRequest,
      await campusRequest,
    );
    if (_disposed) return;
    switch (results) {
      case (
        Success(value: final items),
        Success(value: final claims),
        Success(value: final messages),
        Success(value: final campus),
      ):
        _items = items;
        _claims = claims;
        _messages = messages;
        _campus = campus;
      case (Failure(message: final error), _, _, _):
        _error = error;
      case (_, Failure(message: final error), _, _):
        _error = error;
      case (_, _, Failure(message: final error), _):
        _error = error;
      case (_, _, _, Failure(message: final error)):
        _error = error;
    }
    _loading = false;
    _notify();
  }

  // Одна запись за раз: двойной tap и reload не могут затереть новый результат.
  Future<String?> _write<T>(
    Future<Result<T>> Function() request,
    void Function(T) apply,
  ) async {
    if (busy) return 'Дождитесь завершения текущей операции.';
    _saving = true;
    _notify();
    final result = await request();
    if (_disposed) return null;
    _saving = false;
    switch (result) {
      case Success(:final value):
        apply(value);
        _notify();
        return null;
      case Failure(:final message):
        _notify();
        return message;
    }
  }

  Future<String?> saveItem(Item draft, {required bool editing}) => _write(
    () => editing
        ? _itemsRepository.update(draft)
        : _itemsRepository.create(draft),
    (item) {
      _items = editing
          ? [
              for (final old in _items)
                if (old.id == item.id) item else old,
            ]
          : [item, ..._items];
    },
  );
  Future<String?> closeItem(Item item) =>
      saveItem(item.copyWith(statusLabel: 'Возвращено'), editing: true);
  Future<String?> removeItem(String id) => _write(
    () => _itemsRepository.delete(id),
    (_) {
      final removed = _claims
          .where((c) => c.itemId == id)
          .map((c) => c.id)
          .toSet();
      _items = _items.where((i) => i.id != id).toList();
      _claims = _claims.where((c) => c.itemId != id).toList();
      _messages = _messages.where((m) => !removed.contains(m.claimId)).toList();
    },
  );
  Future<String?> addClaim(Claim draft) =>
      _write(() => _claimsRepository.create(draft), (claim) {
        _claims = [claim, ..._claims];
      });
  Future<String?> removeClaim(String id) =>
      _write(() => _claimsRepository.delete(id), (_) {
        _claims = _claims.where((c) => c.id != id).toList();
        _messages = _messages.where((m) => m.claimId != id).toList();
      });
  Future<String?> send(Message draft) =>
      _write(() => _messagesRepository.create(draft), (message) {
        _messages = [..._messages, message];
      });
  Future<String?> removeMessage(String id) =>
      _write(() => _messagesRepository.delete(id), (_) {
        _messages = _messages.where((m) => m.id != id).toList();
      });
}
