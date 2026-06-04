import 'package:flutter/material.dart';

import '../models/player.dart';

class CharacterInfoDialog extends StatelessWidget {
  final Player player;

  const CharacterInfoDialog({super.key, required this.player});

  static Future<void> show(BuildContext context, Player player) {
    return showDialog(
      context: context,
      builder: (_) => CharacterInfoDialog(player: player),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.075),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: size.height * 0.72,
        child: Column(
          children: [
            // 关闭按钮
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.015,
                right: size.width * 0.02,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // 内容
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  children: [
                    _buildHeader(size),
                    SizedBox(height: size.height * 0.025),
                    _buildAttributes(size),
                    SizedBox(height: size.height * 0.025),
                    _buildPlaceholderCard(size, '角色段位'),
                    SizedBox(height: size.height * 0.015),
                    _buildPlaceholderCard(size, '职业等级'),
                    SizedBox(height: size.height * 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    // 血条百分比（防除零）
    final currentHp = player.hp.clamp(0, player.maxHp);
    final hpPercent = player.maxHp > 0 ? currentHp / player.maxHp : 0.0;

    return Column(
      children: [
        // 头像
        Container(
          width: size.width * 0.18,
          height: size.width * 0.18,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E5E0),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
          ),
          child: const Icon(Icons.person, size: 40, color: Color(0xFF999999)),
        ),
        SizedBox(height: size.height * 0.012),
        // 姓名
        Text(
          player.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: size.height * 0.004),
        // 年龄
        Text(
          '${player.age}岁',
          style: const TextStyle(fontSize: 14, color: Color(0xFF777777)),
        ),
        SizedBox(height: size.height * 0.018),
        // HP 文本
        Text(
          'HP: ${player.hp} / ${player.maxHp}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        ),
        SizedBox(height: size.height * 0.006),
        // 血条
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hpPercent,
            minHeight: 8,
            backgroundColor: const Color(0xFFE8E5E0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7BAE7F)),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributes(Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _attrRow('力量', player.strength)),
              SizedBox(width: size.width * 0.06),
              Expanded(child: _attrRow('防御', player.defense)),
            ],
          ),
          SizedBox(height: size.height * 0.015),
          Row(
            children: [
              Expanded(child: _attrRow('敏捷', player.agility)),
              SizedBox(width: size.width * 0.06),
              Expanded(child: _attrRow('魅力', player.charm)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attrRow(String label, int value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
        ),
        const Spacer(),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderCard(Size size, String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: size.height * 0.008),
          const Text(
            '暂无',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
