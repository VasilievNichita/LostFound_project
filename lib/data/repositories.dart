import 'entities.dart';
import 'result.dart';

abstract interface class ItemRepository {
  Future<Result<List<Item>>> fetchAll();
  Future<Result<Item>> fetchById(String id);
  Future<Result<Item>> create(Item draft);
  Future<Result<Item>> update(Item item);
  Future<Result<void>> delete(String id);
  Future<Result<CampusData>> fetchCampus();
}

abstract interface class ClaimRepository {
  Future<Result<List<Claim>>> fetchAll();
  Future<Result<Claim>> fetchById(String id);
  Future<Result<Claim>> create(Claim draft);
  Future<Result<Claim>> update(Claim claim);
  Future<Result<void>> delete(String id);
}

abstract interface class MessageRepository {
  Future<Result<List<Message>>> fetchAll();
  Future<Result<Message>> create(Message draft);
  Future<Result<void>> delete(String id);
}
