import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_event_record.dart';
import '../models/npc_relationship.dart';
import '../models/player.dart';

class CharacterInfoDialog extends StatefulWidget {
  final Player player;

  const CharacterInfoDialog({super.key, required this.player});

  static Future<void> show(BuildContext context, Player player) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CharacterInfoDialog(player: player),
    );
  }

  @override
  State<CharacterInfoDialog> createState() => _CharacterInfoDialogState();
}

class _CharacterInfoDialogState extends State<CharacterInfoDialog> {
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _softCard = Color(0xFFFAFAFA);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);
  static const double _tabWidth = 48;
  static const _tabs = ['信息', '人脉', '经历'];
  int _selectedTab = 0;

  Player get _p => widget.player;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final panelW = math.max(
      230.0,
      math.min(size.width * 0.74, size.width - _tabWidth - 28),
    );
    final maxPanelH = math.min(size.height * 0.76, size.height - 92);
    final minPanelH = math.min(size.height * 0.38, maxPanelH);

    return Material(
      color: Colors.transparent,
      child: DefaultTextStyle(
        style: const TextStyle(color: _text, decoration: TextDecoration.none),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                child: Container(color: Colors.black54),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: panelW,
                          constraints: BoxConstraints(
                            maxHeight: maxPanelH,
                            minHeight: minPanelH,
                          ),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(height: 1, color: _border),
                              Flexible(
                                fit: FlexFit.loose,
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.fromLTRB(
                                    size.width * 0.04,
                                    8,
                                    size.width * 0.04,
                                    0,
                                  ),
                                  child: _buildContent(size),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 14,
                                  top: 8,
                                ),
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 90,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: _accent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '关闭',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -30,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '角色信息',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildSideTabs(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideTabs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_tabs.length, (i) {
        final selected = _selectedTab == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('character_info_tab_${_tabs[i]}'),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                width: _tabWidth,
                height: 78,
                decoration: BoxDecoration(
                  color: selected ? _accent.withValues(alpha: 0.16) : _card,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border.all(
                    color: selected ? _accent : _border,
                    width: 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(1, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? _accent : _textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContent(Size size) {
    switch (_selectedTab) {
      case 0:
        return _buildInfoTab(size);
      case 1:
        return _buildRelationshipTab(size);
      case 2:
        return _buildHistoryTab(size);
      default:
        return _buildInfoTab(size);
    }
  }

  Widget _buildInfoTab(Size size) {
    final currentHp = _p.hp.clamp(0, _p.maxHp).toInt();
    final hpPercent = _p.maxHp > 0 ? currentHp / _p.maxHp : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHeader(size, currentHp, hpPercent),
        const SizedBox(height: 14),
        _buildAttributes(size),
        const SizedBox(height: 14),
        _buildSectionTitle('家族身份'),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            '家族身份功能未制作',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ),
        const SizedBox(height: 14),
        _buildSectionTitle('人物背景'),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            '人物背景功能未制作',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProfileHeader(Size size, int currentHp, double hpPercent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _softCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E5E0),
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 2),
            ),
            child: const Icon(Icons.person, size: 26, color: Colors.grey),
          ),
          SizedBox(width: size.width * 0.025),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_p.name}  ${_p.age}岁',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'HP：$currentHp / ${_p.maxHp}',
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hpPercent,
                    minHeight: 6,
                    backgroundColor: _border,
                    valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributes(Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.025,
        vertical: size.height * 0.012,
      ),
      decoration: BoxDecoration(
        color: _softCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _attrCell('力量', _p.strength)),
              SizedBox(width: size.width * 0.03),
              Expanded(child: _attrCell('防御', _p.defense)),
            ],
          ),
          SizedBox(height: size.height * 0.01),
          Row(
            children: [
              Expanded(child: _attrCell('敏捷', _p.agility)),
              SizedBox(width: size.width * 0.03),
              Expanded(child: _attrCell('魅力', _p.charm)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attrCell(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: _textSecondary),
          ),
          const Spacer(),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(height: 1, color: _border)),
      ],
    );
  }

  Widget _buildRelationshipTab(Size size) {
    final rels = _p.relationships;

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
      children: rels.map((r) => _buildRelCard(size, r)).toList(),
    );
  }

  Widget _buildRelCard(Size size, NpcRelationship rel) {
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

  Widget _buildHistoryTab(Size size) {
    final events = _p.eventRecords;

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
      children: sorted.map((e) => _buildEventCard(size, e)).toList(),
    );
  }

  Widget _buildEventCard(Size size, GameEventRecord event) {
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
