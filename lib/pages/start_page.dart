import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../services/save_service.dart';
import '../services/world_save_service.dart';
import '../services/world_service.dart';
import 'create_role_page.dart';
import 'game_main_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  DateTime? _lastTipTime;

  void _showTip(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '艾尔德兰',
                style: TextStyle(
                  color: Color(0xFF3E2723),
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 76),
              _buildButton(
                context,
                '开始游戏',
                false,
                () => _onStartGame(context),
                key: const ValueKey('start_create_role_button'),
              ),
              const SizedBox(height: 20),
              _buildButton(
                context,
                '继续游戏',
                false,
                () => _onContinueGame(context),
                key: const ValueKey('start_continue_game_button'),
              ),
              const SizedBox(height: 20),
              _buildButton(context, '赞助作者', false, () => _onSponsor(context)),
              const SizedBox(height: 20),
              _buildButton(
                context,
                '退出游戏',
                false,
                () => _onExit(context),
                key: const ValueKey('start_exit_game_button'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onStartGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text('要开始新的游戏吗？这会清除旧的玩家存档和世界状态。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await SaveService().clearPlayerSave();
              await WorldSaveService().clearWorldSave();
              WorldService().clearNpcs();
              debugPrint('[StartPage] 新游戏已清除旧玩家存档和世界状态');
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CreateRolePage()),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _onContinueGame(BuildContext context) async {
    debugPrint('CONTINUE GAME CLICKED');
    debugPrint('LOADING PLAYER...');
    final player = await SaveService().loadPlayer();
    debugPrint('LOADED PLAYER = $player');
    if (player == null) {
      _showTip('暂无存档，请先开始新游戏');
      return;
    }
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameMainPage(player: player)),
    );
  }

  void _onSponsor(BuildContext context) {
    _showTip('可直接给贤哥转钱');
  }

  void _onExit(BuildContext context) {
    SystemNavigator.pop();
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    bool isLoading,
    VoidCallback onPressed, {
    Key? key,
  }) {
    return SizedBox(
      width: 200,
      height: 56,
      child: ElevatedButton(
        key: key,
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3E2723),
          elevation: 4,
          shadowColor: Colors.black38,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFD7CCC8)),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
