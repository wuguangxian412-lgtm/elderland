import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/player.dart';
import '../widgets/elderland_pressable.dart';
import 'character_history_tab.dart';
import 'character_info_tab.dart';
import 'character_relationship_tab.dart';

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
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);
  static const double _tabWidth = 48;
  static const double _titleOverlapPadding = 38;
  static const _tabs = ['信息', '人脉', '经历'];

  int _selectedTab = 0;

  Player get _p => widget.player;

  String get _dialogTitle {
    switch (_selectedTab) {
      case 0:
        return '角色信息';
      case 1:
        return '人脉关系';
      case 2:
        return '人生经历';
      default:
        return '角色信息';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final panelW = math.max(
      230.0,
      math.min(size.width * 0.74, size.width - _tabWidth - 28),
    );
    final panelH = math.min(size.height * 2 / 3, size.height - 92);
    final contentH = panelH - 58 - _titleOverlapPadding;

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
                          height: panelH,
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
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.fromLTRB(
                                    size.width * 0.04,
                                    _titleOverlapPadding,
                                    size.width * 0.04,
                                    0,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: contentH,
                                    ),
                                    child: _buildContent(size, contentH),
                                  ),
                                ),
                              ),
                              Container(height: 1, color: _border),
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 14,
                                  top: 10,
                                ),
                                child: ElderlandPressableButton(
                                  label: '关闭',
                                  onTap: () => Navigator.of(context).pop(),
                                  filled: true,
                                  accentColor: _accent,
                                  textColor: _textSecondary,
                                  borderColor: _border,
                                  width: 90,
                                  height: 34,
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
                              child: Text(
                                _dialogTitle,
                                style: const TextStyle(
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
                    SizedBox(
                      height: panelH,
                      width: _tabWidth,
                      child: _buildSideTabs(panelH),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideTabs(double panelH) {
    final tabHeight = math.min(78.0, (panelH - 18) / _tabs.length);
    final totalTabsHeight = tabHeight * _tabs.length + 6 * (_tabs.length - 1);
    final targetCenterY = panelH * 0.4;
    final topOffset = math.max(0.0, targetCenterY - totalTabsHeight / 2);

    return Padding(
      padding: EdgeInsets.only(top: topOffset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedTab == i;
          return Padding(
            padding: EdgeInsets.only(bottom: i == _tabs.length - 1 ? 0 : 6),
            child: ElderlandPressableCard(
              key: ValueKey('character_info_tab_${_tabs[i]}'),
              onTap: () => setState(() => _selectedTab = i),
              backgroundColor: selected ? _accent.withValues(alpha: 0.16) : _card,
              borderColor: selected ? _accent : _border,
              overlayColor: _accent,
              borderRadius: 8,
              width: _tabWidth,
              height: tabHeight,
              padding: EdgeInsets.zero,
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
          );
        }),
      ),
    );
  }

  Widget _buildContent(Size size, double contentH) {
    switch (_selectedTab) {
      case 0:
        return CharacterInfoTab(player: _p, size: size);
      case 1:
        return CharacterRelationshipTab(
          player: _p,
          size: size,
          minHeight: contentH,
        );
      case 2:
        return CharacterHistoryTab(player: _p, size: size, minHeight: contentH);
      default:
        return CharacterInfoTab(player: _p, size: size);
    }
  }
}
