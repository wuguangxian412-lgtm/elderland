import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/map_node.dart';

/// 地图数据服务
///
/// 负责从 assets/data/map_data.json 读取地图节点数据。
class MapService {
  static const String _assetPath = 'assets/data/map_data.json';

  List<MapNode>? _cached;

  /// 加载全部地图节点，返回 List<MapNode>
  Future<List<MapNode>> loadMap() async {
    if (_cached != null) return _cached!;

    final jsonStr = await rootBundle.loadString(_assetPath);
    debugPrint(
      '[MapService] JSON 前 300 字符: ${jsonStr.substring(0, jsonStr.length < 300 ? jsonStr.length : 300)}',
    );
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

    final mapDatas = decoded['map_datas'];
    if (mapDatas is! List) {
      throw Exception('map_data.json 缺少 map_datas 字段');
    }

    final result = mapDatas
        .whereType<Map<String, dynamic>>()
        .where((e) => e['id'] is String)
        .map((e) => MapNode.fromJson(e['id'] as String, e))
        .toList();

    debugPrint('[MapService] 地图节点数量: ${result.length}');
    for (final node in result.take(3)) {
      debugPrint('[MapService] ${node.id} -> ${node.name}');
    }

    _cached = result;
    return result;
  }
}
