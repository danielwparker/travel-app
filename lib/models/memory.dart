class Memory {
  String id;
  String caption;
  String description;
  DateTime createdAt;
  DateTime assignedAt;
  String localImagePath;
  String imageUrl;

  Memory({
    required this.id,
    required this.caption,
    required this.description,
    required this.createdAt,
    required this.assignedAt,
    required this.localImagePath,
    required this.imageUrl });

  Memory copyWith({
    String? id,
    String? caption,
    String? description,
    DateTime? createdAt,
    DateTime? assignedAt,
    String? localImagePath,
    String? imageUrl, })
  {

    return Memory(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      localImagePath: localImagePath ?? this.localImagePath,
      imageUrl: imageUrl ?? this.imageUrl
    );
  }

  @override String toString() => 'Memory(id: $id, caption: $caption, assignedAt: $assignedAt, localImagePath: $localImagePath, imageUrl: $imageUrl)';
}