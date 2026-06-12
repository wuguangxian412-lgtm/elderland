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
    return [
      '你仔细观察${building.name.isEmpty ? '这处建筑' : building.name}，记下了它的格局、出入口和周围的动静。',
      '${building.name.isEmpty ? '这处建筑' : building.name}看起来没有特别异常，但你仍从一些细节里看出这里有人经常出入。',
      '你绕着${building.name.isEmpty ? '这处建筑' : building.name}看了看，对它在当前地点中的位置有了更清楚的印象。',
    ];
  }

  List<String> _wanderTexts(Player player) {
    return [
      '你在${player.location.isEmpty ? '当前地点' : player.location}随意走了走，观察周围环境，记下几处值得留意的地方。',
      '你放慢脚步，在${player.location.isEmpty ? '这里' : player.location}闲逛片刻，对周围的道路和人声有了初步印象。',
      '你没有急着做决定，只是沿路看看。当前地点的气氛被你一点点记在心里。',
    ];
  }
}
