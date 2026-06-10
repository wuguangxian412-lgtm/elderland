import 'package:flutter/material.dart';

import '../models/npc_relationship.dart';
import '../models/player.dart';
import '../models/quest.dart';

class CharacterRelationshipTab extends StatelessWidget {
  final Player player;
  final Size size;
  final double minHeight;

  const CharacterRelationshipTab({
    super.key,
    required this.player,
    required this.size,
    required this.minHeight,
  });

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _softCard = Color(0xFFFAFAFA);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

  @override
  Widget build(BuildContext context) {
    final rels = _visibleRelationships();

    if (rels.isEmpty) {
      return SizedBox(
        height: minHeight,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 40, color: _textSecondary),
              SizedBox(height: 8),
              Text(
                '暂无人脉记录\n与 NPC 互动，或接受 NPC 的委托后会出现在这里。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rels.map((rel) => _relationshipCard(context, rel)).toList(),
    );
  }

  List<NpcRelationship> _visibleRelationships() {
    final resultByNpcId = <String, NpcRelationship>{};

    for (final relationship in player.relationships) {
      if (relationship.npcId.isEmpty) continue;
      resultByNpcId[relationship.npcId] = relationship;
    }

    for (final Quest quest in player.activeQuests) {
      final npcId = quest.issuerNpcId.trim();
      if (npcId.isEmpty || resultByNpcId.containsKey(npcId)) continue;

      resultByNpcId[npcId] = NpcRelationship(
        npcId: npcId,
        npcName: quest.issuerNpcName.trim().isEmpty
            ? '未知人物'
            : quest.issuerNpcName,
        knownIdentity: '委托发布人',
        affinity: 0,
        interactionCount: 0,
        year: quest.acceptedYear,
        season: quest.acceptedSeason,
        day: quest.acceptedDay,
        lastMetLocationName: '通过委托建立联系',
        lastMetBuildingName: '',
        lastInteractionSummary: '已接受委托：${quest.title}',
        memorySummary: '你尚未与对方进行有效对话，但已经接受了对方的委托。',
        createdAt: quest.createdAt,
        updatedAt: quest.createdAt,
      );
    }

    final relationships = resultByNpcId.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return relationships;
  }

  Widget _relationshipCard(BuildContext context, NpcRelationship relationship) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showRelationshipDetail(context, relationship),
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
                Expanded(
                  child: Text(
                    relationship.npcName.isEmpty
                        ? '未知人物'
                        : relationship.npcName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _text,
                    ),
                  ),
                ),
                _affinityPill(relationship.affinityLabel),
              ],
            ),
            const SizedBox(height: 6),
            _metaText(
              '身份：${relationship.knownIdentity.isEmpty ? '未知' : relationship.knownIdentity}',
            ),
            _metaText('互动次数：${relationship.interactionCount}'),
            _metaText(
              '上次联系：${relationship.lastMetLocationName}${relationship.lastMetBuildingName.isEmpty ? '' : ' / ${relationship.lastMetBuildingName}'}',
            ),
            if (relationship.canSendLetter)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '通信：已解锁（功能后续开放）',
                  style: TextStyle(fontSize: 12, color: _accent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _affinityPill(String label) {
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
        style: const TextStyle(
          fontSize: 12,
          color: _textSecondary,
          height: 1.35,
        ),
      ),
    );
  }

  void _showRelationshipDetail(
    BuildContext context,
    NpcRelationship relationship,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
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
                        relationship.npcName,
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailLine('关系', relationship.affinityLabel),
                        _detailLine('关系值', relationship.affinity.toString()),
                        _detailLine(
                          '身份',
                          relationship.knownIdentity.isEmpty
                              ? '未知'
                              : relationship.knownIdentity,
                        ),
                        _detailLine(
                          '上次互动时间',
                          '神圣历${relationship.year}年 ${relationship.season} Day ${relationship.day}',
                        ),
                        _detailLine('上次联系地点', relationship.lastMetLocationName),
                        _detailLine(
                          '上次联系建筑',
                          relationship.lastMetBuildingName.isEmpty
                              ? '无'
                              : relationship.lastMetBuildingName,
                        ),
                        _detailLine(
                          '最近互动',
                          relationship.lastInteractionSummary.isEmpty
                              ? '暂无摘要'
                              : relationship.lastInteractionSummary,
                        ),
                        _detailLine(
                          '记忆摘要',
                          relationship.memorySummary.isEmpty
                              ? '暂无摘要'
                              : relationship.memorySummary,
                        ),
                      ],
                    ),
                  ),
                ),
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
}
