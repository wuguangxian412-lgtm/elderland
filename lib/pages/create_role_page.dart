import 'package:flutter/material.dart';

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
  DateTime? _lastTipTime;
  String playerName = '贤哥';
  int availablePoints = totalPoints;
  int strength = 0;
  int defense = 0;
  int agility = 0;
  int charm = 0;

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
              if (text.isNotEmpty) {
                setState(() => playerName = text);
              }
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
      backgroundColor: const Color(0xfff4f0e7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.92,
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.02),

                  // ===================
                  // 属性分配区域
                  // ===================
                  Container(
                    padding: EdgeInsets.all(size.width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      border: Border.all(color: Colors.brown.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // 头像
                            Container(
                              width: size.width * 0.18,
                              height: size.width * 0.18,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.brown,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Icons.person, size: 40),
                            ),

                            SizedBox(width: size.width * 0.03),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        playerName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () =>
                                            _showEditNameDialog(context),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "可用属性：$availablePoints",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _distributeEvenly,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "平均分配",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _resetAttributes,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "重置",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: size.height * 0.02),

                        Row(
                          children: [
                            Expanded(
                              child: _attributeCard(
                                "力量",
                                AttributeType.strength,
                                strength,
                                () =>
                                    _decrementAttribute(AttributeType.strength),
                                () =>
                                    _incrementAttribute(AttributeType.strength),
                                incrementKey: const ValueKey(
                                  'attr_strength_add_button',
                                ),
                              ),
                            ),
                            SizedBox(width: size.width * 0.03),
                            Expanded(
                              child: _attributeCard(
                                "防御",
                                AttributeType.defense,
                                defense,
                                () =>
                                    _decrementAttribute(AttributeType.defense),
                                () =>
                                    _incrementAttribute(AttributeType.defense),
                                incrementKey: const ValueKey(
                                  'attr_defense_add_button',
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: size.height * 0.015),

                        Row(
                          children: [
                            Expanded(
                              child: _attributeCard(
                                "敏捷",
                                AttributeType.agility,
                                agility,
                                () =>
                                    _decrementAttribute(AttributeType.agility),
                                () =>
                                    _incrementAttribute(AttributeType.agility),
                                incrementKey: const ValueKey(
                                  'attr_agility_add_button',
                                ),
                              ),
                            ),
                            SizedBox(width: size.width * 0.03),
                            Expanded(
                              child: _attributeCard(
                                "魅力",
                                AttributeType.charm,
                                charm,
                                () => _decrementAttribute(AttributeType.charm),
                                () => _incrementAttribute(AttributeType.charm),
                                incrementKey: const ValueKey(
                                  'attr_charm_add_button',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * 0.02),

                  // ===================
                  // 天赋选择
                  // ===================
                  _sectionTitle("家世选择"),

                  SizedBox(height: size.height * 0.01),

                  _talentCard(
                    title: "灵境记忆",
                    level: "玄级",
                    desc: "能够回忆前世在灵境中的修炼经验和感悟。",
                    effect: "根骨+1   悟性+2",
                  ),

                  SizedBox(height: size.height * 0.01),

                  _talentCard(
                    title: "灵识敏锐",
                    level: "地级",
                    desc: "福缘悟性双高，却影响气血成长。",
                    effect: "悟性+2   运气+2   气血-2%",
                  ),

                  SizedBox(height: size.height * 0.01),

                  _talentCard(
                    title: "神农之体",
                    level: "玄级",
                    desc: "拥有无上医术，于炼制神奇丹药有奇效。",
                    effect: "炼丹效率提升",
                  ),

                  SizedBox(height: size.height * 0.025),

                  // ===================
                  // 底部按钮
                  // ===================
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
                        debugPrint('CREATE PLAYER START');
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
                          year: 276,
                          season: '春',
                          day: 1,
                          money: 0,
                          triggeredTimelineEvents: [],
                        );
                        debugPrint(
                          'PLAYER INFO: name=${player.name}, hp=${player.hp}',
                        );
                        debugPrint('Player Created');
                        debugPrint('Name: ${player.name}');
                        debugPrint('Age: ${player.age}');
                        debugPrint('HP: ${player.hp}');
                        debugPrint('MaxHP: ${player.maxHp}');
                        debugPrint('Strength: ${player.strength}');
                        debugPrint('Defense: ${player.defense}');
                        debugPrint('Agility: ${player.agility}');
                        debugPrint('Charm: ${player.charm}');
                        debugPrint('Location: ${player.location}');
                        debugPrint('locationId: ${player.locationId}');
                        debugPrint('Year: ${player.year}');
                        debugPrint('Season: ${player.season}');
                        debugPrint('Day: ${player.day}');
                        debugPrint('Money: ${player.money}');
                        debugPrint('CALL SAVE PLAYER');
                        await SaveService().savePlayer(player);
                        debugPrint('SAVE CALLED FINISHED');
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameMainPage(player: player),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffaac8dc),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "创建角色",
                        style: TextStyle(fontSize: 20, color: Colors.black87),
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
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.brown.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          const Spacer(),

          _circleButton("-", onDecrement, key: decrementKey),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text("$value", style: const TextStyle(fontSize: 18)),
          ),

          _circleButton("+", onIncrement, key: incrementKey),
        ],
      ),
    );
  }

  Widget _circleButton(String text, VoidCallback? onPressed, {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: onPressed,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade300,
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _talentCard({
    required String title,
    required String level,
    required String desc,
    required String effect,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.brown.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(desc, style: const TextStyle(fontSize: 14)),

                const SizedBox(height: 6),

                Text(effect, style: const TextStyle(color: Colors.blue)),
              ],
            ),
          ),

          Column(
            children: [
              Text(
                level,
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.radio_button_unchecked),
            ],
          ),
        ],
      ),
    );
  }
}
