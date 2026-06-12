import 'dart:math';

import '../models/building.dart';
import '../models/game_event_record.dart';
import '../models/player.dart';

class ExplorationEventService {
  final Random _random;

  ExplorationEventService({Random? random}) : _random = random ?? Random();

  GameEventRecord buildBuildingObservationEvent({
    required Player player,
    required Building building,
  }) {
    final summary = _pick(_buildingObservationTexts(building));
    return GameEventRecord(
      type: GameEventRecord.typeExploration,
      title: '观察${building.name.isEmpty ? '建筑' : building.name}',
      summary: summary,
      year: player.year,
      season: player.season,
      day: player.day,
      naturalHour: player.naturalHour,
      naturalMinute: player.naturalMinute,
      locationId: player.locationId,
      locationName: player.location,
      buildingId: building.id,
      buildingName: building.name,
      result: 'exploration_logged',
      metadata: {
        'source': 'building_observation',
        'buildingType': building.type,
      },
    );
  }

  GameEventRecord buildWanderEvent({required Player player}) {
    final summary = _pick(_wanderTexts(player));
    return GameEventRecord(
      type: GameEventRecord.typeExploration,
      title: '随便逛逛',
      summary: summary,
      year: player.year,
      season: player.season,
      day: player.day,
      naturalHour: player.naturalHour,
      naturalMinute: player.naturalMinute,
      locationId: player.locationId,
      locationName: player.location,
      result: 'exploration_logged',
      metadata: const {'source': 'wander'},
    );
  }

  String _pick(List<String> texts) {
    if (texts.isEmpty) return '你停下脚步，静静观察四周。';
    return texts[_random.nextInt(texts.length)];
  }

  List<String> _buildingObservationTexts(Building building) {
    switch (building.id) {
      case 'silver_leaf_village_square':
        return const [
          '村口广场上人来人往，脚下石板被岁月磨得发亮。你听见几句家常，也注意到村民们谈起外来商队时声音压低了些。',
          '广场边的木牌贴着旧告示，风吹过时边角轻轻晃动。这里看似平静，却总能收集到村里最快的消息。',
          '你在广场停留片刻，看见几个村民交换农具和干粮。银叶村的日子大多从这里流动起来。',
        ];
      case 'silver_leaf_village_elder_house':
        return const [
          '村长家的门廊打扫得很干净，窗边堆着几卷账册。你能感觉到这里处理的不只是家务，还有整个村子的琐碎秩序。',
          '屋檐下挂着风干的草药，门内隐约有纸页翻动的声音。村长家的安静里藏着许多村务的重量。',
          '你观察村长家的院落，发现柴火、账册和信件都摆得井井有条。这里不像普通民居，更像村子的心脏。',
        ];
      case 'silver_leaf_village_blacksmith':
        return const [
          '铁匠铺里炉火未熄，空气中混着炭灰和热铁的味道。墙上挂着修补过的农具，说明最近村民来得很勤。',
          '你看见砧台边散落着铁屑，水槽里还冒着淡淡白气。这里的每一下敲打，都像是在替村子维持生计。',
          '铁匠铺的工具摆放得很顺手，旧锤柄被握得发亮。你意识到这里不只是打造器具，也修补着银叶村的日常。',
        ];
      case 'silver_leaf_village_inn':
        return const [
          '旅店里有木桌被反复擦拭的痕迹，角落还留着旅人鞋底带进来的泥。这里总能留下外面世界的碎片。',
          '你在旅店门口停了停，闻到热汤和旧木头混在一起的气味。几张空椅子像是在等待下一批过路人。',
          '旅店柜台后挂着几串钥匙，墙边放着磨损的行囊架。来往消息常在这里停留一晚，又继续向远方散去。',
        ];
      default:
        return [
          '你仔细观察${building.name.isEmpty ? '这处建筑' : building.name}，记下了它的格局、出入口和周围的动静。',
          '${building.name.isEmpty ? '这处建筑' : building.name}看起来没有特别异常，但你仍从一些细节里看出这里有人经常出入。',
          '你绕着${building.name.isEmpty ? '这处建筑' : building.name}看了看，对它在当前地点中的位置有了更清楚的印象。',
        ];
    }
  }

  List<String> _wanderTexts(Player player) {
    if (player.locationId == 'silver_leaf_village') {
      return const [
        '你沿着银叶村的小路慢慢走了一圈。村民们各忙各的，炊烟从几处屋顶升起，村子显得安稳而真实。',
        '你没有固定目的，只是在银叶村里闲逛。路过广场时，你听见有人谈起最近天气和商队行程。',
        '你穿过银叶村的几条土路，注意到篱笆、柴堆和井边水桶都带着生活留下的痕迹。',
        '你在村中随意走动，发现不同建筑之间的距离并不远。银叶村虽小，却有自己的节奏。',
      ];
    }
    return [
      '你在${player.location.isEmpty ? '当前地点' : player.location}随意走了走，观察周围环境，记下几处值得留意的地方。',
      '你放慢脚步，在${player.location.isEmpty ? '这里' : player.location}闲逛片刻，对周围的道路和人声有了初步印象。',
      '你没有急着做决定，只是沿路看看。当前地点的气氛被你一点点记在心里。',
    ];
  }
}
