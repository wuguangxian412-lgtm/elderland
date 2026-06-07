import 'package:flutter/material.dart';

import '../models/building.dart';
import '../models/npc.dart';
import '../models/player.dart';
import '../models/quest.dart';

class QuestOfferDialog extends StatelessWidget {
  final Player player;
  final Npc npc;
  final Building building;
  final List<Quest> quests;

  const QuestOfferDialog({
    super.key,
    required this.player,
    required this.npc,
    required this.building,
    required this.quests,
  });

  static Future<Quest?> show(
    BuildContext context, {
    required Player player,
    required Npc npc,
    required Building building,
    required List<Quest> quests,
  }) {
    return showDialog<Quest>(
      context: context,
      builder: (_) => QuestOfferDialog(
        player: player,
        npc: npc,
        building: building,
        quests: quests,
      ),
    );
  }

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);
  static const Color _bgSoft = Color(0xFFFAFAFA);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '可接委托',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${npc.name} · ${building.name.isEmpty ? player.location : building.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
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
              child: quests.isEmpty
                  ? const Center(
                      child: Text(
                        '当前没有可接取的委托',
                        style: TextStyle(fontSize: 15, color: _textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: quests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _questCard(context, quests[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questCard(BuildContext context, Quest quest) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgSoft,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quest.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            quest.description,
            style: const TextStyle(fontSize: 13, color: _text, height: 1.45),
          ),
          const SizedBox(height: 10),
          _infoLine('进度', quest.progressSummary),
          _infoLine('报酬', quest.rewardSummary),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(quest),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
              ),
              child: const Text('接受'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '暂无' : value,
            style: const TextStyle(fontSize: 13, color: _text, height: 1.4),
          ),
        ],
      ),
    );
  }
}
