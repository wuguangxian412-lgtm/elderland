import 'package:flutter/material.dart';

import '../models/npc_relationship.dart';
import '../models/player.dart';

class CharacterRelationshipTab extends StatelessWidget {
  final Player player;
  final Size size;

  const CharacterRelationshipTab({
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
    final rels = player.relationships;

    if (rels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 40, color: _textSecondary),
            SizedBox(height: 8),
            Text(
              '暂无人脉记录',
              style: TextStyle(fontSize: 15, color: _textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rels.map(_buildRelCard).toList(),
    );
  }

  Widget _buildRelCard(NpcRelationship rel) {
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
          Text(
            rel.npcName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          if (rel.knownIdentity.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              rel.knownIdentity,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '好感：${rel.affinity}',
                style: TextStyle(
                  fontSize: 13,
                  color: rel.affinity >= 0 ? _accent : const Color(0xFFD48383),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '互动次数：${rel.interactionCount}',
                style: const TextStyle(fontSize: 13, color: _textSecondary),
              ),
            ],
          ),
          if (rel.lastInteractionSummary.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              '最近：${rel.lastInteractionSummary}',
              style: const TextStyle(fontSize: 12, color: _textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (rel.lastMetLocationName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${rel.year}年${rel.season} · ${rel.lastMetLocationName}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
              ),
            ),
        ],
      ),
    );
  }
}
