import 'package:flutter/material.dart';

import '../dialogs/bag_dialog.dart';
import '../dialogs/character_info_dialog.dart';
import '../dialogs/equipment_dialog.dart';
import '../dialogs/magic_dialog.dart';
import '../dialogs/quest_offer_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/world_map_dialog.dart';
import '../models/building.dart';
import '../models/game_event_record.dart';
import '../models/npc.dart';
import '../models/npc_interaction_result.dart';
import '../models/player.dart';
import '../models/quest.dart';
import '../models/timeline_entry.dart';
import '../pages/npc_interaction_page.dart';
import '../services/building_service.dart';
import '../services/exploration_event_service.dart';
import '../services/interaction_result_service.dart';
import '../services/natural_time_service.dart';
import '../services/quest_service.dart';
import '../services/save_service.dart';
import '../services/time_service.dart';
import '../services/timeline_service.dart';
import '../services/world_service.dart';

class GameMainPage extends StatefulWidget {
  final Player player;

  const GameMainPage({super.key, required this.player});

  @override
  State<GameMainPage> createState() => _GameMainPageState();
}

class _GameMainPageState extends State<GameMainPage> {
  late Player _player;
  List<Building> _currentBuildings = [];
  Building? _selectedBuilding;
  bool _buildingLoading = false;
  bool _isWorldMapOpen = false;
  String? _buildingError;
  DateTime? _lastTipTime;

  final ExplorationEventService _explorationEventService = ExplorationEventService();
  final QuestService _questService = const QuestService();

  static const Color _bg = Color(0xFFF7F5F2);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _softCard = Color(0xFFFAFAFA);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);
  static const Color _danger = Color(0xFFD48383);

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    WorldService().initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object e) {
      debugPrint('[GameMainPage] WorldService初始化失败: $e');
    });
    _loadBuildingsForCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTimelineEvent());
  }

  void _showTip(String message) {
    final now = DateTime.now();
    if (_lastTipTime != null && now.difference(_lastTipTime!).inMilliseconds < 1000) {
      return;
    }
    _lastTipTime = now;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Player> _consumeNaturalTime(String actionId, {required int fallbackMinutes}) async {
    final updated = await NaturalTimeService.consumeAction(
      _player,
      actionId,
      fallbackMinutes: fallbackMinutes,
    );
    if (mounted) setState(() => _player = updated);
    return updated;
  }

  Future<void> _advanceDay() async {
    final updated = TimeService.advanceOneDay(_player);
    setState(() => _player = updated);
    await SaveService().autoSave(_player);
    _checkTimelineEvent();
    if (!mounted) return;
    _showTip('玩家时间已推进一天');
  }

  Future<void> _inspectNpcStatus() async {
    WorldService().advanceDay();
    setState(() {});
    if (!mounted) return;
    _showTip('人物状态已输出到调试日志');
  }

  Future<void> _simulateAi() async {
    final actions = WorldService().simulateAIDay();
    for (final action in actions) {
      await WorldService().executeAction(action);
    }
    setState(() {});
    if (!mounted) return;
    _showTip('村内人物行动已模拟');
  }

  Future<void> _openWorldMap() async {
    if (_isWorldMapOpen) return;
    _isWorldMapOpen = true;
    final oldPlayer = _player;
    try {
      final updated = await WorldMapDialog.show(context, _player);
      if (!mounted || updated == null) return;

      var nextPlayer = updated;
      if (oldPlayer.locationId != updated.locationId) {
        final movementEvent = GameEventRecord(
          type: GameEventRecord.typeMovement,
          title: '前往${updated.location}',
          summary: '你从${oldPlayer.location}出发，前往${updated.location}。',
          year: updated.year,
          season: updated.season,
          day: updated.day,
          naturalHour: updated.naturalHour,
          naturalMinute: updated.naturalMinute,
          locationId: updated.locationId,
          locationName: updated.location,
          result: 'movement_completed',
          metadata: {
            'fromLocationId': oldPlayer.locationId,
            'fromLocationName': oldPlayer.location,
            'toLocationId': updated.locationId,
            'toLocationName': updated.location,
            'timeConsumeRuleId': NaturalTimeAction.mapLocationTravel,
          },
        );
        nextPlayer = updated.copyWith(eventRecords: [...updated.eventRecords, movementEvent]);
      }

      setState(() {
        _player = nextPlayer;
        _selectedBuilding = null;
      });
      await _loadBuildingsForCurrentLocation();
      if (oldPlayer.locationId != updated.locationId) {
        await SaveService().autoSave(nextPlayer);
        _checkTimelineEvent();
      }
    } finally {
      _isWorldMapOpen = false;
    }
  }

  Future<void> _loadBuildingsForCurrentLocation() async {
    setState(() {
      _buildingLoading = true;
      _buildingError = null;
    });
    try {
      final buildings = await BuildingService().loadBuildingsByLocation(_player.locationId);
      if (!mounted) return;
      setState(() {
        _currentBuildings = buildings;
        _buildingLoading = false;
        if (buildings.isEmpty) {
          _selectedBuilding = null;
        } else {
          final selectedId = _selectedBuilding?.id;
          _selectedBuilding = buildings.firstWhere(
            (building) => building.id == selectedId,
            orElse: () => buildings.first,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buildingError = '建筑加载失败: $e';
        _currentBuildings = [];
        _selectedBuilding = null;
        _buildingLoading = false;
      });
    }
  }

  Future<void> _selectBuilding(Building building) async {
    if (_selectedBuilding?.id == building.id) return;
    final timedPlayer = await _consumeNaturalTime(
      NaturalTimeAction.buildingSwitch,
      fallbackMinutes: 10,
    );
    if (!mounted) return;
    setState(() {
      _player = timedPlayer;
      _selectedBuilding = building;
    });
    await SaveService().autoSave(timedPlayer);
    _checkTimelineEvent();
  }

  Future<void> _recordBuildingObservation(Building building) async {
    final timedPlayer = await _consumeNaturalTime(
      NaturalTimeAction.buildingObservation,
      fallbackMinutes: 5,
    );
    final event = _explorationEventService.buildBuildingObservationEvent(
      player: timedPlayer,
      building: building,
    );
    final updatedPlayer = timedPlayer.copyWith(
      eventRecords: [...timedPlayer.eventRecords, event],
    );
    setState(() => _player = updatedPlayer);
    await SaveService().autoSave(updatedPlayer);
    _checkTimelineEvent();
    if (!mounted) return;
    _showExplorationEventDialog(event);
  }

  Future<void> _recordWanderEvent() async {
    final timedPlayer = await _consumeNaturalTime(
      NaturalTimeAction.wander,
      fallbackMinutes: 30,
    );
    final event = _explorationEventService.buildWanderEvent(player: timedPlayer);
    final updatedPlayer = timedPlayer.copyWith(
      eventRecords: [...timedPlayer.eventRecords, event],
    );
    setState(() => _player = updatedPlayer);
    await SaveService().autoSave(updatedPlayer);
    _checkTimelineEvent();
    if (!mounted) return;
    _showExplorationEventDialog(event);
  }

  void _showExplorationEventDialog(GameEventRecord event) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(event.title.isEmpty ? '探索记录' : event.title),
        content: SingleChildScrollView(child: Text(event.summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _openQuestOffer(Building building, Npc npc) async {
    final quests = _questService.getAvailableQuestsForNpc(
      player: _player,
      npc: npc,
      building: building,
    );
    final acceptedQuest = await QuestOfferDialog.show(
      context,
      player: _player,
      npc: npc,
      building: building,
      quests: quests,
    );
    if (!mounted || acceptedQuest == null) return;
    await _acceptQuest(building: building, npc: npc, quest: acceptedQuest);
  }

  Future<void> _acceptQuest({
    required Building building,
    required Npc npc,
    required Quest quest,
  }) async {
    if (_player.activeQuests.any((q) => q.id == quest.id)) return;
    final questEvent = GameEventRecord(
      type: GameEventRecord.typeTask,
      title: '接受委托：${quest.title}',
      summary: '你接受了 ${npc.name} 的委托：${quest.title}。',
      year: _player.year,
      season: _player.season,
      day: _player.day,
      naturalHour: _player.naturalHour,
      naturalMinute: _player.naturalMinute,
      locationId: _player.locationId,
      locationName: _player.location,
      buildingId: building.id,
      buildingName: building.name,
      npcIds: [npc.id],
      npcNames: [npc.name],
      result: 'quest_accepted',
      metadata: {'questId': quest.id, 'issuerNpcId': npc.id},
    );
    final updatedPlayer = _player.copyWith(
      activeQuests: [..._player.activeQuests, quest],
      eventRecords: [..._player.eventRecords, questEvent],
    );
    setState(() => _player = updatedPlayer);
    await SaveService().autoSave(updatedPlayer);
    if (!mounted) return;
    _showTip('已接受委托');
  }

  Future<void> _openNpcInteraction(Building building, Npc npc) async {
    final interactionResult = await Navigator.push<NpcInteractionResult?>(
      context,
      MaterialPageRoute(
        builder: (_) => NpcInteractionPage(player: _player, npc: npc, building: building),
      ),
    );
    if (!mounted || interactionResult == null) return;

    final record = interactionResult.record;
    if (record == null) {
      setState(() => _player = interactionResult.player);
      await SaveService().autoSave(_player);
      return;
    }

    final interactionPlayer = interactionResult.player;
    final resultService = const InteractionResultService();
    final affinityDelta = resultService.estimateAffinityDelta(record);
    final dialogueEvent = resultService.buildDialogueEvent(record);
    final relationshipEvent = resultService.buildRelationshipEvent(record, affinityDelta);
    final memorySummary = resultService.buildNpcMemorySummary(record, affinityDelta);
    final relationships = resultService.upsertRelationship(
      player: interactionPlayer,
      npc: npc,
      building: building,
      record: record,
      affinityDelta: affinityDelta,
      memorySummary: memorySummary,
    );
    final updatedEvents = [...interactionPlayer.eventRecords, dialogueEvent, ?relationshipEvent];
    final importantRelationshipEvent = affinityDelta.abs() >= 10 ? relationshipEvent : null;
    final updatedImportantEvents = [
      ...interactionPlayer.importantEventRecords,
      ?importantRelationshipEvent,
    ];

    setState(() {
      _player = interactionPlayer.copyWith(
        interactionRecords: [...interactionPlayer.interactionRecords, record],
        eventRecords: updatedEvents,
        importantEventRecords: updatedImportantEvents,
        relationships: relationships,
      );
    });

    await WorldService().updateNpcPlayerMemory(
      npcId: npc.id,
      playerName: _player.name,
      summary: memorySummary,
      affinityDelta: affinityDelta,
      interactionCount: relationships.firstWhere((r) => r.npcId == npc.id).interactionCount,
    );
    await SaveService().autoSave(_player);
    _checkTimelineEvent();
    if (!mounted) return;
    _showTip('互动、经历、人脉与NPC记忆已保存');
  }

  Future<void> _checkTimelineEvent() async {
    final event = await TimelineService().getTimelineByYearSeason(
      _player.year,
      _player.season,
    );
    if (event == null) return;
    final eventName = event.title;
    if (_player.triggeredTimelineEvents.contains(eventName)) return;
    setState(() {
      _player = _player.copyWith(
        triggeredTimelineEvents: [..._player.triggeredTimelineEvents, eventName],
      );
    });
    await SaveService().autoSave(_player);
    if (!context.mounted) return;
    _showTimelineEventDialog(event);
  }

  void _showTimelineEventDialog(TimelineEntry event) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('时代事件'),
        content: SingleChildScrollView(child: Text(event.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  List<GameEventRecord> _buildingActionLogs(Building building) {
    final logs = _player.eventRecords.where((event) {
      if (event.buildingId == building.id) return true;
      if (event.locationId != _player.locationId) return false;
      return event.buildingId.isEmpty &&
          (event.type == GameEventRecord.typeMovement || event.type == GameEventRecord.typeExploration);
    }).toList();
    logs.sort((a, b) {
      if (a.year != b.year) return b.year.compareTo(a.year);
      if (a.day != b.day) return b.day.compareTo(a.day);
      if (a.naturalHour != b.naturalHour) return b.naturalHour.compareTo(a.naturalHour);
      if (a.naturalMinute != b.naturalMinute) return b.naturalMinute.compareTo(a.naturalMinute);
      return b.createdAt.compareTo(a.createdAt);
    });
    return logs.take(30).toList();
  }

  String _npcStateText(String state) {
    switch (state) {
      case 'idle':
        return '空闲';
      case 'busy':
        return '忙碌';
      case 'working':
        return '工作中';
      case 'resting':
        return '休息中';
      default:
        return state;
    }
  }

  String _npcPersonalityText(Npc npc) {
    final type = npc.personality['type'];
    if (type is String && type.trim().isNotEmpty) return type.trim();
    return '未知';
  }

  String _npcMemorySummary(Npc npc) {
    final playerMemory = npc.memory['player'];
    if (playerMemory is Map) {
      final summary = playerMemory['summary'];
      if (summary is String && summary.trim().isNotEmpty) return summary.trim();
    }
    final lastAction = npc.memory['lastAction'];
    if (lastAction is String && lastAction.trim().isNotEmpty) return lastAction.trim();
    return '你对这个人物的了解还很有限。';
  }

  void _showNpcInfoDialog(Building building, Npc npc) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(npc.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('所在建筑：${building.name}'),
              const SizedBox(height: 6),
              Text('性格：${_npcPersonalityText(npc)}'),
              const SizedBox(height: 6),
              Text('状态：${_npcStateText(npc.state)}'),
              const SizedBox(height: 12),
              Text(_npcMemorySummary(npc)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _openQuestOffer(building, npc);
            },
            child: const Text('委托'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openNpcInteraction(building, npc);
            },
            child: const Text('互动'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          SafeArea(bottom: false, child: _topPlayerCard(size)),
          SizedBox(height: size.height * 0.015),
          Expanded(child: _mainContentCard(size)),
          SizedBox(height: size.height * 0.015),
          _bottomNav(),
        ],
      ),
    );
  }

  Widget _topPlayerCard(Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(size.width * 0.04, size.height * 0.015, size.width * 0.04, 0),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: size.height * 0.012),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => CharacterInfoDialog.show(context, _player),
              key: const ValueKey('open_character_info_button'),
              child: Container(
                width: size.width * 0.15,
                height: size.width * 0.15,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E5E0),
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 2),
                ),
                child: const Icon(Icons.person, size: 30, color: _textSecondary),
              ),
            ),
            SizedBox(width: size.width * 0.04),
            Container(width: 1, height: size.width * 0.1, color: _border),
            SizedBox(width: size.width * 0.04),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_player.name, style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '血量 HP: ${_player.hp}/${_player.maxHp}',
                    style: const TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _naturalTimePill(),
          ],
        ),
      ),
    );
  }

  Widget _naturalTimePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: _softCard, border: Border.all(color: _border), borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('自然时间', style: TextStyle(fontSize: 10.5, color: _textSecondary)),
          const SizedBox(height: 2),
          Text(
            NaturalTimeService.playerNaturalTimeLabel(_player),
            style: const TextStyle(fontSize: 13, color: _accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _mainContentCard(Size size) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _statusChip(
                    key: const ValueKey('current_time_text'),
                    text: '神圣历${_player.year}年 ${_player.season} Day ${_player.day}',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _statusChip(
                    key: const ValueKey('current_location_text'),
                    text: _player.location,
                    icon: Icons.place_outlined,
                    trailingIcon: Icons.map_outlined,
                    onTap: _openWorldMap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 14),
          Expanded(child: _buildMainInteriorArea(size)),
        ],
      ),
    );
  }

  Widget _buildMainInteriorArea(Size size) {
    if (_buildingLoading) {
      return const Center(child: Text('建筑加载中...', style: TextStyle(fontSize: 14, color: _textSecondary)));
    }
    if (_buildingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(_buildingError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _danger)),
        ),
      );
    }
    if (_currentBuildings.isEmpty || _selectedBuilding == null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
            child: OutlinedButton.icon(
              onPressed: _recordWanderEvent,
              icon: const Icon(Icons.explore_outlined, size: 17),
              label: const Text('随便逛逛'),
            ),
          ),
          const Expanded(
            child: Center(child: Text('附近暂时没有可进入的建筑', style: TextStyle(fontSize: 14, color: _textSecondary))),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildingSelectorBar(_selectedBuilding!),
        Expanded(child: _buildBuildingInteriorView(size, _selectedBuilding!)),
      ],
    );
  }

  Widget _buildingSelectorBar(Building selectedBuilding) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: _currentBuildings.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final building = _currentBuildings[index];
          final selected = building.id == selectedBuilding.id;
          return ChoiceChip(
            label: Text(building.name),
            selected: selected,
            selectedColor: _accent,
            backgroundColor: _softCard,
            side: BorderSide(color: selected ? _accent : _border),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? Colors.white : _text,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
            onSelected: (_) => _selectBuilding(building),
          );
        },
      ),
    );
  }

  Widget _buildBuildingInteriorView(Size size, Building building) {
    final buildingNpcs = WorldService().findNpcsByBuilding(_player.locationId, building.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 77, child: _buildScenePanel(building, buildingNpcs)),
                const SizedBox(width: 8),
                Expanded(child: _buildActionLogPanel(building)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _interiorHeader(building),
        ],
      ),
    );
  }

  Widget _interiorHeader(Building building) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: _softCard, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  building.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, color: _text, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${building.type} · ${building.isPublic ? '公共区域' : '私人区域'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _miniButton('观察', () => _recordBuildingObservation(building)),
          const SizedBox(width: 6),
          _miniButton('闲逛', _recordWanderEvent),
        ],
      ),
    );
  }

  Widget _buildScenePanel(Building building, List<Npc> npcs) {
    return _sidePanel(
      title: '场景',
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _sceneGroupTitle('物品'),
          _emptySceneText('暂无物品'),
          const SizedBox(height: 10),
          _sceneGroupTitle('人物'),
          if (npcs.isEmpty) _emptySceneText('暂无人物') else ...npcs.map((npc) => _sceneNpcButton(building, npc)),
        ],
      ),
    );
  }

  Widget _sceneGroupTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w700)),
    );
  }

  Widget _emptySceneText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _textSecondary)),
    );
  }

  Widget _sceneNpcButton(Building building, Npc npc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showNpcInfoDialog(building, npc),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          decoration: BoxDecoration(color: _softCard, border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
          child: Text(
            npc.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _text, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildActionLogPanel(Building building) {
    final logs = _buildingActionLogs(building);
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(color: _softCard, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
        child: logs.isEmpty
            ? ListView(padding: EdgeInsets.zero, children: [_emptyActionLogText(building)])
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: logs.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: _border),
                itemBuilder: (context, index) => _actionLogTextItem(logs[index], isLatest: index == 0),
              ),
      ),
    );
  }

  Widget _emptyActionLogText(Building building) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        '你进入了${building.name}。\n这里还没有新的行动记录。\n后续可以接入 AI 生成环境描写、物品发现和人物行动。',
        style: const TextStyle(fontSize: 12.5, height: 1.6, color: _textSecondary),
      ),
    );
  }

  Widget _actionLogTextItem(GameEventRecord event, {bool isLatest = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        event.title.isEmpty ? event.typeLabel : event.title,
                        style: const TextStyle(fontSize: 12.5, color: _text, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(999)),
                        child: const Text(
                          'new',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, height: 1),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${event.year}年${event.season}${event.day}日 ${event.naturalClockLabel}',
                style: const TextStyle(fontSize: 10.5, color: _textSecondary),
              ),
            ],
          ),
          if (event.summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(event.summary, style: const TextStyle(fontSize: 12.5, color: _text, height: 1.45)),
          ],
        ],
      ),
    );
  }

  Widget _sidePanel({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: _card, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: _softCard,
              border: Border(bottom: BorderSide(color: _border)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _text, fontWeight: FontWeight.w700)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _miniButton(String text, VoidCallback onTap) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _text,
          side: const BorderSide(color: _border),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: _card, border: Border(top: BorderSide(color: _border, width: 0.5))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _navItem(Icons.backpack_outlined, '背包', () => BagDialog.show(context), key: const ValueKey('open_bag_button')),
              _navDivider(),
              _navItem(Icons.auto_fix_high_outlined, '魔法', () => MagicDialog.show(context)),
              _navDivider(),
              _navItem(Icons.shield_outlined, '装备', () => EquipmentDialog.show(context)),
              _navDivider(),
              _navItem(
                Icons.settings_outlined,
                '设置',
                () => SettingsDialog.show(
                  context,
                  _player,
                  onAdvancePlayerDay: _advanceDay,
                  onInspectNpcStatus: _inspectNpcStatus,
                  onSimulateVillageActions: _simulateAi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap, {Key? key}) {
    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _textSecondary, size: 24),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: _textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _navDivider() => Container(width: 0.5, height: 28, color: _border);

  Widget _statusChip({
    required Key key,
    required String text,
    required IconData icon,
    IconData? trailingIcon,
    VoidCallback? onTap,
  }) {
    final borderRadius = BorderRadius.circular(9);
    final content = Container(
      key: onTap == null ? key : null,
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: _softCard, border: Border.all(color: _border), borderRadius: borderRadius),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 13, color: _textSecondary),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(key: key, borderRadius: borderRadius, onTap: onTap, child: content),
    );
  }
}
