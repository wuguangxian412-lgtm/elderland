import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/timeline_entry.dart';
import '../dialogs/character_info_dialog.dart';
import '../dialogs/bag_dialog.dart';
import '../dialogs/relationship_dialog.dart';
import '../dialogs/history_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../services/time_service.dart';
import '../services/save_service.dart';
import '../services/timeline_service.dart';
import '../dialogs/world_map_dialog.dart';
import '../services/world_service.dart';

class GameMainPage extends StatefulWidget {
  final Player player;

  const GameMainPage({super.key, required this.player});

  @override
  State<GameMainPage> createState() => _GameMainPageState();
}

class _GameMainPageState extends State<GameMainPage> {
  late Player _player;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    debugPrint('[GameMainPage] 正在初始化WorldService');
    WorldService().initialize().then((_) {
      debugPrint('[GameMainPage] WorldService初始化完成');
    });
    // 首次进入时检查当前时间是否有未触发的时代事件
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTimelineEvent());
  }

  /// 时间推进按钮 — 推进一天并刷新界面
  Future<void> _advanceDay() async {
    final updated = TimeService.advanceOneDay(_player);
    debugPrint('[TIME] ${updated.year}年${updated.season} Day ${updated.day}');
    setState(() {
      _player = updated;
    });
    await SaveService().autoSave(_player);
    // TODO: 正式版删除此测试按钮
    _checkTimelineEvent();
  }

  /// 推进 NPC 的一天
  void _advanceNpcDay() {
    debugPrint('[GameMainPage] 推进NPC一天');
    WorldService().advanceDay();
    setState(() {});
  }

  /// 模拟 AI 运行
  void _simulateAi() {
    debugPrint('[GameMainPage] 模拟AI运行');
    final actions = WorldService().simulateAIDay();
    for (final action in actions) {
      WorldService().executeAction(action);
    }
    setState(() {});
  }

  /// 检查当前时间是否有未触发的时代事件
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

    // 记录已触发
    setState(() {
      _player = _player.copyWith(
        triggeredTimelineEvents: [
          ..._player.triggeredTimelineEvents,
          eventName,
        ],
      );
    });

    // 自动存档（保留已触发记录）
    await SaveService().autoSave(_player);

    if (!context.mounted) return;

    // 弹出事件窗口
    _showTimelineEventDialog(event);
  }

  /// 显示时代事件弹窗
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
          // ===================
          // 顶部信息栏
          // ===================
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
                    // 头像
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
                    // 竖向分隔线
                    Container(
                      width: 1,
                      height: size.width * 0.1,
                      color: _border,
                    ),
                    SizedBox(width: size.width * 0.04),
                    // 昵称和血量
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

          // ===================
          // 中间主内容区域
          // ===================
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
                  // 时间和地点信息
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          key: const ValueKey('current_time_text'),
                          '神圣历${_player.year}年 ${_player.season} Day ${_player.day}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                        Text(
                          key: const ValueKey('current_location_text'),
                          _player.location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 14),
                  // NPC 列表标题 + 数量
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Text(
                          'NPC列表（测试）',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _text,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '数量: ${WorldService().npcs.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // NPC 列表
                  Expanded(
                    child: WorldService().npcs.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无NPC数据',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: WorldService().npcs.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final npc = WorldService().npcs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        npc.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: _text,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      npc.locationId,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                                        npc.state,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  // 按钮区域
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
                                      setState(() => _player = updated);
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

          // ===================
          // 底部导航栏
          // ===================
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
}
