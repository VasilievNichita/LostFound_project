import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/entities.dart';
import '../data/repositories.dart';
import '../data/result.dart';

class LostFoundModel extends ChangeNotifier {
  LostFoundModel(
    this._itemsRepository,
    this._claimsRepository,
    this._messagesRepository, {
    this.serverPaging = false,
  });
  final bool serverPaging;
  Timer? _debounce;
  int _boardRequest = 0, _page = 0;
  bool loadingMore = false, hasMore = false;
  String? boardError;
  bool _retryMore = false;
  Future<void> retryBoard() => loadBoard(more: _retryMore);
  List<String> _boardIds = [];
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
    (serverPaging ? _boardIds.map(byId).whereType<Item>() : _items).where(
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
    if (serverPaging) {
      _boardRequest++;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () => loadBoard());
    }
  }

  void resetFilters() {
    filter(query: '', clearLocation: true);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (busy) return;
    _debounce?.cancel();
    _boardRequest++;
    loadingMore = false;
    boardError = null;
    _loading = true;
    _error = null;
    _notify();
    // Запросы независимы, но публикуем один согласованный набор данных.
    final itemRequest = _itemsRepository.fetchAll(
      type: serverPaging ? _type : null,
      search: serverPaging ? _query : null,
      location: serverPaging ? _location : null,
    );
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
        if (serverPaging) {
          _boardIds = items.map((i) => i.id).toList();
          _page = 1;
          hasMore = items.length == 20;
          // Свои объявления и вещи из заявок нужны и вне текущего фильтра доски.
          for (var page = 1; ; page++) {
            final own = await _itemsRepository.fetchAll(
              page: page,
              limit: 100,
              mine: true,
            );
            if (_disposed) return;
            if (own case Success(:final value)) {
              _mergeItems(value);
              if (value.length < 100) break;
            } else {
              _error = (own as Failure).message;
              break;
            }
          }
          for (final claim in claims) {
            if (byId(claim.itemId) != null) continue;
            final related = await _itemsRepository.fetchById(claim.itemId);
            if (_disposed) return;
            if (related case Success(:final value)) _mergeItems([value]);
          }
        }
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

  Future<String?> ensureItem(String id) async {
    if (byId(id) != null) return null;
    final result = await _itemsRepository.fetchById(id);
    if (_disposed) return null;
    switch (result) {
      case Success(:final value):
        _mergeItems([value]);
        _notify();
        return null;
      case Failure(:final message):
        return message;
    }
  }

  void _mergeItems(List<Item> values) {
    final byId = {for (final item in _items) item.id: item};
    for (final item in values) {
      byId[item.id] = item;
    }
    _items = byId.values.toList();
  }

  Future<void> loadBoard({bool more = false}) async {
    if (_disposed ||
        !serverPaging ||
        busy ||
        (more && (loadingMore || !hasMore))) {
      return;
    }
    _debounce?.cancel();
    _retryMore = more;
    final request = ++_boardRequest;
    final page = more ? _page + 1 : 1;
    loadingMore = true;
    boardError = null;
    _notify();
    final result = await _itemsRepository.fetchAll(
      page: page,
      search: _query.trim(),
      type: _type,
      location: _location,
    );
    if (_disposed || request != _boardRequest) return;
    loadingMore = false;
    switch (result) {
      case Success(:final value):
        _mergeItems(value);
        _boardIds = {
          ...(more ? _boardIds : <String>[]),
          ...value.map((i) => i.id),
        }.toList();
        _page = page;
        hasMore = value.length == 20;
      case Failure(:final message):
        boardError = message;
    }
    _notify();
  }

  // Одна запись за раз: двойной tap и reload не могут затереть новый результат.
  Future<String?> _write<T>(
    Future<Result<T>> Function() request,
    void Function(T) apply,
  ) async {
    if (busy || loadingMore) return 'Дождитесь завершения текущей операции.';
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
      if (serverPaging && !_boardIds.contains(item.id)) {
        _boardIds.insert(0, item.id);
      }
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
