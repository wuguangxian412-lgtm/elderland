/// 地图节点数据模型
class MapNode {
  final String id;
  final String name;
  final String type;
  final String description;
  final String country;
  final List<int> coordinates;
  final List<String> connectedNodes;

  /// 节点类型 → 显示层级（数字越小越优先显示，0=村庄, 1=城市, 2=其他）
  static const Map<String, int> typeTierMap = {
    '村庄': 0,
    '城市': 1,
    '荒野': 2,
    '要塞': 2,
  };
  static const int _defaultTier = 2;

  /// 此节点的显示层级
  int get typeTier => typeTierMap[type] ?? _defaultTier;

  const MapNode({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.country,
    required this.coordinates,
    required this.connectedNodes,
  });

  factory MapNode.fromJson(String id, Map<String, dynamic> json) {
    return MapNode(
      id: id,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      country: json['country'] as String? ?? '',
      coordinates: _parseCoordinates(json['coordinates']),
      connectedNodes: _parseStringList(json['connected_nodes']),
    );
  }

  static List<int> _parseCoordinates(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<num>().map((e) => e.toInt()).toList();
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<String>().toList();
  }
}
