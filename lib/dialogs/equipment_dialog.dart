import 'package:flutter/material.dart';

class EquipmentDialog extends StatelessWidget {
  const EquipmentDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const EquipmentDialog(),
    );
  }

  static const Color _border = Color(0xFFE5E5E5);
  static const Color _accent = Color(0xFF7BAE7F);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: size.height * 0.72,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  children: [
                    _sectionCard(
                      title: '已穿戴装备',
                      itemCount: 8,
                      rows: 2,
                      tight: true,
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _sectionCard(
                        title: '已拥有装备',
                        itemCount: 16,
                        rows: 4,
                        tight: false,
                        scrollable: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14, top: 8),
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
    );
  }

  Widget _sectionCard({
    required String title,
    required int itemCount,
    required int rows,
    bool tight = false,
    bool scrollable = false,
  }) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: tight ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 10),
          if (tight)
            _grid(itemCount: itemCount, rows: rows, scrollable: scrollable)
          else
            Expanded(
              child: _grid(
                itemCount: itemCount,
                rows: rows,
                scrollable: scrollable,
              ),
            ),
        ],
      ),
    );

    return tight ? content : SizedBox.expand(child: content);
  }

  Widget _grid({
    required int itemCount,
    required int rows,
    bool scrollable = false,
  }) {
    const columns = 4;
    const spacing = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return SizedBox(
          height: cellSize * rows + spacing * (rows - 1),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: scrollable ? null : const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
