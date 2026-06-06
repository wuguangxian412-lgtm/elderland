import 'package:flutter/material.dart';

import '../models/interaction_record.dart';
import '../models/player.dart';

class HistoryDialog extends StatelessWidget {
  final Player player;

  const HistoryDialog({super.key, required this.player});

  static Future<void> show(BuildContext context, Player player) {
    return showDialog(
      context: context,
      builder: (_) => HistoryDialog(player: player),
    );
  }

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _bgSoft = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final records = player.interactionRecords.reversed.toList();

    return Dialog(
      backgroundColor: _card,
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.075),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                size.width * 0.05,
                size.height * 0.02,
                size.width * 0.03,
                8,
              ),
              child: Row(
                children: [
                  const Text(
                    '经历',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Expanded(
              child: records.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无经历记录',
                        style: TextStyle(fontSize: 16, color: _textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _recordCard(context, record);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(BuildContext context, InteractionRecord record) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showRecordDetail(context, record),
      child: Container(
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
              record.summary.isEmpty ? '一次未命名互动' : record.summary,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            _metaText(
              '时间：神圣历${record.year}年 ${record.season} Day ${record.day}',
            ),
            _metaText('地点：${record.locationName} / ${record.buildingName}'),
            _metaText('人物：${record.npcName}'),
          ],
        ),
      ),
    );
  }

  Widget _metaText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: _textSecondary),
      ),
    );
  }

  void _showRecordDetail(BuildContext context, InteractionRecord record) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.npcName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _text,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _border),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: record.messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final message = record.messages[index];
                    return Text(
                      '${message.speaker}：${message.text}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _text,
                        height: 1.5,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
