import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/game_event_record.dart';
import '../models/player.dart';
import 'time_service.dart';

class NaturalTimeAction {
  static const String npcMessage = 'npc_message';
  static const String buildingSwitch = 'building_switch';
  static const String buildingObservation = 'building_observation';
  static const String wander = 'wander';
  static const String mapLocationTravel = 'map_location_travel';
}

/// 自然时间系统。
///
/// 自然时间是游戏世界内部时间，不依赖现实世界时间。
/// 页面和功能模块只需要调用 consumeAction / advanceMinutes，具体消耗数值
/// 从 assets/data/rules.json 的 time_consume_rules 读取，后续改数值不用改代码。
class NaturalTimeService {
  static const String _rulesAssetPath = 'assets/data/rules.json';
  static const int minutesPerDay = 24 * 60;

  static Map<String, int>? _cachedConsumeMinutes;

  static Future<int> consumeMinutesOf(
    String actionId, {
    int fallbackMinutes = 0,
  }) async {
    final rules = await _loadConsumeRules();
    return rules[actionId] ?? fallbackMinutes;
  }

  static Future<Player> consumeAction(
    Player player,
    String actionId, {
    int fallbackMinutes = 0,
  }) async {
    final minutes = await consumeMinutesOf(
      actionId,
      fallbackMinutes: fallbackMinutes,
    );
    return advanceMinutes(player, minutes);
  }

  static Player advanceMinutes(Player player, int minutes) {
    if (minutes == 0) return _normalizeClock(player);

    final startTotalMinutes = player.naturalHour * 60 + player.naturalMinute;
    final totalMinutes = startTotalMinutes + minutes;
    final dayDelta = totalMinutes ~/ minutesPerDay;
    final clockMinutes = totalMinutes % minutesPerDay;

    var updated = player.copyWith(
      naturalHour: clockMinutes ~/ 60,
      naturalMinute: clockMinutes % 60,
    );

    for (var i = 0; i < dayDelta; i++) {
      updated = TimeService.advanceOneDay(updated);
    }

    return updated;
  }

  static String clockLabel(Player player) {
    final hour = player.naturalHour.clamp(0, 23).toString().padLeft(2, '0');
    final minute = player.naturalMinute.clamp(0, 59).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String eventClockLabel(GameEventRecord event) {
    final hour = event.naturalHour.clamp(0, 23).toString().padLeft(2, '0');
    final minute = event.naturalMinute.clamp(0, 59).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String dayPeriodLabel(int hour) {
    final h = hour.clamp(0, 23).toInt();
    if (h >= 5 && h < 11) return '早晨';
    if (h >= 11 && h < 14) return '中午';
    if (h >= 14 && h < 18) return '下午';
    if (h >= 18 && h < 24) return '晚上';
    return '深夜';
  }

  static String playerNaturalTimeLabel(Player player) {
    return '${clockLabel(player)} ${dayPeriodLabel(player.naturalHour)}';
  }

  static String eventNaturalTimeLabel(GameEventRecord event) {
    return '${eventClockLabel(event)} ${dayPeriodLabel(event.naturalHour)}';
  }

  static Player _normalizeClock(Player player) {
    final hour = player.naturalHour.clamp(0, 23).toInt();
    final minute = player.naturalMinute.clamp(0, 59).toInt();
    if (hour == player.naturalHour && minute == player.naturalMinute) {
      return player;
    }
    return player.copyWith(naturalHour: hour, naturalMinute: minute);
  }

  static Future<Map<String, int>> _loadConsumeRules() async {
    if (_cachedConsumeMinutes != null) return _cachedConsumeMinutes!;

    try {
      final jsonStr = await rootBundle.loadString(_rulesAssetPath);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final rawRules = data['time_consume_rules'];
      final rules = <String, int>{};

      if (rawRules is List) {
        for (final raw in rawRules) {
          if (raw is! Map) continue;
          final id = raw['id']?.toString().trim() ?? '';
          final minutes = (raw['minutes'] as num?)?.toInt();
          if (id.isEmpty || minutes == null) continue;
          rules[id] = minutes < 0 ? 0 : minutes;
        }
      }

      _cachedConsumeMinutes = rules;
      return rules;
    } catch (e) {
      debugPrint('[NaturalTimeService] 读取时间消耗规则失败: $e');
      _cachedConsumeMinutes = const {};
      return _cachedConsumeMinutes!;
    }
  }
}
