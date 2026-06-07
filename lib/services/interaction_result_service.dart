import '../models/building.dart';
import '../models/game_event_record.dart';
import '../models/interaction_record.dart';
import '../models/npc.dart';
import '../models/npc_relationship.dart';
import '../models/player.dart';

/// NPC 互动结算服务
///
/// 目前不接 AI，只做稳定的本地规则结算：
/// 1. 生成统一对话经历；
/// 2. 根据玩家输入粗略判断好感度变化；
/// 3. 生成人脉数据；
/// 4. 生成 NPC 对玩家的记忆摘要。
///
/// 后续接 AI 时，可以把这里的启发式规则替换成 AI 总结结果，
/// 但最终仍由系统写入 Player / WorldService / SaveService。
class InteractionResultService {
  const InteractionResultService();

  int estimateAffinityDelta(InteractionRecord record) {
    final playerTexts = record.messages
        .where((m) => m.speaker == '你')
        .map((m) => m.text)
        .join(' ');

    final negativeWords = ['骂', '威胁', '攻击', '打', '骗', '侮辱', '滚', '闭嘴', '敌人'];
    if (negativeWords.any(playerTexts.contains)) return -5;

    final positiveWords = ['谢谢', '感谢', '帮', '帮助', '请', '拜托', '你好', '关心', '辛苦'];
    if (positiveWords.any(playerTexts.contains)) return 5;

    return 0;
  }

  GameEventRecord buildDialogueEvent(InteractionRecord record) {
    return GameEventRecord(
      type: GameEventRecord.typeDialogue,
      title: '与${record.npcName}交谈',
      summary: '你在${record.locationName}${record.buildingName.isEmpty ? '' : '的${record.buildingName}'}与${record.npcName}交谈。',
      year: record.year,
      season: record.season,
      day: record.day,
      locationId: record.locationId,
      locationName: record.locationName,
      buildingId: record.buildingId,
      buildingName: record.buildingName,
      npcIds: [record.npcId],
      npcNames: [record.npcName],
      result: 'dialogue_saved',
      metadata: {
        'interactionRecordId': record.id,
        'messageCount': record.messages.length,
      },
    );
  }

  GameEventRecord? buildRelationshipEvent(InteractionRecord record, int delta) {
    if (delta == 0) return null;
    final direction = delta > 0 ? '变好' : '变差';
    return GameEventRecord(
      type: GameEventRecord.typeRelationship,
      title: '与${record.npcName}的关系$direction',
      summary: '这次交谈后，${record.npcName}对你的印象有所$direction。',
      year: record.year,
      season: record.season,
      day: record.day,
      locationId: record.locationId,
      locationName: record.locationName,
      buildingId: record.buildingId,
      buildingName: record.buildingName,
      npcIds: [record.npcId],
      npcNames: [record.npcName],
      result: delta > 0 ? 'affinity_up' : 'affinity_down',
      metadata: {'affinityDelta': delta},
    );
  }

  List<NpcRelationship> upsertRelationship({
    required Player player,
    required Npc npc,
    required Building building,
    required InteractionRecord record,
    required int affinityDelta,
    required String memorySummary,
  }) {
    final relationships = [...player.relationships];
    final index = relationships.indexWhere((r) => r.npcId == npc.id);
    final knownIdentity = _knownIdentityOf(npc);

    if (index < 0) {
      relationships.add(
        NpcRelationship(
          npcId: npc.id,
          npcName: npc.name,
          knownIdentity: knownIdentity,
          affinity: affinityDelta,
          interactionCount: 1,
          year: player.year,
          season: player.season,
          day: player.day,
          lastMetLocationName: player.location,
          lastMetBuildingName: building.name,
          lastInteractionSummary: record.summary,
          memorySummary: memorySummary,
        ),
      );
      return relationships;
    }

    final old = relationships[index];
    relationships[index] = old.copyWith(
      npcName: npc.name,
      knownIdentity: knownIdentity.isEmpty ? old.knownIdentity : knownIdentity,
      affinity: old.affinity + affinityDelta,
      interactionCount: old.interactionCount + 1,
      year: player.year,
      season: player.season,
      day: player.day,
      lastMetLocationName: player.location,
      lastMetBuildingName: building.name,
      lastInteractionSummary: record.summary,
      memorySummary: memorySummary,
    );
    return relationships;
  }

  String buildNpcMemorySummary(InteractionRecord record, int affinityDelta) {
    final playerMessageCount = record.messages.where((m) => m.speaker == '你').length;
    final result = affinityDelta > 0
        ? '印象略有改善'
        : affinityDelta < 0
            ? '印象略有下降'
            : '印象暂未明显变化';
    return '神圣历${record.year}年${record.season} Day ${record.day}，玩家在${record.locationName}${record.buildingName.isEmpty ? '' : '的${record.buildingName}'}与我交谈，玩家发言 $playerMessageCount 次，$result。';
  }

  String _knownIdentityOf(Npc npc) {
    final identity = npc.personality['identity'];
    if (identity is String && identity.trim().isNotEmpty) return identity.trim();

    final role = npc.personality['role'];
    if (role is String && role.trim().isNotEmpty) return role.trim();

    final type = npc.personality['type'];
    if (type is String && type.trim().isNotEmpty) return type.trim();

    return '普通人物';
  }
}
