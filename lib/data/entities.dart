// Локальные данные L2. dateLabel и statusLabel — поля представления,
// а не утверждение о наличии этих полей в контракте backend.
class Item {
  const Item(
    this.id,
    this.userId,
    this.type,
    this.title,
    this.description,
    this.imageUrl,
    this.location,
    this.dateLabel,
    this.statusLabel,
  );
  final String id, userId, type, title, description, imageUrl, location;
  final String dateLabel, statusLabel;
  Item copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    String? location,
    String? dateLabel,
    String? statusLabel,
  }) => Item(
    id ?? this.id,
    userId ?? this.userId,
    type ?? this.type,
    title ?? this.title,
    description ?? this.description,
    imageUrl ?? this.imageUrl,
    location ?? this.location,
    dateLabel ?? this.dateLabel,
    statusLabel ?? this.statusLabel,
  );
}

class Claim {
  const Claim(this.id, this.itemId, this.userId, this.message, this.status);
  final String id, itemId, userId, message, status;
  Claim copyWith({
    String? id,
    String? itemId,
    String? userId,
    String? message,
    String? status,
  }) => Claim(
    id ?? this.id,
    itemId ?? this.itemId,
    userId ?? this.userId,
    message ?? this.message,
    status ?? this.status,
  );
}

class Message {
  const Message(this.id, this.claimId, this.senderId, this.text, this.sentAt);
  final String id, claimId, senderId, text, sentAt;
  Message copyWith({
    String? id,
    String? claimId,
    String? senderId,
    String? text,
    String? sentAt,
  }) => Message(
    id ?? this.id,
    claimId ?? this.claimId,
    senderId ?? this.senderId,
    text ?? this.text,
    sentAt ?? this.sentAt,
  );
}

class CampusData {
  CampusData({
    required this.userId,
    required this.name,
    required this.email,
    required this.group,
    required this.university,
    required List<String> locations,
    required Map<String, String> names,
  }) : locations = List.unmodifiable(locations),
       names = Map.unmodifiable(names);
  final String userId, name, email, group, university;
  final List<String> locations;
  final Map<String, String> names;
}
