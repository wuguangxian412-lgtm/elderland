import 'package:flutter/material.dart';

import '../dialogs/bag_dialog.dart';
import '../models/building.dart';
import '../models/npc.dart';
import '../models/player.dart';

class NpcInteractionPage extends StatefulWidget {
  final Player player;
  final Npc npc;
  final Building building;

  const NpcInteractionPage({
    super.key,
    required this.player,
    required this.npc,
    required this.building,
  });

  @override
  State<NpcInteractionPage> createState() => _NpcInteractionPageState();
}

class _NpcInteractionPageState extends State<NpcInteractionPage> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  static const Color _bg = Color(0xFFF7F5F2);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

  @override
  void initState() {
    super.initState();
    debugPrint('[NpcInteraction] 进入互动页面 npc=${widget.npc.id}');
    _messages.add({'speaker': '系统', 'text': '你正在与【${widget.npc.name}】互动。'});
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _leavePage() {
    debugPrint('[NpcInteraction] 离开互动页面 npc=${widget.npc.id}');
    Navigator.pop(context);
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    debugPrint('[NpcInteraction] 玩家输入: $text');
    setState(() {
      _messages.add({'speaker': '你', 'text': text});
      _messages.add({'speaker': widget.npc.name, 'text': _mockNpcReply()});
    });
    _inputController.clear();
  }

  String _mockNpcReply() {
    if (widget.npc.name == '村长') {
      return '村长沉思片刻，说：最近村子附近并不太平，你最好多留意周围的人和事。';
    }
    if (widget.npc.name == '铁匠') {
      return '铁匠擦了擦手上的煤灰，说：想要趁手的工具，就得先有好材料。';
    }
    return '${widget.npc.name}看着你，似乎还在思考该如何回应。';
  }

  String get _npcStateText {
    switch (widget.npc.state) {
      case 'idle':
        return '空闲';
      default:
        return widget.npc.state;
    }
  }

  String get _personalityText {
    final type = widget.npc.personality['type'];
    if (type is String && type.trim().isNotEmpty) return type.trim();
    return '未知';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList()),
            _buildInputArea(),
            _buildPlayerBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: _leavePage,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('离开'),
                style: TextButton.styleFrom(
                  foregroundColor: _textSecondary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _npcStateText,
                  style: const TextStyle(fontSize: 12, color: _accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.npc.name,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          _npcInfoGrid(),
        ],
      ),
    );
  }

  Widget _npcInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _infoTile('所在地点', widget.player.location)),
            const SizedBox(width: 8),
            Expanded(child: _infoTile('所在建筑', widget.building.name)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _infoTile('建筑类型', widget.building.type)),
            const SizedBox(width: 8),
            Expanded(child: _infoTile('性格', _personalityText)),
          ],
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '未知' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final message = _messages[index];
          final speaker = message['speaker'] ?? '';
          final text = message['text'] ?? '';
          return _buildMessageRow(speaker, text);
        },
      ),
    );
  }

  Widget _buildMessageRow(String speaker, String text) {
    final isSystem = speaker == '系统';
    final isPlayer = speaker == '你';

    if (isSystem) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ),
      );
    }

    return Align(
      alignment: isPlayer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPlayer ? const Color(0xFFE8F5E9) : const Color(0xFFFAFAFA),
          border: Border.all(
            color: isPlayer ? const Color(0xFFA5D6A7) : _border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$speaker：$text',
          style: const TextStyle(fontSize: 14, color: _text, height: 1.45),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(
                hintText: '输入你想说的话，或想做的事……',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.player.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
              ),
              _hpPill(),
              const SizedBox(width: 10),
              SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: () => BagDialog.show(context),
                  icon: const Icon(Icons.backpack_outlined, size: 17),
                  label: const Text('背包'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _text,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _playerStat('攻击', widget.player.strength)),
              const SizedBox(width: 8),
              Expanded(child: _playerStat('防御', widget.player.defense)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _playerStat('敏捷', widget.player.agility)),
              const SizedBox(width: 8),
              Expanded(child: _playerStat('魅力', widget.player.charm)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hpPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        'HP: ${widget.player.hp}/${widget.player.maxHp}',
        style: const TextStyle(
          fontSize: 13,
          color: _accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _playerStat(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 13,
              color: _text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
