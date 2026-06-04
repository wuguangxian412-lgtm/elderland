import 'package:flutter/material.dart';

import '../data/flavor_text.dart';
import '../models/map_node.dart';
import '../services/world_service.dart';

/// 地点详情对话框
class LocationDetailDialog {
  static Future<void> show(
    BuildContext context,
    MapNode node, {
    bool isCurrentLocation = false,
    bool canMoveHere = false,
    Future<void> Function()? onMoveHere,
    String? moveHintText,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => _LocationDetailContent(
        node: node,
        isCurrentLocation: isCurrentLocation,
        canMoveHere: canMoveHere,
        onMoveHere: onMoveHere,
        moveHintText: moveHintText,
      ),
    );
  }
}

class _LocationDetailContent extends StatelessWidget {
  final MapNode node;
  final bool isCurrentLocation;
  final bool canMoveHere;
  final Future<void> Function()? onMoveHere;
  final String? moveHintText;

  const _LocationDetailContent({
    required this.node,
    this.isCurrentLocation = false,
    this.canMoveHere = false,
    this.onMoveHere,
    this.moveHintText,
  });

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              key: const ValueKey('location_detail_title'),
              node.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _text,
              ),
            ),
            const SizedBox(height: 16),
            // 类型
            _infoRow('类型', node.type),
            const SizedBox(height: 8),
            // 国家
            _infoRow('国家', node.country),
            const SizedBox(height: 16),
            // 描述
            const Text(
              '描述',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              node.description,
              style: const TextStyle(fontSize: 14, color: _text, height: 1.6),
            ),
            // 场景描述
            if (flavorTextMap[node.id] != null &&
                flavorTextMap[node.id]!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFE5E5E5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '❝ ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF777777),
                        height: 1.6,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        flavorTextMap[node.id]!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 当地 NPC
            _buildNpcSection(),
            const SizedBox(height: 16),
            // 移动区域
            _buildMoveSection(context),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('location_detail_close_button'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNpcSection() {
    final npcs = WorldService().findNpcsByLocation(node.id);
    debugPrint('地点 ${node.id} 当前 NPC 数量: ${npcs.length}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '当地 NPC',
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        if (npcs.isEmpty)
          const Text(
            '当前地点暂无可见 NPC',
            style: TextStyle(fontSize: 14, color: _textSecondary, height: 1.6),
          )
        else
          ...npcs.map(
            (npc) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: _textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      npc.name,
                      style: const TextStyle(fontSize: 14, color: _text),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7BAE7F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      npc.state,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7BAE7F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMoveSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCurrentLocation) ...[
          const Text(
            '移动',
            style: TextStyle(
              fontSize: 13,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFA5D6A7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Color(0xFF7BAE7F)),
                SizedBox(width: 6),
                Text(
                  '你当前就在这里',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ] else if (canMoveHere && onMoveHere != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('move_here_button'),
              onPressed: () async {
                await onMoveHere?.call();
                if (context.mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BAE7F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                moveHintText ?? '移动到这里',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFE0E0E0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.block, size: 16, color: _textSecondary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    key: ValueKey('location_move_hint_text'),
                    '无法直接移动到这里，需要先前往相邻地点。',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: _text),
          ),
        ),
      ],
    );
  }
}
