import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/building.dart';

/// 建筑数据服务：从静态资源加载并缓存建筑列表。
class BuildingService {
  static final BuildingService _instance = BuildingService._();
  factory BuildingService() => _instance;
  BuildingService._();

  static const String _buildingAssetPath = 'assets/data/building_data.json';

  Map<String, List<Building>>? _buildingsByLocation;

  Future<Map<String, List<Building>>> _loadAllBuildings() async {
    if (_buildingsByLocation != null) return _buildingsByLocation!;

    final jsonStr = await rootBundle.loadString(_buildingAssetPath);
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final locations = data['locations'] is Map
        ? Map<String, dynamic>.from(
            (data['locations'] as Map).map((k, v) => MapEntry(k.toString(), v)),
          )
        : <String, dynamic>{};

    final parsed = <String, List<Building>>{};
    for (final entry in locations.entries) {
      final rawList = entry.value;
      if (rawList is! List) {
        parsed[entry.key] = [];
        continue;
      }

      parsed[entry.key] = rawList
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => Building.fromJson(
              Map<String, dynamic>.from(
                item.map((k, v) => MapEntry(k.toString(), v)),
              ),
            ),
          )
          .toList();
    }

    _buildingsByLocation = parsed;
    return parsed;
  }

  Future<List<Building>> loadBuildingsByLocation(String locationId) async {
    final buildingsByLocation = await _loadAllBuildings();
    final buildings = List<Building>.unmodifiable(
      buildingsByLocation[locationId] ?? const <Building>[],
    );
    debugPrint('[BuildingService] 已加载 $locationId 的建筑数量: ${buildings.length}');
    return buildings;
  }
}
