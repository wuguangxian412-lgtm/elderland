import 'package:flutter/material.dart';

import '../models/building.dart';
import '../models/game_event_record.dart';
import '../models/interaction_record.dart';
import '../models/player.dart';
import '../models/npc.dart';
import '../models/quest.dart';
import '../models/timeline_entry.dart';
import '../dialogs/character_info_dialog.dart';
import '../dialogs/bag_dialog.dart';
import '../dialogs/relationship_dialog.dart';
import '../dialogs/history_dialog.dart';
import '../dialogs/quest_offer_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../pages/npc_interaction_page.dart';
import '../services/time_service.dart';
import '../services/save_service.dart';
import '../services/timeline_service.dart';
import '../dialogs/world_map_dialog.dart';
import '../services/world_service.dart';
import '../services/building_service.dart';
import '../services/exploration_event_service.dart';
import '../services/interaction_result_service.dart';
import '../services/quest_service.dart';

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
  final ExplorationEventService _explorationEventService =
      ExplorationEventService();
  final QuestService _questService = const QuestService();

  static const Color _bg = Color(0xFFF7F5F2);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    WorldService()
        .initialize()
        .then((_) {
          debugPrint('[GameMainPage] WorldService初始化完成');
          if (mounted) setState(() {});
        })
        .catchError((Object e) {
          debugPrint('[GameMainPage] WorldService初始化失败: $e');
        });
    _loadBuildingsForCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTimelineEvent());
  }

  void _showTip(String message) {
    final now = DateTime.now();
    if (_lastTipTime != null &&
        now.difference(_lastTipTime!).inMilliseconds < 1000) {
      return;
    }
    _lastTipTime = now;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _advanceDay() async {
    final updated = TimeService.advanceOneDay(_player);
    debugPrint('[TIME] ${updated.year}年${updated.season} Day ${updated.day}');
    setState(() => _player = updated);
    await SaveService().autoSave(_player);
    _checkTimelineEvent();
    if (!mounted) return;
    _showTip('玩家时间已推进一天');
  }

  Future<void> _inspectNpcStatus() async {
    debugPrint('[GameMainPage] 查看人物状态');
    WorldService().advanceDay();
    setState(() {});
    if (!mounted) return;
    _showTip('人物状态已输出到调试日志');
  }

  Future<void> _simulateAi() async {
    debugPrint('[GameMainPage] 模拟AI运行');
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
      if (!mounted) return;
      if (updated != null) {
        var nextPlayer = updated;
        if (oldPlayer.locationId != updated.locationId) {
          final movementEvent = GameEventRecord(
            type: GameEventRecord.typeMovement,
            title: '前往${updated.location}',
            summary: '你从${oldPlayer.location}出发，前往${updated.location}。',
            year: updated.year,
            season: updated.season,
            day: updated.day,
            locationId: updated.locationId,
            locationName: updated.location,
            result: 'movement_completed',
            metadata: {
              'fromLocationId': oldPlayer.locationId,
              'fromLocationName': oldPlayer.location,
              'toLocationId': updated.locationId,
              'toLocationName': updated.location,
            },
          );
          nextPlayer = updated.copyWith(
            eventRecords: [...updated.eventRecords, movementEvent],
          );
          debugPrint(
            '[Movement] 已记录移动经历: 从${oldPlayer.location}到${updated.location}',
          );
        }
        setState(() {
          _player = nextPlayer;
          _selectedBuilding = null;
        });
        _loadBuildingsForCurrentLocation();
        if (oldPlayer.locationId != updated.locationId) {
          await SaveService().autoSave(nextPlayer);
        }
      }
    } finally {
      _isWorldMapOpen = false;
    }
  }

  Future<void> _loadBuildingsForCurrentLocation() async {
    debugPrint('[Building] 开始加载当前地点建筑: ${_player.locationId}');
    setState(() {
      _buildingLoading = true;
      _buildingError = null;
    });
    try {
      final buildings = await BuildingService().loadBuildingsByLocation(
        _player.locationId,
      );
      if (!mounted) return;
      setState(() {
        _currentBuildings = buildings;
        _buildingLoading = false;
      });
      debugPrint('[Building] 当前地点建筑数量: ${buildings.length}');
    } catch (e) {
      debugPrint('[Building] 加载当前地点建筑失败: $e');
      if (!mounted) return;
      setState(() {
        _buildingError = '建筑加载失败: $e';
        _currentBuildings = [];
        _buildingLoading = false;
      });
    }
  }

  void _showBuildingActionSheet(Building building) {
    debugPrint('[Building] 点击建筑: ${building.id} ${building.name}');
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.meeting_room_outlined),
              title: const Text('进入'),
              onTap: () {
                Navigator.of(ctx).pop();
                debugPrint('[Building] 进入建筑: ${building.id} ${building.name}');
                setState(() => _selectedBuilding = building);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('观察'),
              onTap: () async {
                Navigator.of(ctx).pop();
                debugPrint('[Building] 观察建筑: ${building.id} ${building.name}');
                await _recordBuildingObservation(building);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordBuildingObservation(Building building) async {
    final event = _explorationEventService.buildBuildingObservationEvent(
      player: _player,
      building: building,
    );
    final updatedPlayer = _player.copyWith(
      eventRecords: [..._player.eventRecords, event],
    );
    setState(() => _player = updatedPlayer);
    await SaveService().autoSave(updatedPlayer);
    debugPrint('[Exploration] 已记录建筑观察事件: ${event.id}');
    if (!mounted) return;
    _showExplorationEventDialog(event);
  }

  Future<void> _recordWanderEvent() async {
    final event = _explorationEventService.buildWanderEvent(player: _player);
    final updatedPlayer = _player.copyWith(
      eventRecords: [..._player.eventRecords, event],
    );
    setState(() => _player = updatedPlayer);
    await SaveService().autoSave(updatedPlayer);
    debugPrint('[Exploration] 已记录随便逛逛事件: ${event.id}');
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

  void _returnToBuildingList() {
    debugPrint('[Building] 返回地点建筑列表');
    setState(() => _selectedBuilding = null);
  }

  void _showNpcActionSheet(Building building, Npc npc) {
    debugPrint('[NPC] 点击NPC: ${npc.id} ${npc.name}');
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('对话'),
              onTap: () {
                Navigator.of(ctx).pop();
                _openNpcInteraction(building, npc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('查看委托'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _openQuestOffer(building, npc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
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
    final alreadyActive = _player.activeQuests.any(
      (activeQuest) => activeQuest.id == quest.id,
    );
    if (alreadyActive) return;

    final questEvent = GameEventRecord(
      type: GameEventRecord.typeTask,
      title: '接受委托：${quest.title}',
      summary: '你接受了 ${npc.name} 的委托：${quest.title}。',
      year: _player.year,
      season: _player.season,
      day: _player.day,
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
    debugPrint('[Quest] 已接受委托: ${quest.id}');
    if (!mounted) return;
    _showTip('已接受委托');
  }

  Future<void> _openNpcInteraction(Building building, Npc npc) async {
    final record = await Navigator.push<InteractionRecord?>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NpcInteractionPage(player: _player, npc: npc, building: building),
      ),
    );
    if (!mounted) return;
    if (record == null) {
      debugPrint('[Interaction] 本次互动没有生成记录');
      setState(() {});
      return;
    }

    final resultService = const InteractionResultService();
    final affinityDelta = resultService.estimateAffinityDelta(record);
    final dialogueEvent = resultService.buildDialogueEvent(record);
    final relationshipEvent = resultService.buildRelationshipEvent(
      record,
      affinityDelta,
    );
    final memorySummary = resultService.buildNpcMemorySummary(
      record,
      affinityDelta,
    );
    final relationships = resultService.upsertRelationship(
      player: _player,
      npc: npc,
      building: building,
      record: record,
      affinityDelta: affinityDelta,
      memorySummary: memorySummary,
    );

    final updatedEvents = [
      ..._player.eventRecords,
      dialogueEvent,
      ?relationshipEvent,
    ];

    final importantRelationshipEvent = affinityDelta.abs() >= 10
        ? relationshipEvent
        : null;
    final updatedImportantEvents = [
      ..._player.importantEventRecords,
      ?importantRelationshipEvent,
    ];

    setState(() {
      _player = _player.copyWith(
        interactionRecords: [..._player.interactionRecords, record],
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
      interactionCount: relationships
          .firstWhere((r) => r.npcId == npc.id)
          .interactionCount,
    );
    await SaveService().autoSave(_player);

    debugPrint('[Interaction] 已保存互动记录: ${record.id}');
    debugPrint('[Interaction] 已写入统一经历: ${dialogueEvent.id}');
    debugPrint('[Interaction] 好感变化: $affinityDelta');
    if (!mounted) return;
    _showTip('互动、经历、人脉与NPC记忆已保存');
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

  Future<void> _checkTimelineEvent() async {
    final event = await TimelineService().getTimelineByYearSeason(
      _player.year,
      _player.season,
    );
    if (event == null) return;
    final eventName = event.title;
    if (_player.triggeredTimelineEvents.contains(eventName)) return;
    debugPrint('[TIMELINE] 触发事件：$eventName');
    setState(() {
      _player = _player.copyWith(
        triggeredTimelineEvents: [
          ..._player.triggeredTimelineEvents,
          eventName,
        ],
      );
    });
    await SaveService().autoSave(_player);
    if (!context.mounted) return;
    _showTimelineEventDialog(event);
  }

  void _showTimelineEventDialog(TimelineEntry event) {
    showDialog(
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

  Widget _buildLocationBuildingsView() {
    if (_buildingLoading) {
      return const Center(
        child: Text(
          '建筑加载中...',
          style: TextStyle(fontSize: 14, color: _textSecondary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text(
                '周围建筑',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _text,
                ),
              ),
              const Spacer(),
              Text(
                '数量: ${_currentBuildings.length}',
                style: const TextStyle(fontSize: 13, color: _textSecondary),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              onPressed: _recordWanderEvent,
              icon: const Icon(Icons.explore_outlined, size: 17),
              label: const Text('随便逛逛'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ),
        if (_buildingError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              _buildingError!,
              style: const TextStyle(fontSize: 13, color: Color(0xFFC75C5C)),
            ),
          ),
        Expanded(
          child: _currentBuildings.isEmpty
              ? const Center(
                  child: Text(
                    '附近暂时没有可进入的建筑',
                    style: TextStyle(fontSize: 14, color: _textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  itemCount: _currentBuildings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _buildingCard(_currentBuildings[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildingCard(Building building) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showBuildingActionSheet(building),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    building.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _text,
                    ),
                  ),
                ),
                _tag(building.isPublic ? '公共区域' : '私人区域'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              building.type,
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              building.description,
              style: const TextStyle(fontSize: 13, color: _text, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingInteriorView(Building building) {
    final buildingNpcs = WorldService().findNpcsByBuilding(
      _player.locationId,
      building.id,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextButton.icon(
            onPressed: _returnToBuildingList,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('离开'),
            style: TextButton.styleFrom(
              foregroundColor: _textSecondary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  building.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '建筑类型：${building.type}',
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  building.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _text,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            building.isPublic ? '周围人物' : '房间人物',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: buildingNpcs.isEmpty
              ? const Center(
                  child: Text(
                    '这里暂时没有可见人物',
                    style: TextStyle(fontSize: 14, color: _textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  itemCount: buildingNpcs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _npcCard(building, buildingNpcs[index]),
                ),
        ),
      ],
    );
  }

  Widget _npcCard(Building building, Npc npc) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showNpcActionSheet(building, npc),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    npc.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '状态：${_npcStateText(npc.state)}',
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _accent)),
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
      padding: EdgeInsets.fromLTRB(
        size.width * 0.04,
        size.height * 0.015,
        size.width * 0.04,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.03,
          vertical: size.height * 0.012,
        ),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
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
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: _textSecondary,
                ),
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
                  Text(
                    _player.name,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '血量 HP: ${_player.hp}/${_player.maxHp}',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
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
                    text:
                        '神圣历${_player.year}年 ${_player.season} Day ${_player.day}',
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
          Expanded(
            child: _selectedBuilding == null
                ? _buildLocationBuildingsView()
                : _buildBuildingInteriorView(_selectedBuilding!),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _navItem(
                Icons.backpack_outlined,
                '背包',
                () => BagDialog.show(context),
                key: const ValueKey('open_bag_button'),
              ),
              _navDivider(),
              _navItem(
                Icons.people_outlined,
                '人脉',
                () => RelationshipDialog.show(context, _player),
              ),
              _navDivider(),
              _navItem(
                Icons.history_outlined,
                '经历',
                () => HistoryDialog.show(context, _player),
                key: const ValueKey('open_history_button'),
              ),
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
            Text(
              label,
              style: const TextStyle(color: _textSecondary, fontSize: 11),
            ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: _border),
        borderRadius: borderRadius,
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _text,
              ),
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
      child: InkWell(
        key: key,
        borderRadius: borderRadius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}
