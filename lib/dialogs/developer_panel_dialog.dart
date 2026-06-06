import 'package:flutter/material.dart';

class DeveloperPanelDialog extends StatelessWidget {
  final Future<void> Function()? onAdvancePlayerDay;
  final Future<void> Function()? onInspectNpcStatus;
  final Future<void> Function()? onSimulateVillageActions;
  final Future<void> Function()? onOpenWorldMap;

  const DeveloperPanelDialog({
    super.key,
    this.onAdvancePlayerDay,
    this.onInspectNpcStatus,
    this.onSimulateVillageActions,
    this.onOpenWorldMap,
  });

  static Future<void> show(
    BuildContext context, {
    Future<void> Function()? onAdvancePlayerDay,
    Future<void> Function()? onInspectNpcStatus,
    Future<void> Function()? onSimulateVillageActions,
    Future<void> Function()? onOpenWorldMap,
  }) {
    return showDialog(
      context: context,
      builder: (_) => DeveloperPanelDialog(
        onAdvancePlayerDay: onAdvancePlayerDay,
        onInspectNpcStatus: onInspectNpcStatus,
        onSimulateVillageActions: onSimulateVillageActions,
        onOpenWorldMap: onOpenWorldMap,
      ),
    );
  }

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _danger = Color(0xFFD87C7C);

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function()? action, {
    bool closePanelFirst = false,
  }) async {
    if (action == null) return;
    if (closePanelFirst && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: _card,
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.075),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: size.height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '开发者面板',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  const Text(
                    '这里放开发阶段用的测试按钮。正式玩法按钮以后不要放在这里。',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _panelButton(
                    icon: Icons.calendar_today_outlined,
                    title: '玩家时间+1天',
                    subtitle: '推进玩家日期，保存 player_save，并检查时间线事件。',
                    onTap: () => _runAction(context, onAdvancePlayerDay),
                  ),
                  _panelButton(
                    icon: Icons.people_alt_outlined,
                    title: '查看人物状态',
                    subtitle: '把当前 NPC 的 location / building / state 输出到调试日志。',
                    onTap: () => _runAction(context, onInspectNpcStatus),
                  ),
                  _panelButton(
                    icon: Icons.auto_awesome_outlined,
                    title: '模拟村内人物行动',
                    subtitle: '只在银叶村已有建筑内移动或修改人物状态，并保存 world_save。',
                    onTap: () => _runAction(context, onSimulateVillageActions),
                    accentColor: _danger,
                  ),
                  _panelButton(
                    icon: Icons.map_outlined,
                    title: '打开世界地图',
                    subtitle: '临时保留在开发者面板中的地图入口，方便测试移动。',
                    onTap: () => _runAction(
                      context,
                      onOpenWorldMap,
                      closePanelFirst: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final color = accentColor ?? _text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
