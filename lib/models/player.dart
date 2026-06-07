import 'game_event_record.dart';
import 'interaction_record.dart';
import 'npc_relationship.dart';

/// 玩家数据模型
class Player {
  final String name;
  final String gender;
  final int age;
  final int hp;
  final int maxHp;
  final int strength;
  final int defense;
  final int agility;
  final int charm;
  final String location;
  final String locationId;
  final int year;
  final String season;
  final int day;
  final int money;
  final String country;
  final List<String> triggeredTimelineEvents;

  /// 旧版 NPC 对话详情记录。
  ///
  /// 暂时保留，用来查看完整对话内容；后续统一经历系统稳定后，
  /// 可以考虑只保留摘要或迁移成详情数据。
  final List<InteractionRecord> interactionRecords;

  /// 统一经历记录。
  ///
  /// 用于记录对话、探索、移动、任务、物品、成长、关系等事件。
  final List<GameEventRecord> eventRecords;

  /// 重要经历记录。
  ///
  /// 只记录影响玩家人生轨迹或世界状态的重要事件。
  final List<GameEventRecord> importantEventRecords;

  /// 玩家已建立的人脉关系。
  ///
  /// 注意：这里不保存 NPC 实时位置，只保存玩家合理知道的信息。
  final List<NpcRelationship> relationships;

  const Player({
    required this.name,
    required this.gender,
    required this.age,
    required this.hp,
    required this.maxHp,
    required this.strength,
    required this.defense,
    required this.agility,
    required this.charm,
    required this.location,
    this.locationId = 'silver_leaf_village',
    required this.year,
    required this.season,
    required this.day,
    required this.money,
    this.country = '圣山王国',
    this.triggeredTimelineEvents = const [],
    this.interactionRecords = const [],
    this.eventRecords = const [],
    this.importantEventRecords = const [],
    this.relationships = const [],
  });

  /// 从 JSON 创建 Player
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      hp: (json['hp'] as num?)?.toInt() ?? 0,
      maxHp: (json['maxHp'] as num?)?.toInt() ?? 0,
      strength: (json['strength'] as num?)?.toInt() ?? 0,
      defense: (json['defense'] as num?)?.toInt() ?? 0,
      agility: (json['agility'] as num?)?.toInt() ?? 0,
      charm: (json['charm'] as num?)?.toInt() ?? 0,
      location: json['location'] as String? ?? '',
      locationId: json['locationId'] as String? ?? 'silver_leaf_village',
      country: json['country'] as String? ?? '圣山王国',
      year: (json['year'] as num?)?.toInt() ?? 0,
      season: json['season'] as String? ?? '',
      day: (json['day'] as num?)?.toInt() ?? 0,
      money: (json['money'] as num?)?.toInt() ?? 0,
      triggeredTimelineEvents:
          (json['triggeredTimelineEvents'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      interactionRecords: _parseInteractionRecords(json['interactionRecords']),
      eventRecords: _parseEventRecords(json['eventRecords']),
      importantEventRecords: _parseEventRecords(json['importantEventRecords']),
      relationships: _parseRelationships(json['relationships']),
    );
  }

  /// 转为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'age': age,
      'hp': hp,
      'maxHp': maxHp,
      'strength': strength,
      'defense': defense,
      'agility': agility,
      'charm': charm,
      'location': location,
      'locationId': locationId,
      'country': country,
      'year': year,
      'season': season,
      'day': day,
      'money': money,
      'triggeredTimelineEvents': triggeredTimelineEvents,
      'interactionRecords': interactionRecords.map((e) => e.toJson()).toList(),
      'eventRecords': eventRecords.map((e) => e.toJson()).toList(),
      'importantEventRecords': importantEventRecords.map((e) => e.toJson()).toList(),
      'relationships': relationships.map((e) => e.toJson()).toList(),
    };
  }

  /// 基于当前对象创建副本并修改指定字段
  Player copyWith({
    String? name,
    String? gender,
    int? age,
    int? hp,
    int? maxHp,
    int? strength,
    int? defense,
    int? agility,
    int? charm,
    String? location,
    String? locationId,
    String? country,
    int? year,
    String? season,
    int? day,
    int? money,
    List<String>? triggeredTimelineEvents,
    List<InteractionRecord>? interactionRecords,
    List<GameEventRecord>? eventRecords,
    List<GameEventRecord>? importantEventRecords,
    List<NpcRelationship>? relationships,
  }) {
    return Player(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      strength: strength ?? this.strength,
      defense: defense ?? this.defense,
      agility: agility ?? this.agility,
      charm: charm ?? this.charm,
      location: location ?? this.location,
      locationId: locationId ?? this.locationId,
      country: country ?? this.country,
      year: year ?? this.year,
      season: season ?? this.season,
      day: day ?? this.day,
      money: money ?? this.money,
      triggeredTimelineEvents:
          triggeredTimelineEvents ?? this.triggeredTimelineEvents,
      interactionRecords: interactionRecords ?? this.interactionRecords,
      eventRecords: eventRecords ?? this.eventRecords,
      importantEventRecords: importantEventRecords ?? this.importantEventRecords,
      relationships: relationships ?? this.relationships,
    );
  }

  static List<InteractionRecord> _parseInteractionRecords(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => InteractionRecord.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  static List<GameEventRecord> _parseEventRecords(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => GameEventRecord.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  static List<NpcRelationship> _parseRelationships(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => NpcRelationship.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }
}
