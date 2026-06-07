import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/npc.dart';

class WorldSaveService {
  static const String _fileName = 'world_save.json';
  static const int _saveVersion = 1;

  Future<String> get _localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    final file = File('$path/$_fileName');
    debugPrint('[WorldSaveService] world_save 路径: ${file.path}');
    return file;
  }

  Future<void> saveWorldNpcs(List<Npc> npcs) async {
    final file = await _localFile;
    final data = {
      'version': _saveVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'npcs': npcs.map((npc) => npc.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(data), flush: true);
    debugPrint('[WorldSaveService] 已保存 NPC 数量: ${npcs.length}');
  }

  Future<List<Npc>?> loadWorldNpcs() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        debugPrint('[WorldSaveService] 没有找到 world_save');
        return null;
      }

      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('[WorldSaveService] 读取 world_save 失败: invalid root');
        return null;
      }

      final rawNpcs = decoded['npcs'];
      if (rawNpcs is! List) {
        debugPrint('[WorldSaveService] 读取 world_save 失败: invalid npcs');
        return null;
      }

      final npcs = rawNpcs
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => Npc.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
      debugPrint('[WorldSaveService] 已读取 NPC 数量: ${npcs.length}');
      return npcs;
    } on FormatException catch (e) {
      debugPrint('[WorldSaveService] 读取 world_save 失败: $e');
      return null;
    } on FileSystemException catch (e) {
      debugPrint('[WorldSaveService] 读取 world_save 失败: $e');
      return null;
    } catch (e) {
      debugPrint('[WorldSaveService] 读取 world_save 失败: $e');
      return null;
    }
  }

  Future<bool> hasWorldSave() async {
    final file = await _localFile;
    return file.exists();
  }

  Future<void> clearWorldSave() async {
    final file = await _localFile;
    if (await file.exists()) {
      await file.delete();
      debugPrint('[WorldSaveService] 已清除 world_save: ${file.path}');
    } else {
      debugPrint('[WorldSaveService] 清除跳过，world_save 不存在');
    }
  }
}
