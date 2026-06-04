import 'dart:async';
import 'package:flutter/material.dart';
import 'start_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    // 3秒后跳转到游戏开始界面
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StartPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // Padding 确保左右两侧有安全间距，防止极小屏幕下贴边
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center, // 让大项在中间对齐
            children: [
              Text(
                '健康游戏忠告',
                style: TextStyle(
                  color: Color(0xFF795548),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2, // 字间距，更有古风感
                ),
              ),
              SizedBox(height: 30), // 标题和正文的间距
              // 用 Column 包裹文字并设置 crossAxisAlignment.start 确保文字块内部左对齐
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '抵制不良游戏，拒绝盗版游戏。',
                    style: TextStyle(
                      color: Color(0xFF795548),
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  Text(
                    '注意自我保护，谨防受骗上当。',
                    style: TextStyle(
                      color: Color(0xFF795548),
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  Text(
                    '适度游戏益脑，沉迷游戏伤身。',
                    style: TextStyle(
                      color: Color(0xFF795548),
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  Text(
                    '合理安排时间，享受健康生活。',
                    style: TextStyle(
                      color: Color(0xFF795548),
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
