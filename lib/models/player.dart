import 'interaction_record.dart';

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
  final List<InteractionRecord> interactionRecords;

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
}
