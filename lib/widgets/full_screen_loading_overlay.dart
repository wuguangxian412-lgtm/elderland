import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


/// 全屏加载遮罩。
///
/// 用法示例：
/// ```dart
/// final loading = FullScreenLoadingOverlay.show(
///   context,
///   message: '正在加载世界内容...',
/// );
/// try {
///   loading.updateMessage('正在生成 NPC 行动...');
///   await someAsyncTask();
/// } finally {
///   await loading.hide();
/// }
/// ```
class FullScreenLoadingOverlay {
  static const Color _textSecondary = Color(0xFF777777);

  const FullScreenLoadingOverlay._();

  /// 显示全屏加载遮罩。
  ///
  /// [message] 是动画下方显示的加载文字，可通过返回的 controller 更新。
  /// [animation] 是中间动画区域，暂时可以不传；后续确定动画样式后替换这里即可。
  static FullScreenLoadingController show(
    BuildContext context, {
    String message = '加载中...',
    Widget? animation,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messageNotifier = ValueNotifier<String>(message);

    late final PageRoute<void> route;
    final controller = FullScreenLoadingController._(
      navigator: navigator,
      messageNotifier: messageNotifier,
      routeProvider: () => route,
    );

    route = PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 160),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animationController, secondaryAnimation) {
        return FadeTransition(
          opacity: animationController,
          child: _FullScreenLoadingBody(
            messageListenable: messageNotifier,
            animation: animation,
          ),
        );
      },
    );

    navigator.push(route);
    return controller;
  }

  /// 执行一个异步任务，并在任务期间自动显示全屏加载遮罩。
  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function(FullScreenLoadingController controller) task,
    String message = '加载中...',
    Widget? animation,
  }) async {
    final controller = show(context, message: message, animation: animation);
    try {
      return await task(controller);
    } finally {
      await controller.hide();
    }
  }

  static Widget defaultAnimation() {
    return const SizedBox(
      width: 42,
      height: 42,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: Color(0xFF6FA86F),
      ),
    );
  }
}

class FullScreenLoadingController {
  FullScreenLoadingController._({
    required NavigatorState navigator,
    required ValueNotifier<String> messageNotifier,
    required PageRoute<void> Function() routeProvider,
  }) : _navigator = navigator,
       _messageNotifier = messageNotifier,
       _routeProvider = routeProvider;

  final NavigatorState _navigator;
  final ValueNotifier<String> _messageNotifier;
  final PageRoute<void> Function() _routeProvider;
  bool _closed = false;

  bool get isClosed => _closed;

  void updateMessage(String message) {
    if (_closed) return;
    _messageNotifier.value = message;
  }

  Future<void> hide() async {
    if (_closed) return;
    _closed = true;

    final route = _routeProvider();
    if (route.isActive) {
      _navigator.removeRoute(route);
    }
    _messageNotifier.dispose();
    await Future<void>.delayed(Duration.zero);
  }
}

class _FullScreenLoadingBody extends StatelessWidget {
  const _FullScreenLoadingBody({
    required this.messageListenable,
    required this.animation,
  });

  final ValueListenable<String> messageListenable;
  final Widget? animation;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  animation ?? FullScreenLoadingOverlay.defaultAnimation(),
                  const SizedBox(height: 22),
                  ValueListenableBuilder<String>(
                    valueListenable: messageListenable,
                    builder: (context, message, _) {
                      return Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: FullScreenLoadingOverlay._textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
