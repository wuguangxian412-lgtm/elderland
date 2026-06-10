import 'package:flutter/material.dart';

import '../models/game_event_record.dart';
import '../models/interaction_record.dart';
import '../models/player.dart';

class CharacterHistoryTab extends StatelessWidget {
  final Player player;
  final Size size;

  const CharacterHistoryTab({
    super.key,
    required this.player,
    required this.size,
  });

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _softCard = Color(0xFFFAFAFA);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

  @override
  Widget build(BuildContext context) {
    final records = player.eventRecords.isNotEmpty
        ? player.eventRecords.reversed.toList()
        : _legacyEventsFromInteractions().reversed.toList();

    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 40, color: _textSecondary),
            SizedBox(height: 8),
            Text(
              '暂无经历记录',
              style: TextStyle(fontSize: 15, color: _textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (player.importantEventRecords.isNotEmpty) _importantSummary(),
        ...records.map((record) => _eventCard(context, record)),
      ],
    );
  }

  Widget _importantSummary() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: size.height * 0.01),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        '重要经历：${player.importantEventRecords.length} 条',
        style: const TextStyle(
          fontSize: 13,
          color: _accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _eventCard(BuildContext context, GameEventRecord record) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showEventDetail(context, record),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: size.height * 0.01),
        padding: EdgeInsets.all(size.width * 0.03),
        decoration: BoxDecoration(
          color: _softCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _typePill(record.typeLabel),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.title.isEmpty ? '未命名经历' : record.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _text,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              record.summary.isEmpty ? '暂无摘要' : record.summary,
              style: const TextStyle(fontSize: 13, color: _text, height: 1.45),
            ),
            const SizedBox(height: 8),
            _metaText('时间：${record.timeLabel}'),
            if (record.locationName.isNotEmpty)
              _metaText(
                '地点：${record.locationName}${record.buildingName.isEmpty ? '' : ' / ${record.buildingName}'}',
              ),
            if (record.npcNames.isNotEmpty)
              _metaText('人物：${record.npcNames.join('、')}'),
          ],
        ),
      ),
    );
  }

  Widget _typePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: _accent,
          fontWeight: FontWeight.w700,
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

  void _showEventDetail(BuildContext context, GameEventRecord record) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.title.isEmpty ? '经历详情' : record.title,
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
                const Divider(height: 1, color: _border),
                const SizedBox(height: 12),
                _detailLine('类型', record.typeLabel),
                _detailLine('时间', record.timeLabel),
                _detailLine(
                  '地点',
                  record.locationName.isEmpty ? '未知' : record.locationName,
                ),
                _detailLine(
                  '建筑',
                  record.buildingName.isEmpty ? '无' : record.buildingName,
                ),
                _detailLine(
                  '相关人物',
                  record.npcNames.isEmpty ? '无' : record.npcNames.join('、'),
                ),
                _detailLine('结果', record.result.isEmpty ? '无' : record.result),
                _detailLine('摘要', record.summary.isEmpty ? '暂无摘要' : record.summary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: _text, height: 1.4),
          ),
        ],
      ),
    );
  }

  List<GameEventRecord> _legacyEventsFromInteractions() {
    return player.interactionRecords.map(_legacyEventFromInteraction).toList();
  }

  GameEventRecord _legacyEventFromInteraction(InteractionRecord record) {
    return GameEventRecord(
      id: 'legacy_${record.id}',
      type: GameEventRecord.typeDialogue,
      title: '与${record.npcName}交谈',
      summary: record.summary,
      year: record.year,
      season: record.season,
      day: record.day,
      locationId: record.locationId,
      locationName: record.locationName,
      buildingId: record.buildingId,
      buildingName: record.buildingName,
      npcIds: [record.npcId],
      npcNames: [record.npcName],
      result: 'legacy_interaction',
      metadata: {'interactionRecordId': record.id},
      createdAt: record.createdAt,
    );
  }
}
