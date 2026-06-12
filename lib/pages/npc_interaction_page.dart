import 'package:flutter/material.dart';

import '../dialogs/bag_dialog.dart';
import '../models/building.dart';
import '../models/dialogue_message.dart';
import '../models/interaction_record.dart';
import '../models/npc.dart';
import '../models/npc_interaction_result.dart';
import '../models/player.dart';
import '../services/natural_time_service.dart';

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
  final List<DialogueMessage> _messages = [];
  late Player _player;
  bool _isLeaving = false;
  bool _isSending = false;

  static const Color _bg = Color(0xFFF7F5F2);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    debugPrint('[NpcInteraction] 进入互动页面 npc=${widget.npc.id}');
    _messages.add(
      DialogueMessage(speaker: '系统', text: '你正在与【${widget.npc.name}】互动。'),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _leavePage() {
    if (_isLeaving) return;
    _isLeaving = true;
    debugPrint('[NpcInteraction] 离开互动页面 npc=${widget.npc.id}');
    final record = _buildInteractionRecord();
    Navigator.pop(
      context,
      NpcInteractionResult(player: _player, record: record),
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _isSending = true;
    debugPrint('[NpcInteraction] 玩家输入: $text');
    final reply = _mockNpcReply();
    final updatedPlayer = await NaturalTimeService.consumeAction(
      _player,
      NaturalTimeAction.npcMessage,
      fallbackMinutes: 3,
    );
    if (!mounted) return;
    setState(() {
      _player = updatedPlayer;
      _messages.add(DialogueMessage(speaker: '你', text: text));
      _messages.add(DialogueMessage(speaker: widget.npc.name, text: reply));
      _isSending = false;
    });
    _inputController.clear();
  }

  InteractionRecord? _buildInteractionRecord() {
    final hasPlayerMessage = _messages.any((m) => m.speaker == '你');
    if (!hasPlayerMessage) {
      debugPrint('[NpcInteraction] 无玩家消息，不保存互动记录');
      return null;
    }

    final record = InteractionRecord(
      npcId: widget.npc.id,
      npcName: widget.npc.name,
      locationId: _player.locationId,
      locationName: _player.location,
      buildingId: widget.building.id,
      buildingName: widget.building.name,
      year: _player.year,
      season: _player.season,
      day: _player.day,
      naturalHour: _player.naturalHour,
      naturalMinute: _player.naturalMinute,
      summary: '你与【${widget.npc.name}】进行了一次交谈，共记录 ${_messages.length} 条消息。',
      messages: _messages,
    );
    debugPrint(
      '[NpcInteraction] 生成互动记录 npc=${widget.npc.id} messageCount=${_messages.length}',
    );
    return record;
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
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope<NpcInteractionResult?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leavePage();
      },
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = keyboardVisible || constraints.maxHeight < 560;
              return Column(
                children: [
                  _buildHeader(compact: compact),
                  Expanded(child: _buildMessageList(compact: compact)),
                  _buildInputArea(
                    compact: compact,
                    keyboardVisible: keyboardVisible,
                  ),
                  if (!keyboardVisible) _buildPlayerBar(compact: compact),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool compact}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16, compact ? 6 : 10, 16, compact ? 4 : 6),
      padding: EdgeInsets.fromLTRB(12, compact ? 7 : 10, 12, compact ? 8 : 12),
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
          SizedBox(height: compact ? 2 : 4),
          Text(
            widget.npc.name,
            style: TextStyle(
              fontSize: compact ? 20 : 21,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          _npcInfoGrid(compact: compact),
        ],
      ),
    );
  }

  Widget _npcInfoGrid({required bool compact}) {
    final verticalGap = compact ? 4.0 : 6.0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoTile('所在地点', _player.location, compact: compact),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _infoTile('所在建筑', widget.building.name, compact: compact),
            ),
          ],
        ),
        SizedBox(height: verticalGap),
        Row(
          children: [
            Expanded(
              child: _infoTile('建筑类型', widget.building.type, compact: compact),
            ),
            const SizedBox(width: 8),
            Expanded(child: _infoTile('性格', _personalityText, compact: compact)),
          ],
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, {required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 9,
        vertical: compact ? 4 : 6,
      ),
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

  Widget _buildMessageList({required bool compact}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        padding: EdgeInsets.all(compact ? 10 : 12),
        itemCount: _messages.length,
        separatorBuilder: (_, _) => SizedBox(height: compact ? 8 : 10),
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageRow(message.speaker, message.text);
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

  Widget _buildInputArea({
    required bool compact,
    required bool keyboardVisible,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        compact ? 4 : 6,
        16,
        keyboardVisible ? 0 : (compact ? 4 : 6),
      ),
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
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
              maxLines: 1,
              style: const TextStyle(fontSize: 14, height: 1.2),
              textInputAction: TextInputAction.send,
              textAlignVertical: TextAlignVertical.center,
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(
                hintText: '输入你想说的话，或想做的事……',
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: compact ? 34 : 36,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: Size(compact ? 52 : 58, compact ? 30 : 32),
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                '发送',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBar({required bool compact}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16, 0, 16, compact ? 6 : 12),
      padding: EdgeInsets.all(compact ? 9 : 14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: compact ? _compactPlayerBarContent() : _fullPlayerBarContent(),
    );
  }

  Widget _compactPlayerBarContent() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _hpPill(compact: true),
        const SizedBox(width: 8),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _miniStat('攻', _player.strength),
                const SizedBox(width: 6),
                _miniStat('防', _player.defense),
                const SizedBox(width: 6),
                _miniStat('敏', _player.agility),
                const SizedBox(width: 6),
                _miniStat('魅', _player.charm),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 32,
          child: OutlinedButton.icon(
            onPressed: () => BagDialog.show(context),
            icon: const Icon(Icons.backpack_outlined, size: 16),
            label: const Text('背包'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _text,
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fullPlayerBarContent() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _player.name,
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
            Expanded(child: _playerStat('攻击', _player.strength)),
            const SizedBox(width: 8),
            Expanded(child: _playerStat('防御', _player.defense)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _playerStat('敏捷', _player.agility)),
            const SizedBox(width: 8),
            Expanded(child: _playerStat('魅力', _player.charm)),
          ],
        ),
      ],
    );
  }

  Widget _hpPill({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        'HP: ${_player.hp}/${_player.maxHp}',
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          color: _accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _miniStat(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 11,
          color: _textSecondary,
          fontWeight: FontWeight.w600,
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
