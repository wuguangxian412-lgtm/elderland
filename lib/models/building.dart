/// 建筑数据模型
class Building {
  final String id;
  final String locationId;
  final String name;
  final String type;
  final String description;
  final bool isPublic;

  const Building({
    this.id = '',
    this.locationId = '',
    this.name = '',
    this.type = '',
    this.description = '',
    this.isPublic = true,
  });

  factory Building.fromJson(
    Map<String, dynamic> json, {
    String defaultLocationId = '',
  }) {
    final rawLocationId = (json['locationId'] as String?)?.trim();
    return Building(
      id: (json['id'] as String?)?.trim() ?? '',
      locationId: rawLocationId != null && rawLocationId.isNotEmpty
          ? rawLocationId
          : defaultLocationId,
      name: (json['name'] as String?)?.trim() ?? '',
      type: (json['type'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      isPublic: json['isPublic'] is bool ? json['isPublic'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'locationId': locationId,
    'name': name,
    'type': type,
    'description': description,
    'isPublic': isPublic,
  };
}
