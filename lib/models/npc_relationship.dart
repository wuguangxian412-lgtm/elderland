/// 玩家与 NPC 的关系模型
///
/// 注意：这里不记录 NPC 实时位置，避免人脉系统变成全知雷达。
/// 只记录玩家合理知道的信息：基本身份、亲密度、上次互动地点与摘要。
class NpcRelationship {
  final String npcId;
  final String npcName;
  final String knownIdentity;
  final int affinity;
  final int interactionCount;
  final int year;
  final String season;
  final int day;
  final String lastMetLocationName;
  final String lastMetBuildingName;
  final String lastInteractionSummary;
  final String memorySummary;
  final String createdAt;
  final String updatedAt;

  NpcRelationship({
    required String npcId,
    required String npcName,
    String knownIdentity = '',
    int affinity = 0,
    int interactionCount = 0,
    required this.year,
    required String season,
    required this.day,
    String lastMetLocationName = '',
    String lastMetBuildingName = '',
    String lastInteractionSummary = '',
    String memorySummary = '',
    String? createdAt,
    String? updatedAt,
  }) : npcId = npcId.trim(),
       npcName = npcName.trim(),
       knownIdentity = knownIdentity.trim(),
       affinity = affinity.clamp(-100, 100),
       interactionCount = interactionCount < 0 ? 0 : interactionCount,
       season = season.trim(),
       lastMetLocationName = lastMetLocationName.trim(),
       lastMetBuildingName = lastMetBuildingName.trim(),
       lastInteractionSummary = lastInteractionSummary.trim(),
       memorySummary = memorySummary.trim(),
       createdAt = (createdAt == null || createdAt.trim().isEmpty)
           ? DateTime.now().toIso8601String()
           : createdAt.trim(),
       updatedAt = (updatedAt == null || updatedAt.trim().isEmpty)
           ? DateTime.now().toIso8601String()
           : updatedAt.trim();

  factory NpcRelationship.fromJson(Map<String, dynamic> json) {
    return NpcRelationship(
      npcId: json['npcId'] as String? ?? '',
      npcName: json['npcName'] as String? ?? '',
      knownIdentity: json['knownIdentity'] as String? ?? '',
      affinity: (json['affinity'] as num?)?.toInt() ?? 0,
      interactionCount: (json['interactionCount'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      season: json['season'] as String? ?? '',
      day: (json['day'] as num?)?.toInt() ?? 0,
      lastMetLocationName: json['lastMetLocationName'] as String? ?? '',
      lastMetBuildingName: json['lastMetBuildingName'] as String? ?? '',
      lastInteractionSummary: json['lastInteractionSummary'] as String? ?? '',
      memorySummary: json['memorySummary'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'npcId': npcId,
    'npcName': npcName,
    'knownIdentity': knownIdentity,
    'affinity': affinity,
    'interactionCount': interactionCount,
    'year': year,
    'season': season,
    'day': day,
    'lastMetLocationName': lastMetLocationName,
    'lastMetBuildingName': lastMetBuildingName,
    'lastInteractionSummary': lastInteractionSummary,
    'memorySummary': memorySummary,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  NpcRelationship copyWith({
    String? npcName,
    String? knownIdentity,
    int? affinity,
    int? interactionCount,
    int? year,
    String? season,
    int? day,
    String? lastMetLocationName,
    String? lastMetBuildingName,
    String? lastInteractionSummary,
    String? memorySummary,
    String? updatedAt,
  }) {
    return NpcRelationship(
      npcId: npcId,
      npcName: npcName ?? this.npcName,
      knownIdentity: knownIdentity ?? this.knownIdentity,
      affinity: affinity ?? this.affinity,
      interactionCount: interactionCount ?? this.interactionCount,
      year: year ?? this.year,
      season: season ?? this.season,
      day: day ?? this.day,
      lastMetLocationName: lastMetLocationName ?? this.lastMetLocationName,
      lastMetBuildingName: lastMetBuildingName ?? this.lastMetBuildingName,
      lastInteractionSummary: lastInteractionSummary ?? this.lastInteractionSummary,
      memorySummary: memorySummary ?? this.memorySummary,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get affinityLabel {
    if (affinity <= -81) return '仇敌';
    if (affinity <= -51) return '敌对';
    if (affinity <= -21) return '厌恶';
    if (affinity <= -1) return '疏远';
    if (affinity == 0) return '陌生';
    if (affinity <= 20) return '认识';
    if (affinity <= 40) return '友好';
    if (affinity <= 60) return '信赖';
    if (affinity <= 80) return '亲密';
    return '挚友';
  }

  bool get canSendLetter => affinity >= 21;
}
