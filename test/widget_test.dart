// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:elderland/main.dart';

void main() {
  testWidgets('App shows loading page', (WidgetTester tester) async {
    await tester.pumpWidget(const ElderlandApp());

    // LoadingPage 显示健康游戏忠告
    expect(find.text('健康游戏忠告'), findsOneWidget);
    expect(find.text('抵制不良游戏，拒绝盗版游戏。'), findsOneWidget);

    // 推进 3 秒定时器，让 LoadingPage 完成跳转
    await tester.pump(const Duration(seconds: 4));
  });
}
