import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/timeline_entry.dart';

/// 时间线数据库服务
///
/// 负责从 assets/data/timeline.json 读取并查询时间线事件。
class TimelineService {
  static const String _assetPath = 'assets/data/timeline.json';

  List<TimelineEntry>? _cached;

  /// 加载全部时间线条目，返回 List<TimelineEntry>
  Future<List<TimelineEntry>> loadTimeline() async {
    if (_cached != null) return _cached!;

    final jsonStr = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    final timelineList = decoded['timeline'];
    if (timelineList is! List) {
      throw Exception('timeline.json 缺少 timeline 字段');
    }

    final result = timelineList
        .whereType<Map<String, dynamic>>()
        .map(TimelineEntry.fromJson)
        .toList();
    _cached = result;
    return result;
  }

  /// 根据年份和季节查询对应时间线事件
  Future<TimelineEntry?> getTimelineByYearSeason(
    int year,
    String season,
  ) async {
    final timeline = await loadTimeline();
    for (final entry in timeline) {
      if (entry.year == year && entry.season == season) {
        debugPrint('TIMELINE MATCH: ${entry.title}');
        return entry;
      }
    }
    debugPrint('TIMELINE NOT FOUND: $year $season');
    return null;
  }
}
