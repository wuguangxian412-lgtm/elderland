import 'package:flutter/material.dart';

import 'pages/loading_page.dart';

void main() {
  runApp(const ElderlandApp());
}

class ElderlandApp extends StatelessWidget {
  const ElderlandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Elderland',
      debugShowCheckedModeBanner: false,
      home: LoadingPage(),
    );
  }
}
