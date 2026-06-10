import 'package:flutter/material.dart';

import '../models/player.dart';

class CharacterInfoTab extends StatelessWidget {
  final Player player;
  final Size size;

  const CharacterInfoTab({
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
    final currentHp = player.hp.clamp(0, player.maxHp).toInt();
    final hpPercent = player.maxHp > 0 ? currentHp / player.maxHp : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHeader(currentHp, hpPercent),
        const SizedBox(height: 14),
        _buildAttributes(),
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

  Widget _buildProfileHeader(int currentHp, double hpPercent) {
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
                  '${player.name}  ${player.age}岁',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'HP：$currentHp / ${player.maxHp}',
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

  Widget _buildAttributes() {
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
              Expanded(child: _attrCell('力量', player.strength)),
              SizedBox(width: size.width * 0.03),
              Expanded(child: _attrCell('防御', player.defense)),
            ],
          ),
          SizedBox(height: size.height * 0.01),
          Row(
            children: [
              Expanded(child: _attrCell('敏捷', player.agility)),
              SizedBox(width: size.width * 0.03),
              Expanded(child: _attrCell('魅力', player.charm)),
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
}
