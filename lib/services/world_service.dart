import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/npc.dart';
import '../models/action.dart';

/// 世界状态服务 — 管理全局 NPC 和世界模拟数据
class WorldService {
  static final WorldService _instance = WorldService._();
  factory WorldService() => _instance;
  WorldService._();

  static const String _npcAssetPath = 'assets/data/npc_data.json';

  /// 全部 NPC 列表（静态 + 动态生成）
  final List<Npc> npcs = [];

  /// 是否已完成初始化
  bool _initialized = false;
  Future<void>? _initializing;

  /// 从 assets 加载 NPC 数据
  Future<void> initialize() async {
    debugPrint('[WorldService] initialize() 被调用');
    if (_initialized) return;
    if (_initializing != null) return _initializing!;

    _initializing = _loadInitialNpcs();
    try {
      await _initializing;
      _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _loadInitialNpcs() async {
    try {
      final jsonStr = await rootBundle.loadString(_npcAssetPath);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final npcList = data['npcs'] as List<dynamic>? ?? [];

      for (final item in npcList) {
        npcs.add(Npc.fromJson(item as Map<String, dynamic>));
      }

      debugPrint('[WorldService] 已加载 ${npcs.length} 个 NPC');
      for (final npc in npcs) {
        debugPrint(
          '[WorldService] NPC: id=${npc.id}  name=${npc.name}  '
          'locationId=${npc.locationId}  buildingId=${npc.buildingId}  state=${npc.state}',
        );
      }
    } catch (e) {
      debugPrint('[WorldService] 加载 NPC 数据失败: $e');
      rethrow;
    }
  }

  /// 手动添加 NPC（测试用）
  void addNpc(Npc npc) => npcs.add(npc);

  /// 按 ID 查找 NPC
  Npc? findNpcById(String id) {
    for (final npc in npcs) {
      if (npc.id == id) return npc;
    }
    return null;
  }

  /// 按所在地查找 NPC 列表
  List<Npc> findNpcsByLocation(String locationId) {
    return npcs.where((n) => n.locationId == locationId).toList();
  }

  /// 按地点和建筑查找 NPC 列表
  List<Npc> findNpcsByBuilding(String locationId, String buildingId) {
    final buildingNpcs = npcs
        .where((n) => n.locationId == locationId && n.buildingId == buildingId)
        .toList();
    debugPrint('[Building] 当前建筑 NPC 数量: ${buildingNpcs.length}');
    return buildingNpcs;
  }

  /// 更新指定 NPC 的状态
  void updateNpcState(String id, String newState) {
    final npc = findNpcById(id);
    if (npc != null) npc.state = newState;
  }

  /// 清除所有 NPC（测试用）
  void clearNpcs() {
    npcs.clear();
    _initialized = false;
  }

  // === AI 指令执行系统 ===

  /// 执行 AI 行动指令
  void executeAction(Action action) {
    debugPrint(
      '[WorldService] executeAction: ${action.type} target=${action.targetId}',
    );
    switch (action.type) {
      case 'spawn_npc':
        final npc = Npc.fromJson(action.payload);
        npcs.add(npc);
        debugPrint('[WorldService]  spawned NPC: ${npc.id} ${npc.name}');
        break;

      case 'move_npc':
        final npc = findNpcById(action.targetId ?? '');
        if (npc != null) {
          final newLocation = action.payload['locationId'] as String? ?? '';
          debugPrint(
            '[WorldService]  move NPC ${npc.name}: ${npc.locationId} -> $newLocation',
          );
          npc.locationId = newLocation;
        } else {
          debugPrint('[WorldService]  move_npc 未找到: ${action.targetId}');
        }
        break;

      case 'change_state':
        final npc = findNpcById(action.targetId ?? '');
        if (npc != null) {
          final newState = action.payload['state'] as String? ?? '';
          debugPrint(
            '[WorldService]  change_state NPC ${npc.name}: ${npc.state} -> $newState',
          );
          npc.state = newState;
        } else {
          debugPrint('[WorldService]  change_state 未找到: ${action.targetId}');
        }
        break;

      case 'update_memory':
        final npc = findNpcById(action.targetId ?? '');
        if (npc != null) {
          debugPrint(
            '[WorldService]  update_memory NPC ${npc.name}: ${action.payload}',
          );
          npc.memory.addAll(action.payload);
        } else {
          debugPrint('[WorldService]  update_memory 未找到: ${action.targetId}');
        }
        break;

      default:
        debugPrint('[WorldService]  未知 action type: ${action.type}');
    }
  }

  /// 模拟 AI 每日决策 — 返回测试用 Action 列表
  List<Action> simulateAIDay() {
    debugPrint('[WorldService] simulateAIDay()');
    final actions = <Action>[
      Action(
        type: 'move_npc',
        targetId: 'npc_village_elder_001',
        payload: {'locationId': 'holy_light_city'},
      ),
      Action(
        type: 'change_state',
        targetId: 'npc_village_elder_001',
        payload: {'state': 'working'},
      ),
      Action(
        type: 'update_memory',
        targetId: 'npc_village_elder_001',
        payload: {'lastAction': '前往圣光城汇报', 'day': 1},
      ),
      Action(
        type: 'spawn_npc',
        payload: {
          'id': 'npc_test_${DateTime.now().millisecondsSinceEpoch}',
          'name': '测试NPC_生成',
          'locationId': 'silver_leaf_village',
          'state': 'idle',
        },
      ),
    ];
    for (final a in actions) {
      debugPrint('[WorldService]  计划 action: $a');
    }
    return actions;
  }

  /// 推进一天（NPC 维度）
  void advanceDay() {
    debugPrint('[WorldService] advanceDay()');
    for (final npc in npcs) {
      debugPrint(
        '[WorldService]  NPC ${npc.name}: location=${npc.locationId} building=${npc.buildingId} state=${npc.state}',
      );
    }
  }

  /// 重新加载（用于重置或测试）
  Future<void> reload() async {
    npcs.clear();
    _initialized = false;
    await initialize();
  }
}
