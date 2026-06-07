import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/player.dart';

class SaveService {
  static const String _fileName = 'player_save.json';
  static const int _saveVersion = 1;

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
    final file = await _localFile;
    final data = {'version': _saveVersion, 'data': player.toJson()};
    await file.writeAsString(jsonEncode(data), flush: true);
    debugPrint('SAVE SUCCESS: ${file.path}');
  }

  Future<void> clearPlayerSave() async {
    final file = await _localFile;
    if (await file.exists()) {
      await file.delete();
      debugPrint('CLEAR SAVE SUCCESS: ${file.path}');
    } else {
      debugPrint('CLEAR SAVE SKIPPED: player_save not found');
    }
  }

  Future<Player?> loadPlayer() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        debugPrint('FILE NOT EXISTS');
        return null;
      }

      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('LOAD ERROR: invalid save root');
        return null;
      }

      final version = (decoded['version'] as num?)?.toInt();
      if (version != _saveVersion) {
        debugPrint('LOAD ERROR: unsupported save version $version');
        return null;
      }

      final rawPlayerData = decoded['data'];
      if (rawPlayerData is! Map<String, dynamic>) {
        debugPrint('LOAD ERROR: invalid player data');
        return null;
      }

      final playerData = Map<String, dynamic>.from(rawPlayerData);
      final player = Player.fromJson(playerData);
      debugPrint('locationId: ${player.locationId}');
      debugPrint('LOAD SUCCESS');
      return player;
    } on FormatException catch (e) {
      debugPrint('LOAD ERROR: invalid JSON: $e');
      return null;
    } on FileSystemException catch (e) {
      debugPrint('LOAD ERROR: file system: $e');
      return null;
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
