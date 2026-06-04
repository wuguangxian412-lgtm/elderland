import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/player.dart';
import '../pages/start_page.dart';
import '../services/save_service.dart';

class SettingsDialog extends StatelessWidget {
  final Player player;

  const SettingsDialog({super.key, required this.player});

  static Future<void> show(BuildContext context, Player player) {
    return showDialog(
      context: context,
      builder: (_) => SettingsDialog(player: player),
    );
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
            const Expanded(
              child: Center(
                child: Text(
                  "设置界面",
                  style: TextStyle(fontSize: 18, color: Color(0xFF777777)),
                ),
              ),
            ),
            // 存档按钮
            Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.02),
              child: Center(
                child: SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: () async {
                      await SaveService().savePlayer(player);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('存档成功')));
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
