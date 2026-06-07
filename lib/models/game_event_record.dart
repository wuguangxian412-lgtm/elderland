/// 统一经历 / 事件记录模型
///
/// 这个模型用于记录玩家在世界中发生过的结构化事件。
/// 它不是只服务 UI 的文本日志，后续也会作为 AI 叙事上下文、
/// NPC 记忆摘要、任务和世界模拟的基础材料。
class GameEventRecord {
  static const String typeDialogue = 'dialogue';
  static const String typeExploration = 'exploration';
  static const String typeMovement = 'movement';
  static const String typeTask = 'task';
  static const String typeItem = 'item';
  static const String typeGrowth = 'growth';
  static const String typeRelationship = 'relationship';

  final String id;
  final String type;
  final String title;
  final String summary;
  final int year;
  final String season;
  final int day;
  final String locationId;
  final String locationName;
  final String buildingId;
  final String buildingName;
  final List<String> npcIds;
  final List<String> npcNames;
  final String result;
  final bool isImportant;
  final Map<String, dynamic> metadata;
  final String createdAt;

  GameEventRecord({
    String? id,
    required String type,
    required String title,
    required String summary,
    required this.year,
    required String season,
    required this.day,
    String locationId = '',
    String locationName = '',
    String buildingId = '',
    String buildingName = '',
    List<String> npcIds = const [],
    List<String> npcNames = const [],
    String result = '',
    this.isImportant = false,
    Map<String, dynamic> metadata = const {},
    String? createdAt,
  }) : id = (id == null || id.trim().isEmpty)
           ? 'event_${DateTime.now().millisecondsSinceEpoch}'
           : id.trim(),
       type = type.trim().isEmpty ? typeDialogue : type.trim(),
       title = title.trim(),
       summary = summary.trim(),
       season = season.trim(),
       locationId = locationId.trim(),
       locationName = locationName.trim(),
       buildingId = buildingId.trim(),
       buildingName = buildingName.trim(),
       npcIds = List.unmodifiable(npcIds.map((e) => e.trim()).where((e) => e.isNotEmpty)),
       npcNames = List.unmodifiable(npcNames.map((e) => e.trim()).where((e) => e.isNotEmpty)),
       result = result.trim(),
       metadata = Map.unmodifiable(metadata),
       createdAt = (createdAt == null || createdAt.trim().isEmpty)
           ? DateTime.now().toIso8601String()
           : createdAt.trim();

  factory GameEventRecord.fromJson(Map<String, dynamic> json) {
    return GameEventRecord(
      id: json['id'] as String?,
      type: json['type'] as String? ?? typeDialogue,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      season: json['season'] as String? ?? '',
      day: (json['day'] as num?)?.toInt() ?? 0,
      locationId: json['locationId'] as String? ?? '',
      locationName: json['locationName'] as String? ?? '',
      buildingId: json['buildingId'] as String? ?? '',
      buildingName: json['buildingName'] as String? ?? '',
      npcIds: _parseStringList(json['npcIds']),
      npcNames: _parseStringList(json['npcNames']),
      result: json['result'] as String? ?? '',
      isImportant: json['isImportant'] as bool? ?? false,
      metadata: _parseMap(json['metadata']),
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'summary': summary,
    'year': year,
    'season': season,
    'day': day,
    'locationId': locationId,
    'locationName': locationName,
    'buildingId': buildingId,
    'buildingName': buildingName,
    'npcIds': npcIds,
    'npcNames': npcNames,
    'result': result,
    'isImportant': isImportant,
    'metadata': metadata,
    'createdAt': createdAt,
  };

  String get typeLabel {
    switch (type) {
      case typeDialogue:
        return '对话';
      case typeExploration:
        return '探索';
      case typeMovement:
        return '移动';
      case typeTask:
        return '任务';
      case typeItem:
        return '物品';
      case typeGrowth:
        return '成长';
      case typeRelationship:
        return '关系';
      default:
        return '记录';
    }
  }

  String get timeLabel => '神圣历${year}年 $season Day $day';

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Object>()
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> _parseMap(dynamic raw) {
    if (raw is! Map) return {};
    return Map<String, dynamic>.from(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
