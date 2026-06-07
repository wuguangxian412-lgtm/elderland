import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/player.dart';

class SaveService {
  static const String _fileName = 'player_save.json';
  static const int _saveVersion = 1;

  /// 对话详情记录会比统一经历更占空间，因此只保留最近一部分完整详情。
  /// 统一经历仍然是长期主记录，避免存档无限膨胀。
  static const int _maxInteractionRecords = 50;
  static const int _maxEventRecords = 300;
  static const int _maxImportantEventRecords = 100;

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
    final normalizedPlayer = _normalizePlayerForSave(player);
    final data = {'version': _saveVersion, 'data': normalizedPlayer.toJson()};
    await file.writeAsString(jsonEncode(data), flush: true);
    debugPrint('SAVE SUCCESS: ${file.path}');
  }

  /// 保存前统一收束玩家存档体积。
  ///
  /// 规则：
  /// - interactionRecords：保留最近 50 条完整对话详情；
  /// - eventRecords：保留最近 300 条统一经历；
  /// - importantEventRecords：保留最近 100 条重要经历；
  /// - relationships / activeQuests 不截断，因为它们是当前可见玩法状态。
  Player _normalizePlayerForSave(Player player) {
    return player.copyWith(
      interactionRecords: _takeLast(player.interactionRecords, _maxInteractionRecords),
      eventRecords: _takeLast(player.eventRecords, _maxEventRecords),
      importantEventRecords: _takeLast(
        player.importantEventRecords,
        _maxImportantEventRecords,
      ),
    );
  }

  List<T> _takeLast<T>(List<T> source, int maxCount) {
    if (source.length <= maxCount) return source;
    return source.sublist(source.length - maxCount);
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
