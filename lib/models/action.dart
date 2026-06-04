/// AI 行动指令 — AI 输出的标准格式，用于驱动 WorldService 执行世界变化
class Action {
  /// 行动类型
  ///   spawn_npc     — 生成新 NPC
  ///   move_npc      — 移动 NPC 到新地点
  ///   change_state  — 修改 NPC 状态
  ///   update_memory — 更新 NPC 记忆
  final String type;

  /// 目标 NPC ID（可为空，如 spawn_npc 不需要）
  final String? targetId;

  /// 附加数据载荷
  final Map<String, dynamic> payload;

  Action({required this.type, this.targetId, this.payload = const {}});

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      type: (json['type'] as String?)?.trim() ?? '',
      targetId: (json['targetId'] as String?)?.trim(),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(
              (json['payload'] as Map).map((k, v) => MapEntry(k.toString(), v)),
            )
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (targetId != null) 'targetId': targetId,
    'payload': payload,
  };

  @override
  String toString() =>
      'Action($type${targetId != null ? ' -> $targetId' : ''})';
}
