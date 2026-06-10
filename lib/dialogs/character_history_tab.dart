import 'package:flutter/material.dart';

import '../models/game_event_record.dart';
import '../models/player.dart';

class CharacterHistoryTab extends StatelessWidget {
  final Player player;
  final Size size;

  const CharacterHistoryTab({
    super.key,
    required this.player,
    required this.size,
  });

  static const Color _softCard = Color(0xFFFAFAFA);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

  @override
  Widget build(BuildContext context) {
    final events = player.eventRecords;

    if (events.isEmpty) {
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

    final sorted = List<GameEventRecord>.from(events)
      ..sort((a, b) {
        if (a.year != b.year) return b.year.compareTo(a.year);
        return b.day.compareTo(a.day);
      });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sorted.map(_buildEventCard).toList(),
    );
  }

  Widget _buildEventCard(GameEventRecord event) {
    return Container(
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
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.typeLabel,
                  style: const TextStyle(fontSize: 11, color: _accent),
                ),
              ),
            ],
          ),
          if (event.summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.summary,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 3),
          Text(
            '${event.year}年${event.season}${event.day}日'
            '${event.locationName.isNotEmpty ? ' · ${event.locationName}' : ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }
}
