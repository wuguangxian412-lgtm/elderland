import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/player.dart';

class SaveService {
  static const String _fileName = 'player_save.json';

  /// 存档目录获取
  Future<String> get _localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// 存档文件引用
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<void> savePlayer(Player player) async {
    debugPrint('SAVE START');
    final file = await _localFile;
    final data = {'version': 1, 'data': player.toJson()};
    debugPrint('SAVE DATA: $data');
    await file.writeAsString(jsonEncode(data));
    debugPrint('SAVE SUCCESS');
  }

  Future<Player?> loadPlayer() async {
    debugPrint('LOAD START');
    try {
      final file = await _localFile;
      debugPrint('CHECK FILE EXISTS');
      if (!await file.exists()) {
        debugPrint('FILE NOT EXISTS');
        return null;
      }
      final content = await file.readAsString();
      debugPrint('RAW CONTENT: $content');
      final data = jsonDecode(content) as Map<String, dynamic>;
      debugPrint('PARSED DATA: $data');
      final playerData = data['data'] as Map<String, dynamic>;
      debugPrint('PLAYER DATA: $playerData');
      final player = Player.fromJson(playerData);
      debugPrint('locationId: ${player.locationId}');
      debugPrint('LOAD SUCCESS');
      return player;
    } catch (e) {
      debugPrint('LOAD ERROR: $e');
      return null;
    }
  }

  /// 自动存档接口
  Future<void> autoSave(Player player) async {
    await savePlayer(player);
  }
}
