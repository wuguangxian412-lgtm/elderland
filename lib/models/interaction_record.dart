import 'dialogue_message.dart';

class InteractionRecord {
  final String id;
  final String npcId;
  final String npcName;
  final String locationId;
  final String locationName;
  final String buildingId;
  final String buildingName;
  final int year;
  final String season;
  final int day;
  final int naturalHour;
  final int naturalMinute;
  final String summary;
  final List<DialogueMessage> messages;
  final String createdAt;

  InteractionRecord({
    String? id,
    required String npcId,
    required String npcName,
    required String locationId,
    required String locationName,
    required String buildingId,
    required String buildingName,
    required this.year,
    required String season,
    required this.day,
    int naturalHour = 8,
    int naturalMinute = 0,
    required String summary,
    required List<DialogueMessage> messages,
    String? createdAt,
  }) : id = (id == null || id.trim().isEmpty)
           ? 'interaction_${DateTime.now().millisecondsSinceEpoch}'
           : id.trim(),
       npcId = npcId.trim(),
       npcName = npcName.trim(),
       locationId = locationId.trim(),
       locationName = locationName.trim(),
       buildingId = buildingId.trim(),
       buildingName = buildingName.trim(),
       season = season.trim(),
       naturalHour = naturalHour.clamp(0, 23).toInt(),
       naturalMinute = naturalMinute.clamp(0, 59).toInt(),
       summary = summary.trim(),
       messages = List.unmodifiable(messages),
       createdAt = (createdAt == null || createdAt.trim().isEmpty)
           ? DateTime.now().toIso8601String()
           : createdAt.trim();

  factory InteractionRecord.fromJson(Map<String, dynamic> json) {
    return InteractionRecord(
      id: json['id'] as String?,
      npcId: json['npcId'] as String? ?? '',
      npcName: json['npcName'] as String? ?? '',
      locationId: json['locationId'] as String? ?? '',
      locationName: json['locationName'] as String? ?? '',
      buildingId: json['buildingId'] as String? ?? '',
      buildingName: json['buildingName'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      season: json['season'] as String? ?? '',
      day: (json['day'] as num?)?.toInt() ?? 0,
      naturalHour: (json['naturalHour'] as num?)?.toInt() ?? 8,
      naturalMinute: (json['naturalMinute'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? '',
      messages: _parseMessages(json['messages']),
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'npcId': npcId,
    'npcName': npcName,
    'locationId': locationId,
    'locationName': locationName,
    'buildingId': buildingId,
    'buildingName': buildingName,
    'year': year,
    'season': season,
    'day': day,
    'naturalHour': naturalHour,
    'naturalMinute': naturalMinute,
    'summary': summary,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt,
  };

  static List<DialogueMessage> _parseMessages(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => DialogueMessage.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }
}
