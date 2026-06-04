/// NPC 数据模型
class Npc {
  final String id;
  final String name;
  String locationId;
  String state;
  final Map<String, dynamic> personality;
  final Map<String, dynamic> memory;
  final List<Map<String, dynamic>> history;

  Npc({
    required this.id,
    required this.name,
    required this.locationId,
    this.state = 'idle',
    this.personality = const {},
    this.memory = const {},
    this.history = const [],
  });

  factory Npc.fromJson(Map<String, dynamic> json) {
    // 安全解析 history：过滤非 Map 元素，避免 AI 生成脏数据导致崩溃
    List<Map<String, dynamic>> parseHistory(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => Map<String, dynamic>.from(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          )
          .toList();
    }

    return Npc(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      locationId: (json['locationId'] as String?)?.trim() ?? '',
      state: (json['state'] as String?)?.trim() ?? 'idle',
      personality: json['personality'] is Map
          ? Map<String, dynamic>.from(
              (json['personality'] as Map).map(
                (k, v) => MapEntry(k.toString(), v),
              ),
            )
          : {},
      memory: json['memory'] is Map
          ? Map<String, dynamic>.from(
              (json['memory'] as Map).map((k, v) => MapEntry(k.toString(), v)),
            )
          : {},
      history: parseHistory(json['history']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'locationId': locationId,
    'state': state,
    'personality': personality,
    'memory': memory,
    'history': history,
  };

  @override
  String toString() => 'Npc($id: $name @ $locationId [$state])';
}
