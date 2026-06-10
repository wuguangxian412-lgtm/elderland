import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/player.dart';
import '../services/save_service.dart';
import 'game_main_page.dart';

enum AttributeType { strength, defense, agility, charm }

class CreateRolePage extends StatefulWidget {
  const CreateRolePage({super.key});

  @override
  State<CreateRolePage> createState() => _CreateRolePageState();
}

class _CreateRolePageState extends State<CreateRolePage> {
  static const int totalPoints = 20;

  static const Color _bg = Color(0xFFF7F5F2);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _softCard = Color(0xFFFAFAFA);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

  DateTime? _lastTipTime;
  String playerName = '贤哥';
  int availablePoints = totalPoints;
  int strength = 0;
  int defense = 0;
  int agility = 0;
  int charm = 0;

  List<String> _factions = [];
  String? _selectedBirthplace;

  static const List<String> _familyIdentities = [
    '市井平民',
    '流放罪人',
    '没落贵族',
    '富商豪族',
    '地方领主',
    '魔法世家',
  ];
  String _selectedFamilyIdentity = '市井平民';

  static const List<String> _familyMemberOptions = ['哥哥', '姐姐', '弟弟', '妹妹'];
  final Set<String> _selectedFamilyMembers = {};

  bool _isLoadingFactions = true;

  @override
  void initState() {
    super.initState();
    _loadFactions();
  }

  Future<void> _loadFactions() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/world_lore.json',
      );
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final factionsRaw = data['factions'] as List<dynamic>? ?? [];
      final names = factionsRaw
          .whereType<Map<String, dynamic>>()
          .map((f) => (f['name'] as String? ?? '').trim())
          .where((n) => n.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _factions = names;
        _isLoadingFactions = false;
        if (_selectedBirthplace == null && _factions.isNotEmpty) {
          _selectedBirthplace = _factions.first;
        }
      });
    } catch (e) {
      debugPrint('[CreateRole] 加载 factions 失败: $e');
      if (!mounted) return;
      setState(() => _isLoadingFactions = false);
    }
  }

  void _incrementAttribute(AttributeType attr) {
    if (availablePoints <= 0) return;
    setState(() {
      availablePoints--;
      switch (attr) {
        case AttributeType.strength:
          strength++;
          break;
        case AttributeType.defense:
          defense++;
          break;
        case AttributeType.agility:
          agility++;
          break;
        case AttributeType.charm:
          charm++;
          break;
      }
    });
  }

  void _decrementAttribute(AttributeType attr) {
    setState(() {
      switch (attr) {
        case AttributeType.strength:
          if (strength > 0) {
            strength--;
            availablePoints++;
          }
          break;
        case AttributeType.defense:
          if (defense > 0) {
            defense--;
            availablePoints++;
          }
          break;
        case AttributeType.agility:
          if (agility > 0) {
            agility--;
            availablePoints++;
          }
          break;
        case AttributeType.charm:
          if (charm > 0) {
            charm--;
            availablePoints++;
          }
          break;
      }
    });
  }

  void _distributeEvenly() {
    if (availablePoints <= 0) return;
    setState(() {
      final total = availablePoints;
      final each = total ~/ 4;
      final remainder = total % 4;
      strength += each + (remainder > 0 ? 1 : 0);
      defense += each + (remainder > 1 ? 1 : 0);
      agility += each + (remainder > 2 ? 1 : 0);
      charm += each;
      availablePoints = 0;
    });
  }

  void _resetAttributes() {
    setState(() {
      strength = 0;
      defense = 0;
      agility = 0;
      charm = 0;
      availablePoints = totalPoints;
    });
  }

  void _showTip(String message) {
    final now = DateTime.now();
    if (_lastTipTime != null &&
        now.difference(_lastTipTime!).inMilliseconds < 1000) {
      return;
    }
    _lastTipTime = now;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: playerName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改名字'),
        content: TextField(
          key: const ValueKey('create_role_name_input'),
          controller: controller,
          autofocus: true,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) setState(() => playerName = text);
              Navigator.of(ctx).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.02),
                    _buildAttributeSection(size),
                    SizedBox(height: size.height * 0.018),
                    _buildBirthplaceSection(size),
                    SizedBox(height: size.height * 0.018),
                    _buildFamilyIdentitySection(size),
                    SizedBox(height: size.height * 0.018),
                    _buildFamilyMembersSection(size),
                    SizedBox(height: size.height * 0.025),
                    SizedBox(
                      width: size.width * 0.45,
                      height: size.height * 0.065,
                      child: ElevatedButton(
                        key: const ValueKey('create_role_confirm_button'),
                        onPressed: () async {
                          if (playerName.trim().isEmpty) {
                            _showTip('角色名字不能为空');
                            return;
                          }
                          if (availablePoints != 0) {
                            _showTip('请分配剩余属性点');
                            return;
                          }

                          final player = Player(
                            name: playerName,
                            gender: '男',
                            age: 18,
                            hp: 100,
                            maxHp: 100,
                            strength: strength,
                            defense: defense,
                            agility: agility,
                            charm: charm,
                            location: '银叶村',
                            locationId: 'silver_leaf_village',
                            country: '圣山王国',
                            year: 275,
                            season: '冬',
                            day: 1,
                            money: 0,
                            triggeredTimelineEvents: const [],
                          );

                          debugPrint('CREATE PLAYER: ${player.name}');
                          await SaveService().savePlayer(player);
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameMainPage(player: player),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '创建角色',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeSection(Size size) {
    return _buildSectionCard(size, [
      Row(
        children: [
          const Text(
            '角色属性',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          const Spacer(),
          _smallActionButton('平均', _distributeEvenly),
          const SizedBox(width: 8),
          _smallActionButton('重置', _resetAttributes),
        ],
      ),
      SizedBox(height: size.height * 0.012),
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E5E0),
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 2),
            ),
            child: const Icon(Icons.person, size: 26, color: _textSecondary),
          ),
          SizedBox(width: size.width * 0.025),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        playerName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _showEditNameDialog(context),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '剩余属性点：$availablePoints',
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      SizedBox(height: size.height * 0.012),
      Row(
        children: [
          Expanded(
            child: _attributeCard(
              '力量',
              AttributeType.strength,
              strength,
              () => _decrementAttribute(AttributeType.strength),
              () => _incrementAttribute(AttributeType.strength),
              incrementKey: const ValueKey('attr_strength_add_button'),
            ),
          ),
          SizedBox(width: size.width * 0.025),
          Expanded(
            child: _attributeCard(
              '防御',
              AttributeType.defense,
              defense,
              () => _decrementAttribute(AttributeType.defense),
              () => _incrementAttribute(AttributeType.defense),
              incrementKey: const ValueKey('attr_defense_add_button'),
            ),
          ),
        ],
      ),
      SizedBox(height: size.height * 0.01),
      Row(
        children: [
          Expanded(
            child: _attributeCard(
              '敏捷',
              AttributeType.agility,
              agility,
              () => _decrementAttribute(AttributeType.agility),
              () => _incrementAttribute(AttributeType.agility),
              incrementKey: const ValueKey('attr_agility_add_button'),
            ),
          ),
          SizedBox(width: size.width * 0.025),
          Expanded(
            child: _attributeCard(
              '魅力',
              AttributeType.charm,
              charm,
              () => _decrementAttribute(AttributeType.charm),
              () => _incrementAttribute(AttributeType.charm),
              incrementKey: const ValueKey('attr_charm_add_button'),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _attributeCard(
    String label,
    AttributeType type,
    int value,
    VoidCallback onDecrement,
    VoidCallback onIncrement, {
    Key? incrementKey,
    Key? decrementKey,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: _textSecondary),
          ),
          const Spacer(),
          _circleButton('-', onDecrement, key: decrementKey),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 14,
                color: _text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _circleButton('+', onIncrement, key: incrementKey),
        ],
      ),
    );
  }

  Widget _circleButton(String text, VoidCallback? onPressed, {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _accent.withValues(alpha: 0.14),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBirthplaceSection(Size size) {
    return _buildSectionCard(size, [
      Row(
        children: [
          const Text(
            '出生地(必选)',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          const Spacer(),
          _smallActionButton('随机', () {
            if (_factions.isEmpty) return;
            final idx = Random().nextInt(_factions.length);
            setState(() => _selectedBirthplace = _factions[idx]);
          }),
        ],
      ),
      SizedBox(height: size.height * 0.012),
      if (_isLoadingFactions)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('加载中…', style: TextStyle(color: _textSecondary)),
        )
      else if (_factions.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('暂无可选出生地', style: TextStyle(color: _textSecondary)),
        )
      else
        _buildChoiceWrap(_factions, _selectedBirthplace, (value) {
          setState(() => _selectedBirthplace = value);
        }),
    ]);
  }

  Widget _buildFamilyIdentitySection(Size size) {
    return _buildSectionCard(size, [
      Row(
        children: [
          const Text(
            '家族身份(必选)',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          const Spacer(),
          _smallActionButton('随机', () {
            final idx = Random().nextInt(_familyIdentities.length);
            setState(() => _selectedFamilyIdentity = _familyIdentities[idx]);
          }),
        ],
      ),
      SizedBox(height: size.height * 0.012),
      _buildChoiceWrap(_familyIdentities, _selectedFamilyIdentity, (value) {
        setState(() => _selectedFamilyIdentity = value);
      }),
    ]);
  }

  Widget _buildFamilyMembersSection(Size size) {
    return _buildSectionCard(size, [
      const Text(
        '家族成员(可多选或不选)',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: _text,
        ),
      ),
      SizedBox(height: size.height * 0.012),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _familyMemberOptions.map((m) {
          final selected = _selectedFamilyMembers.contains(m);
          return FilterChip(
            label: Text(m),
            selected: selected,
            selectedColor: _accent,
            backgroundColor: _card,
            side: BorderSide(color: selected ? _accent : _border),
            elevation: 0,
            pressElevation: 0,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? Colors.white : _text,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            onSelected: (val) {
              setState(() {
                if (val) {
                  _selectedFamilyMembers.add(m);
                } else {
                  _selectedFamilyMembers.remove(m);
                }
              });
            },
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildChoiceWrap(
    List<String> options,
    String? selectedValue,
    ValueChanged<String> onSelected,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((value) {
        final selected = selectedValue == value;
        return ChoiceChip(
          label: Text(value),
          selected: selected,
          selectedColor: _accent,
          backgroundColor: _card,
          side: BorderSide(color: selected ? _accent : _border),
          elevation: 0,
          pressElevation: 0,
          showCheckmark: false,
          labelStyle: TextStyle(
            color: selected ? Colors.white : _text,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(Size size, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.03),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _smallActionButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _softCard,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: _text,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
