import '../models/building.dart';
import '../models/npc.dart';
import '../models/player.dart';
import '../models/quest.dart';

class QuestService {
  const QuestService();

  List<Quest> getAvailableQuestsForNpc({
    required Player player,
    required Npc npc,
    required Building building,
  }) {
    final quest = _sampleQuestForNpc(
      player: player,
      npc: npc,
      building: building,
    );
    if (quest == null) return [];
    final alreadyActive = player.activeQuests.any(
      (active) => active.id == quest.id,
    );
    if (alreadyActive) return [];
    return [quest];
  }

  Quest? _sampleQuestForNpc({
    required Player player,
    required Npc npc,
    required Building building,
  }) {
    switch (npc.id) {
      case 'npc_village_elder_001':
        return Quest(
          id: 'quest_village_elder_inn_rumors',
          title: '打听旅店传闻',
          description: '村长希望你去旅店留意最近外来旅人提到的消息，尤其是有关道路和流民的传闻。',
          issuerNpcId: npc.id,
          issuerNpcName: npc.name,
          locationId: player.locationId,
          buildingId: building.id,
          acceptedYear: player.year,
          acceptedSeason: player.season,
          acceptedDay: player.day,
          progressSummary: '尚未开始。可以先去旅店看看。',
          rewardSummary: '完成后可能获得村长的感谢与少量报酬。',
        );
      case 'npc_blacksmith_001':
        return Quest(
          id: 'quest_blacksmith_ore_caravan',
          title: '留意矿石商队',
          description: '铁匠铺最近材料紧张，铁匠希望你帮忙留意是否有商队带来矿石或金属材料。',
          issuerNpcId: npc.id,
          issuerNpcName: npc.name,
          locationId: player.locationId,
          buildingId: building.id,
          acceptedYear: player.year,
          acceptedSeason: player.season,
          acceptedDay: player.day,
          progressSummary: '尚未开始。可以在村口广场或旅店打听商队消息。',
          rewardSummary: '完成后可能获得铁匠的好感或打造折扣。',
        );
      default:
        return null;
    }
  }
}
