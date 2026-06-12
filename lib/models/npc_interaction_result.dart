import 'dialogue_message.dart';
import 'interaction_record.dart';
import 'player.dart';

/// NPC 互动页面返回结果。
///
/// 同时继承 InteractionRecord，是为了兼容旧版调用处：
/// 旧代码如果仍按 InteractionRecord? 接收，也不会因为返回类型变化而崩溃。
class NpcInteractionResult extends InteractionRecord {
  final Player player;
  final InteractionRecord? record;

  NpcInteractionResult({required this.player, required this.record})
      : super(
          id: record?.id,
          npcId: record?.npcId ?? '',
          npcName: record?.npcName ?? '',
          locationId: record?.locationId ?? player.locationId,
          locationName: record?.locationName ?? player.location,
          buildingId: record?.buildingId ?? '',
          buildingName: record?.buildingName ?? '',
          year: record?.year ?? player.year,
          season: record?.season ?? player.season,
          day: record?.day ?? player.day,
          naturalHour: record?.naturalHour ?? player.naturalHour,
          naturalMinute: record?.naturalMinute ?? player.naturalMinute,
          summary: record?.summary ?? '',
          messages: record?.messages ?? const <DialogueMessage>[],
          createdAt: record?.createdAt,
        );
}
