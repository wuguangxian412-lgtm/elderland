import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/npc.dart';
import '../models/action.dart';
import 'world_save_service.dart';

/// 世界状态服务 — 管理全局 NPC 和世界模拟数据
class WorldService {
  static final WorldService _instance = WorldService._();
  factory WorldService() => _instance;
  WorldService._();

  static const String _npcAssetPath = 'assets/data/npc_data.json';
  static const Set<String> _allowedMemorySections = {
    'player',
    'daily',
    'quest',
    'world',
    'lastAction',
  };

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
      npcs.clear();
      final jsonStr = await rootBundle.loadString(_npcAssetPath);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final npcList = data['npcs'] as List<dynamic>? ?? [];

      for (final item in npcList) {
        npcs.add(Npc.fromJson(item as Map<String, dynamic>));
      }

      debugPrint('[WorldService] 已加载初始 NPC 数量: ${npcs.length}');

      final savedNpcs = await WorldSaveService().loadWorldNpcs();
      if (savedNpcs != null && savedNpcs.isNotEmpty) {
        npcs
          ..clear()
          ..addAll(savedNpcs);
        debugPrint('[WorldService] 已使用 world_save 覆盖 NPC 状态');
      } else {
        debugPrint('[WorldService] 使用初始 NPC 数据');
      }

      debugPrint('[WorldService] 当前 NPC 数量: ${npcs.length}');
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
  Future<void> updateNpcState(String id, String newState) async {
    final npc = findNpcById(id);
    if (npc != null) {
      npc.state = newState;
      await saveWorldState();
    }
  }

  /// 更新 NPC 对玩家的记忆摘要。
  ///
  /// 这里不保存完整对话，只保存摘要，避免 NPC 记忆无限膨胀。
  Future<void> updateNpcPlayerMemory({
    required String npcId,
    required String playerName,
    required String summary,
    required int affinityDelta,
    required int interactionCount,
  }) async {
    final npc = findNpcById(npcId);
    if (npc == null) {
      debugPrint('[WorldService] updateNpcPlayerMemory 未找到 NPC: $npcId');
      return;
    }

    final playerMemory = npc.memory['player'] is Map
        ? Map<String, dynamic>.from(
            (npc.memory['player'] as Map).map((k, v) => MapEntry(k.toString(), v)),
          )
        : <String, dynamic>{};

    playerMemory['name'] = playerName;
    playerMemory['summary'] = summary;
    playerMemory['lastAffinityDelta'] = affinityDelta;
    playerMemory['interactionCount'] = interactionCount;
    playerMemory['updatedAt'] = DateTime.now().toIso8601String();
    npc.memory['player'] = playerMemory;

    await saveWorldState();
    debugPrint('[WorldService] 已更新 NPC 对玩家记忆: ${npc.name}');
  }

  Future<void> saveWorldState() async {
    await WorldSaveService().saveWorldNpcs(npcs);
    debugPrint('[WorldService] 世界状态已保存');
  }

  /// 清除所有 NPC（测试用）
  void clearNpcs() {
    npcs.clear();
    _initialized = false;
    _initializing = null;
  }

  // === AI 指令执行系统 ===

  /// 执行 AI 行动指令
  Future<void> executeAction(Action action) async {
    debugPrint(
      '[WorldService] executeAction: ${action.type} target=${action.targetId}',
    );
    var didChange = false;
    switch (action.type) {
      case 'spawn_npc':
        final npc = Npc.fromJson(action.payload);
        npcs.add(npc);
        didChange = true;
        debugPrint('[WorldService]  spawned NPC: ${npc.id} ${npc.name}');
        break;

      case 'move_npc':
        final npc = findNpcById(action.targetId ?? '');
        if (npc != null) {
          final oldLocation = npc.locationId;
          final oldBuilding = npc.buildingId;
          final newLocation = action.payload['locationId'] as String? ?? '';
          final hasBuildingPayload = action.payload.containsKey('buildingId');
          final newBuilding = hasBuildingPayload
              ? (action.payload['buildingId'] as String? ?? '')
              : (newLocation == oldLocation ? oldBuilding : '');
          debugPrint(
            '[WorldService]  move NPC ${npc.name}: '
            '$oldLocation/$oldBuilding -> $newLocation/$newBuilding',
          );
          npc.locationId = newLocation;
          npc.buildingId = newBuilding;
          didChange = true;
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
          didChange = true;
        } else {
          debugPrint('[WorldService]  change_state 未找到: ${action.targetId}');
        }
        break;

      case 'update_memory':
        final npc = findNpcById(action.targetId ?? '');
        if (npc != null) {
          final safePayload = _sanitizeMemoryPayload(action.payload);
          if (safePayload.isEmpty) {
            debugPrint('[WorldService]  update_memory 跳过：payload 没有允许的记忆字段');
            break;
          }
          debugPrint(
            '[WorldService]  update_memory NPC ${npc.name}: $safePayload',
          );
          npc.memory.addAll(safePayload);
          didChange = true;
        } else {
          debugPrint('[WorldService]  update_memory 未找到: ${action.targetId}');
        }
        break;

      default:
        debugPrint('[WorldService]  未知 action type: ${action.type}');
    }

    if (didChange) {
      await saveWorldState();
    }
  }

  Map<String, dynamic> _sanitizeMemoryPayload(Map<String, dynamic> payload) {
    final safe = <String, dynamic>{};
    for (final entry in payload.entries) {
      final key = entry.key.trim();
      if (!_allowedMemorySections.contains(key)) continue;
      safe[key] = entry.value;
    }
    return safe;
  }

  /// 模拟村内人物行动 — 返回测试用 Action 列表
  ///
  /// 注意：这是开发阶段的本地模拟，不是真正 AI。
  /// 目前只允许 NPC 在银叶村已有建筑之间移动，避免 NPC 被移动到
  /// 尚未配置建筑的地点后从 UI 中消失。
  List<Action> simulateAIDay() {
    debugPrint('[WorldService] simulateAIDay()');
    final actions = <Action>[
      Action(
        type: 'move_npc',
        targetId: 'npc_village_elder_001',
        payload: {
          'locationId': 'silver_leaf_village',
          'buildingId': 'silver_leaf_village_square',
        },
      ),
      Action(
        type: 'change_state',
        targetId: 'npc_village_elder_001',
        payload: {'state': 'busy'},
      ),
      Action(
        type: 'update_memory',
        targetId: 'npc_village_elder_001',
        payload: {
          'lastAction': '在村口广场处理村务',
          'daily': {
            'attitudeToPlayer': 'neutral',
            'day': 1,
          },
        },
      ),
      Action(
        type: 'change_state',
        targetId: 'npc_blacksmith_001',
        payload: {'state': 'working'},
      ),
      Action(
        type: 'spawn_npc',
        payload: {
          'id': 'npc_test_${DateTime.now().millisecondsSinceEpoch}',
          'name': '测试旅人',
          'locationId': 'silver_leaf_village',
          'buildingId': 'silver_leaf_village_inn',
          'state': 'idle',
          'personality': {'type': '普通'},
          'memory': {'world': {'source': 'simulateAIDay'}},
          'history': [],
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
