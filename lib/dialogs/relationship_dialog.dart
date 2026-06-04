import 'package:flutter/material.dart';

class RelationshipDialog extends StatelessWidget {
  const RelationshipDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const RelationshipDialog(),
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
        height: size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.02,
                right: size.width * 0.03,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  "人脉界面",
                  style: TextStyle(fontSize: 18, color: Color(0xFF777777)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
