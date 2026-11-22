import 'api_client.dart';
import 'entities.dart';
import 'repositories.dart';
import 'result.dart';

String _id(dynamic value) => (value as int).toString();
String _date(String value) {
  final date = DateTime.parse(value).toLocal();
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

Item itemFromJson(dynamic data) {
  final j = data as Map<String, dynamic>;
  return Item(
    _id(j['id']),
    _id(j['userId']),
    j['type'] as String,
    j['title'] as String,
    j['description'] as String,
    j['imageUrl'] as String,
    j['location'] as String,
    _date(j['createdAt'] as String),
    j['status'] == 'returned'
        ? 'Возвращено'
        : (j['type'] == 'found' ? 'Ищет владельца' : 'Поиск'),
  );
}

Map<String, dynamic> itemToJson(Item item) => {
  'type': item.type,
  'title': item.title,
  'description': item.description,
  'imageUrl': item.imageUrl,
  'location': item.location,
  'status': item.statusLabel == 'Возвращено' ? 'returned' : 'open',
};
Claim claimFromJson(dynamic data) {
  final j = data as Map<String, dynamic>;
  return Claim(
    _id(j['id']),
    _id(j['itemId']),
    _id(j['userId']),
    j['message'] as String,
    switch (j['status']) {
      'closed' => 'Закрыта',
      'discussion' => 'Обсуждение',
      _ => 'На рассмотрении',
    },
  );
}

Message messageFromJson(dynamic data) {
  final j = data as Map<String, dynamic>;
  final date = DateTime.parse(j['sentAt'] as String).toLocal();
  return Message(
    _id(j['id']),
    _id(j['claimId']),
    _id(j['senderId']),
    j['text'] as String,
    '${_date(j['sentAt'] as String)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
  );
}

// Для связанных записей забираем все страницы: переписка не обрывается на 20-й строке.
Future<Result<List<T>>> allPages<T>(
  ApiClient api,
  String path,
  T Function(dynamic) decode, {
  Map<String, String> query = const {},
}) async {
  final values = <T>[];
  for (var page = 1; ; page++) {
    final result = await api.request<(List<T>, int)>(
      'GET',
      path,
      (j) => ((j['items'] as List).map(decode).toList(), j['total'] as int),
      query: {...query, 'page': '$page', 'limit': '100'},
    );
    switch (result) {
      case Failure(:final message):
        return Failure(message);
      case Success(:final value):
        values.addAll(value.$1);
        if (values.length >= value.$2 || value.$1.isEmpty) {
          return Success(values);
        }
    }
  }
}

class HttpItemRepository implements ItemRepository {
  HttpItemRepository(this.api);
  final ApiClient api;
  @override
  Future<Result<List<Item>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
    String? type,
    String? location,
    bool mine = false,
  }) => api.request(
    'GET',
    '/items',
    (j) => (j['items'] as List).map(itemFromJson).toList(),
    query: {
      'page': '$page',
      'limit': '$limit',
      'search': ?search,
      'type': ?type,
      'location': ?location,
      if (mine) 'mine': '1',
    },
  );
  @override
  Future<Result<Item>> fetchById(String id) =>
      api.request('GET', '/items/$id', itemFromJson);
  @override
  Future<Result<Item>> create(Item draft) =>
      api.request('POST', '/items', itemFromJson, body: itemToJson(draft));
  @override
  Future<Result<Item>> update(Item item) => api.request(
    'PUT',
    '/items/${item.id}',
    itemFromJson,
    body: itemToJson(item),
  );
  @override
  Future<Result<void>> delete(String id) =>
      api.request('DELETE', '/items/$id', (_) {});
  @override
  Future<Result<CampusData>> fetchCampus() => api.request(
    'GET',
    '/campus',
    (j) => CampusData(
      userId: j['userId'] as String,
      name: j['name'] as String,
      email: j['email'] as String,
      group: j['group'] as String,
      university: j['university'] as String,
      locations: (j['locations'] as List).cast<String>(),
      names: (j['names'] as Map).cast<String, String>(),
    ),
  );
}

class HttpClaimRepository implements ClaimRepository {
  HttpClaimRepository(this.api);
  final ApiClient api;
  @override
  Future<Result<List<Claim>>> fetchAll() =>
      allPages(api, '/claims', claimFromJson);
  @override
  Future<Result<Claim>> fetchById(String id) =>
      api.request('GET', '/claims/$id', claimFromJson);
  @override
  Future<Result<Claim>> create(Claim draft) => api.request(
    'POST',
    '/claims',
    claimFromJson,
    body: {'itemId': int.parse(draft.itemId), 'message': draft.message},
  );
  @override
  Future<Result<Claim>> update(Claim claim) => api.request(
    'PUT',
    '/claims/${claim.id}',
    claimFromJson,
    body: {
      'message': claim.message,
      'status': switch (claim.status) {
        'Закрыта' => 'closed',
        'Обсуждение' => 'discussion',
        _ => 'pending',
      },
    },
  );
  @override
  Future<Result<void>> delete(String id) =>
      api.request('DELETE', '/claims/$id', (_) {});
}

class HttpMessageRepository implements MessageRepository {
  HttpMessageRepository(this.api);
  final ApiClient api;
  @override
  Future<Result<List<Message>>> fetchAll() =>
      allPages(api, '/messages', messageFromJson);
  @override
  Future<Result<Message>> create(Message draft) => api.request(
    'POST',
    '/messages',
    messageFromJson,
    body: {'claimId': int.parse(draft.claimId), 'text': draft.text},
  );
  @override
  Future<Result<void>> delete(String id) =>
      api.request('DELETE', '/messages/$id', (_) {});
}
