import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/player.dart';
import '../pages/start_page.dart';
import '../services/save_service.dart';
import '../services/world_save_service.dart';
import '../services/world_service.dart';
import 'developer_panel_dialog.dart';

class SettingsDialog extends StatelessWidget {
  final Player player;
  final Future<void> Function()? onAdvancePlayerDay;
  final Future<void> Function()? onInspectNpcStatus;
  final Future<void> Function()? onSimulateVillageActions;
  final Future<void> Function()? onOpenWorldMap;
  final Future<void> Function()? onClearAllSaves;

  const SettingsDialog({
    super.key,
    required this.player,
    this.onAdvancePlayerDay,
    this.onInspectNpcStatus,
    this.onSimulateVillageActions,
    this.onOpenWorldMap,
    this.onClearAllSaves,
  });

  static Future<void> show(
    BuildContext context,
    Player player, {
    Future<void> Function()? onAdvancePlayerDay,
    Future<void> Function()? onInspectNpcStatus,
    Future<void> Function()? onSimulateVillageActions,
    Future<void> Function()? onOpenWorldMap,
    Future<void> Function()? onClearAllSaves,
  }) {
    return showDialog(
      context: context,
      builder: (_) => SettingsDialog(
        player: player,
        onAdvancePlayerDay: onAdvancePlayerDay,
        onInspectNpcStatus: onInspectNpcStatus,
        onSimulateVillageActions: onSimulateVillageActions,
        onOpenWorldMap: onOpenWorldMap,
        onClearAllSaves: onClearAllSaves,
      ),
    );
  }

  static DateTime? _lastTipTime;

  void _showTip(BuildContext context, String message) {
    final now = DateTime.now();
    if (_lastTipTime != null &&
        now.difference(_lastTipTime!).inMilliseconds < 1000) {
      return;
    }
    _lastTipTime = now;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text("退出游戏"),
          content: const Text("你确定要退出游戏吗？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("返回"),
            ),
            TextButton(
              key: const ValueKey('back_to_title_button'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const StartPage()),
                  (route) => false,
                );
              },
              child: const Text("回到标题"),
            ),
            TextButton(
              key: const ValueKey('game_exit_button'),
              onPressed: () {
                Navigator.of(ctx).pop();
                SystemNavigator.pop();
              },
              child: const Text("结束游戏"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeveloperPanel(BuildContext context) {
    DeveloperPanelDialog.show(
      context,
      onAdvancePlayerDay: onAdvancePlayerDay,
      onInspectNpcStatus: onInspectNpcStatus,
      onSimulateVillageActions: onSimulateVillageActions,
      onOpenWorldMap: onOpenWorldMap,
      onClearAllSaves: onClearAllSaves ?? () => _clearAllSaves(context),
    );
  }

  Future<void> _clearAllSaves(BuildContext context) async {
    debugPrint('[Developer] 清除全部存档');
    await SaveService().clearPlayerSave();
    await WorldSaveService().clearWorldSave();
    WorldService().clearNpcs();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StartPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.075),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.02,
                right: size.width * 0.03,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.settings_outlined,
                      size: 42,
                      color: Color(0xFF777777),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "设置界面",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "这里保留正式设置入口；开发阶段测试功能统一放进开发者面板。",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF777777),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 180,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeveloperPanel(context),
                        icon: const Icon(Icons.bug_report_outlined, size: 18),
                        label: const Text("开发者面板"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF333333),
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.02),
              child: Center(
                child: SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: () async {
                      await SaveService().savePlayer(player);
                      if (!context.mounted) return;
                      _showTip(context, '存档成功');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF333333),
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text("立即存档"),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.04),
              child: Center(
                child: SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: () => _showExitConfirmDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF333333),
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text("退出游戏"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
