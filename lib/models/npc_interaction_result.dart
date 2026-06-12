import 'dialogue_message.dart';
import 'interaction_record.dart';
import 'player.dart';

/// NPC 互动页面返回结果。
///
/// 继承 InteractionRecord，是为了兼容旧的 Navigator.push<InteractionRecord?>
/// 接收方式；同时额外携带已推进自然时间后的 Player。
class NpcInteractionResult extends InteractionRecord {
  final Player player;
  final InteractionRecord? sourceRecord;

  InteractionRecord? get record => sourceRecord;

  NpcInteractionResult({
    required this.player,
    required InteractionRecord? record,
  }) : sourceRecord = record,
       super(
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
