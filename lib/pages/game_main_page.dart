import 'package:flutter/material.dart';

import '../models/building.dart';
import '../models/player.dart';
import '../models/npc.dart';
import '../models/timeline_entry.dart';
import '../dialogs/character_info_dialog.dart';
import '../dialogs/bag_dialog.dart';
import '../dialogs/relationship_dialog.dart';
import '../dialogs/history_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../pages/npc_interaction_page.dart';
import '../services/time_service.dart';
import '../services/save_service.dart';
import '../services/timeline_service.dart';
import '../dialogs/world_map_dialog.dart';
import '../services/world_service.dart';
import '../services/building_service.dart';

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
  String? _buildingError;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    debugPrint('[GameMainPage] 正在初始化WorldService');
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

  Future<void> _advanceDay() async {
    final updated = TimeService.advanceOneDay(_player);
    debugPrint('[TIME] ${updated.year}年${updated.season} Day ${updated.day}');
    setState(() {
      _player = updated;
    });
    await SaveService().autoSave(_player);
    _checkTimelineEvent();
  }

  void _advanceNpcDay() {
    debugPrint('[GameMainPage] 推进NPC一天');
    WorldService().advanceDay();
    setState(() {});
  }

  void _simulateAi() {
    debugPrint('[GameMainPage] 模拟AI运行');
    final actions = WorldService().simulateAIDay();
    for (final action in actions) {
      WorldService().executeAction(action);
    }
    setState(() {});
  }

  Future<void> _loadBuildingsForCurrentLocation() async {
    debugPrint('[Building] 开始加载当前地点建筑: ${_player.locationId}');
    if (mounted) {
      setState(() {
        _buildingLoading = true;
        _buildingError = null;
      });
    }

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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.meeting_room_outlined),
                title: const Text('进入'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  debugPrint(
                    '[Building] 进入建筑: ${building.id} ${building.name}',
                  );
                  setState(() => _selectedBuilding = building);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('观察'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  debugPrint(
                    '[Building] 观察建筑: ${building.id} ${building.name}',
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('观察功能后续开放')));
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                leading: const Icon(Icons.dangerous_outlined),
                title: const Text('杀害'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('杀害功能后续开放')));
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
      ),
    );
  }

  Future<void> _openNpcInteraction(Building building, Npc npc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NpcInteractionPage(player: _player, npc: npc, building: building),
      ),
    );
    if (mounted) setState(() {});
  }

  String _npcStateText(String state) {
    switch (state) {
      case 'idle':
        return '空闲';
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
    if (_player.triggeredTimelineEvents.contains(eventName)) {
      debugPrint('[TIMELINE] 已触发过，跳过：$eventName');
      return;
    }

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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '时代事件',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    event.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF555555),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('知道了'),
                ),
              ),
            ],
          ),
        ),
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
        const SizedBox(height: 8),
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
                  itemBuilder: (context, index) {
                    final building = _currentBuildings[index];
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    building.isPublic ? '公共区域' : '私人区域',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              building.type,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              building.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _text,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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
                  itemBuilder: (context, index) {
                    final npc = buildingNpcs[index];
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
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: _textSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static const Color _bg = Color(0xFFF7F5F2);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
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
                    Container(
                      width: 1,
                      height: size.width * 0.1,
                      color: _border,
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _player.name,
                            style: TextStyle(
                              color: _text,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "血量 HP: ${_player.hp}/${_player.maxHp}",
                            style: TextStyle(
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
            ),
          ),
          SizedBox(height: size.height * 0.015),
          Expanded(
            child: Container(
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
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  key: const ValueKey('advance_one_day_button'),
                                  onPressed: _advanceDay,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffaac8dc),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    '推进一天（测试）',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: _advanceNpcDay,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B9D83),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    '推进一天（测试NPC）',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: _simulateAi,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD87C7C),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    '模拟AI运行',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final updated = await WorldMapDialog.show(
                                      context,
                                      _player,
                                    );
                                    if (!mounted) return;
                                    if (updated != null) {
                                      setState(() {
                                        _player = updated;
                                        _selectedBuilding = null;
                                      });
                                      _loadBuildingsForCurrentLocation();
                                    }
                                  },
                                  key: const ValueKey('open_world_map_button'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B7F8D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    '世界地图',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: size.height * 0.015),
          Container(
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
                      "背包",
                      0,
                      () => BagDialog.show(context),
                      key: const ValueKey('open_bag_button'),
                    ),
                    _navDivider(),
                    _navItem(
                      Icons.people_outlined,
                      "人脉",
                      1,
                      () => RelationshipDialog.show(context),
                    ),
                    _navDivider(),
                    _navItem(
                      Icons.history_outlined,
                      "经历",
                      2,
                      () => HistoryDialog.show(context),
                      key: const ValueKey('open_history_button'),
                    ),
                    _navDivider(),
                    _navItem(
                      Icons.settings_outlined,
                      "设置",
                      3,
                      () => SettingsDialog.show(context, _player),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index,
    VoidCallback onTap, {
    Key? key,
  }) {
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

  Widget _navDivider() {
    return Container(width: 0.5, height: 28, color: _border);
  }

  Widget _statusChip({
    required Key key,
    required String text,
    required IconData icon,
  }) {
    return Container(
      key: key,
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
        ],
      ),
    );
  }
}
