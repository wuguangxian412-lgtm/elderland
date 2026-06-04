import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'
    show
        PointerCancelEvent,
        PointerDownEvent,
        PointerScrollEvent,
        PointerUpEvent;

import '../models/map_node.dart';
import '../models/player.dart';
import '../services/map_service.dart';
import '../services/save_service.dart';
import '../services/time_service.dart';
import 'location_detail_dialog.dart';

/// 世界地图对话框
class WorldMapDialog {
  static Future<Player?> show(BuildContext context, Player player) {
    return showDialog<Player>(
      context: context,
      builder: (ctx) => _WorldMapContent(player: player),
    );
  }
}

class _WorldMapContent extends StatefulWidget {
  final Player player;

  const _WorldMapContent({required this.player});

  @override
  State<_WorldMapContent> createState() => _WorldMapContentState();
}

class _WorldMapContentState extends State<_WorldMapContent> {
  // AI Dynamic Expansion Reserved — Future AI-generated nodes (villages, towns,
  // dungeons, ruins, event sites, special instances) require no architecture changes.

  static const bool kMapDebugMode = false;

  late Player _player;
  List<MapNode>? _nodes;
  final List<MapNode> _dynamicNodes = [];
  String? _error;

  static Matrix4? _lastTransform;
  static double _lastScale = 1.0;

  double _currentScale = 1.0;
  final TransformationController _controller = TransformationController();
  final GlobalKey _mapContentKey = GlobalKey();

  static const double _minScale = 0.3;
  static const double _maxScale = 10.0;
  static const double _zoomStep = 0.1;

  /// 地图节点按钮的固定视觉尺寸。
  /// 这样“看得见的按钮区域”和“点击判定区域”可以保持一致。
  static const double _nodeButtonWidth = 112.0;
  static const double _nodeButtonHeight = 40.0;

  /// 点击判定额外扩展范围。
  /// 用来照顾模拟器鼠标点击、缩放后的轻微误差。
  static const double _nodeHitExtraPadding = 6.0;

  /// 判断一次 pointer 操作是点击还是拖动。
  /// 这个是屏幕像素距离，不是地图坐标距离。
  static const double _mapTapMoveTolerance = 10.0;

  /// 外层地图点击监听用。
  /// 不再依赖单个节点 GestureDetector 的命中。
  final Map<int, Offset> _mapPointerDownPositions = {};

  /// 缩放按钮长按相关 Timer
  Timer? _zoomLongPressDelayTimer;
  Timer? _zoomRepeatTimer;

  /// 最近一次构建节点时算出的标签偏移。
  /// 点击判定需要用到同一份偏移，否则视觉位置和判定位置会不一致。
  Map<String, Offset> _lastLabelOffsets = {};

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

  // 节点类型颜色
  static const Map<String, Color> _nodeBgColors = {
    '村庄': Color(0xFFF3F4F6),
    '城市': Color(0xFFE3F2FD),
    '要塞': Color(0xFFFFEBEE),
    '荒野': Color(0xFFFFF3E0),
  };
  static const Map<String, Color> _nodeBorderColors = {
    '村庄': Color(0xFFD1D5DB),
    '城市': Color(0xFF90CAF9),
    '要塞': Color(0xFFEF9A9A),
    '荒野': Color(0xFFFFB74D),
  };
  static const Map<String, Color> _nodeTextColors = {
    '村庄': Color(0xFF4B5563),
    '城市': Color(0xFF1565C0),
    '要塞': Color(0xFFC62828),
    '荒野': Color(0xFFE65100),
  };

  /// 缩放级别阈值：当前 scale >= 该值时，对应层级的节点才可见
  /// 层级 0(村庄) → scale ≥ 3.0  层级 1(城市) → scale ≥ 1.5  层级 2(其他) → scale ≥ 0.0
  static const List<double> _tierThresholds = [3.0, 1.5, 0.0];

  /// 节点 Map 缓存（性能优化：避免每次 build 重新遍历 _allNodes）
  Map<String, MapNode>? _nodeMapCache;

  Map<String, MapNode> get _nodeMap {
    _nodeMapCache ??= {for (final n in _allNodes) n.id: n};
    return _nodeMapCache!;
  }

  List<MapNode> get _allNodes => [...?_nodes, ..._dynamicNodes];

  List<MapNode> get _visibleNodes {
    final result = _allNodes
        .where((n) => _currentScale >= _tierThresholds[n.typeTier])
        .toList();
    if (kMapDebugMode) {
      debugPrint(
        '[Map] scale=$_currentScale  visible=${result.length}: ${result.map((n) => n.name).join("  ")}  dynamic=${_dynamicNodes.length}',
      );
    }
    return result;
  }

  /// 玩家当前所在地对应的 MapNode
  MapNode? get _currentLocationNode {
    for (final n in _allNodes) {
      if (n.id == _player.locationId) return n;
    }
    return null;
  }

  /// 判断目标节点是否与当前所在地相邻
  bool _isAdjacentToCurrentLocation(MapNode targetNode) {
    final currentNode = _currentLocationNode;
    if (currentNode == null) return false;
    if (targetNode.id == currentNode.id) return false;
    if (currentNode.connectedNodes.contains(targetNode.id)) return true;
    if (targetNode.connectedNodes.contains(currentNode.id)) return true;
    return false;
  }

  /// 执行移动到目标地点
  Future<void> _movePlayerToNode(MapNode targetNode) async {
    debugPrint('[MapMove] 准备移动: ${_player.locationId} -> ${targetNode.id}');

    final updatedPlayer = _player.copyWith(
      locationId: targetNode.id,
      location: targetNode.name,
      country: targetNode.country,
    );
    final advancedPlayer = TimeService.advanceOneDay(updatedPlayer);

    await SaveService().savePlayer(advancedPlayer);

    if (!mounted) return;
    setState(() {
      _player = advancedPlayer;
    });

    debugPrint(
      '[MapMove] 移动完成: locationId=${advancedPlayer.locationId}, location=${advancedPlayer.location}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已移动到：${targetNode.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    debugPrint('[WorldMap] 打开地图 locationId=${_player.locationId}');
    _controller.addListener(_onTransformChanged);
    _loadData();
  }

  @override
  void dispose() {
    _cancelZoomTimersOnly();
    _controller.removeListener(_onTransformChanged);
    _lastTransform = _controller.value.clone();
    _lastScale = _currentScale;
    _controller.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // AI Dynamic Expansion Reserved — 动态地图节点接口
  // 供后续 AI 引擎调用生成：村庄 / 城镇 / 地下城 / 遗迹 / 事件地点 / 特殊副本
  // ──────────────────────────────────────────────

  /// 添加一个 AI 动态生成的地图节点
  void addDynamicNode(MapNode node) {
    _nodeMapCache = null;
    setState(() => _dynamicNodes.add(node));
  }

  /// 批量添加动态节点
  void addDynamicNodes(List<MapNode> nodes) {
    _nodeMapCache = null;
    setState(() => _dynamicNodes.addAll(nodes));
  }

  /// 清除所有动态节点
  void clearDynamicNodes() {
    _nodeMapCache = null;
    setState(() => _dynamicNodes.clear());
  }

  /// 按 ID 移除动态节点
  void removeDynamicNode(String id) {
    _nodeMapCache = null;
    setState(() => _dynamicNodes.removeWhere((n) => n.id == id));
  }

  /// 更新指定动态节点（ID 不变，替换其他字段）
  void updateDynamicNode(MapNode node) {
    _nodeMapCache = null;
    setState(() {
      final idx = _dynamicNodes.indexWhere((n) => n.id == node.id);
      if (idx != -1) _dynamicNodes[idx] = node;
    });
  }

  /// 在所有节点（静态+动态）中按 ID 查找
  MapNode? findNodeById(String id) => _nodeMap[id];

  // ──────────────────────────────────────────────
  // 数据加载
  // ──────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final nodes = await MapService().loadMap();
      if (mounted) {
        setState(() {
          _nodes = nodes;
          _nodeMapCache = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_lastTransform != null) {
            _controller.value = _lastTransform!;
            _currentScale = _lastScale;
          } else {
            _centerMap(nodes);
          }
        });
      }
    } catch (e) {
      if (kMapDebugMode) debugPrint('[WorldMap] 加载地图数据失败: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  /// 初始将视口聚焦于玩家当前所在地
  void _centerMap(List<MapNode> nodes) {
    // 查找玩家所在地节点
    MapNode? target = _currentLocationNode;
    target ??= nodes.where((n) => n.typeTier == 0).firstOrNull;
    if (target == null || target.coordinates.length < 2) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final viewW = renderBox.size.width;
    final viewH = renderBox.size.height;
    if (viewW <= 0 || viewH <= 0) return;

    const initialScale = 5.0;
    final cx = target.coordinates[0].toDouble();
    final cy = target.coordinates[1].toDouble();
    final tx = -cx * initialScale + viewW / 2;
    final ty = -cy * initialScale + viewH / 2;

    setState(() {
      _currentScale = initialScale;
      _controller.value = Matrix4.identity()
        ..translate(tx, ty)
        ..scale(initialScale);
    });
  }

  void _onTransformChanged() {
    final matrixScale = _controller.value.getMaxScaleOnAxis();
    if ((matrixScale - _currentScale).abs() > 0.01) {
      setState(() => _currentScale = matrixScale);
    }
    if (kMapDebugMode) {
      debugPrint(
        '[MapScale] _currentScale=$_currentScale  matrix=${matrixScale.toStringAsFixed(2)}  display=$_scaleText',
      );
    }
  }

  // ──────────────────────────────────────────────
  // 地图节点点击判定
  // ──────────────────────────────────────────────

  void _handleMapPointerDown(PointerDownEvent event) {
    _mapPointerDownPositions[event.pointer] = event.localPosition;
  }

  void _handleMapPointerUp(PointerUpEvent event) {
    final downPosition = _mapPointerDownPositions.remove(event.pointer);
    if (downPosition == null) return;

    final movedDistance = (event.localPosition - downPosition).distance;

    // 用户明显拖动地图时，不触发地点点击。
    if (movedDistance > _mapTapMoveTolerance) {
      if (kMapDebugMode) {
        debugPrint(
          '[MapHitTest] 判定为拖动地图，moved=${movedDistance.toStringAsFixed(1)}',
        );
      }
      return;
    }

    // 把屏幕上的点击位置转换成 InteractiveViewer 内部地图坐标。
    final scenePoint = _controller.toScene(event.localPosition);
    final hitNode = _hitTestNode(scenePoint);

    if (hitNode == null) {
      if (kMapDebugMode) {
        debugPrint(
          '[MapHitTest] 点击地图空白处 scene=(${scenePoint.dx.toStringAsFixed(1)}, ${scenePoint.dy.toStringAsFixed(1)})',
        );
      }
      return;
    }

    debugPrint(
      '[MapHitTest] 命中地图节点: ${hitNode.id} / ${hitNode.name}, scene=(${scenePoint.dx.toStringAsFixed(1)}, ${scenePoint.dy.toStringAsFixed(1)})',
    );
    _openLocationDetail(hitNode);
  }

  void _handleMapPointerCancel(PointerCancelEvent event) {
    _mapPointerDownPositions.remove(event.pointer);
  }

  /// 根据地图坐标判断点击落在哪个节点按钮上。
  ///
  /// 注意：
  /// 这里不依赖 GestureDetector 的命中结果。
  /// 即使节点 Widget 自己没有收到点击，只要外层地图收到了点击，
  /// 就可以通过坐标反推用户点中了哪个地点。
  MapNode? _hitTestNode(Offset scenePoint) {
    final nodes = _visibleNodes;

    // Stack 后面的节点绘制在上层，所以倒序判断，优先命中视觉上更靠上的节点。
    for (final node in nodes.reversed) {
      if (node.coordinates.length < 2) continue;

      final x = node.coordinates[0].toDouble();
      final y = node.coordinates[1].toDouble();
      final labelOffset = _lastLabelOffsets[node.id] ?? Offset.zero;

      final rect = Rect.fromCenter(
        center: Offset(x + labelOffset.dx, y + labelOffset.dy),
        width: _nodeButtonWidth,
        height: _nodeButtonHeight,
      ).inflate(_nodeHitExtraPadding);

      if (rect.contains(scenePoint)) {
        return node;
      }
    }

    return null;
  }

  void _openLocationDetail(MapNode node) {
    debugPrint('[MapNode] 准备打开地点详情: ${node.id} / ${node.name}');
    final isCurrent = node.id == _player.locationId;
    final canMove = _isAdjacentToCurrentLocation(node);
    LocationDetailDialog.show(
      context,
      node,
      isCurrentLocation: isCurrent,
      canMoveHere: canMove,
      onMoveHere: canMove
          ? () async {
              await _movePlayerToNode(node);
            }
          : null,
    );
  }

  // ──────────────────────────────────────────────
  // 缩放工具栏
  // ──────────────────────────────────────────────

  /// 长按延迟结束后开始连续缩放
  void _startZoomPress(double delta) {
    _cancelZoomTimersOnly();
    _zoomLongPressDelayTimer = Timer(const Duration(milliseconds: 320), () {
      _zoomRepeatTimer = Timer.periodic(
        const Duration(milliseconds: 70),
        (_) => _zoomBy(delta),
      );
    });
  }

  /// 松手时：若正在连续缩放则停止；否则执行单次缩放
  void _endZoomPress(double delta) {
    final wasRepeating = _zoomRepeatTimer?.isActive ?? false;
    _cancelZoomTimersOnly();
    if (!wasRepeating) {
      _zoomBy(delta);
    }
  }

  /// 清理所有缩放 Timer
  void _cancelZoomTimersOnly() {
    _zoomLongPressDelayTimer?.cancel();
    _zoomLongPressDelayTimer = null;
    _zoomRepeatTimer?.cancel();
    _zoomRepeatTimer = null;
  }

  /// 以指定焦点（默认视口中心）为锚点缩放 delta 步长
  void _zoomBy(double delta, {Offset? focalPoint}) {
    final renderBox =
        _mapContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final viewW = renderBox.size.width;
    final viewH = renderBox.size.height;
    if (viewW <= 0 || viewH <= 0) return;

    final matrix = _controller.value;
    final oldScale = matrix.getMaxScaleOnAxis();
    final newScale = (oldScale + delta).clamp(_minScale, _maxScale);
    if (newScale == oldScale) return;

    final tx = matrix.entry(0, 3);
    final ty = matrix.entry(1, 3);

    // 以鼠标位置（或视口中心）为缩放锚点
    final fp = focalPoint ?? Offset(viewW / 2, viewH / 2);
    final canvasX = (fp.dx - tx) / oldScale;
    final canvasY = (fp.dy - ty) / oldScale;

    // 保持锚点画布坐标不变，仅修改缩放倍率
    final newTx = fp.dx - canvasX * newScale;
    final newTy = fp.dy - canvasY * newScale;

    _controller.value = Matrix4.identity()
      ..translate(newTx, newTy)
      ..scale(newScale);
    // _onTransformChanged 会通过 listener 自动触发 setState
  }

  /// 缩放倍率文本，如 "500%"
  String get _scaleText => '${(_currentScale * 100).round()}%';

  // ──────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.8,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // 标题栏 + 关闭按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '世界地图',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_player.location} · ${_player.country}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    key: const ValueKey('world_map_close_button'),
                    onPressed: () => Navigator.of(context).pop(_player),
                    icon: const Icon(Icons.close, color: _textSecondary),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Expanded(child: _buildMapContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    if (_error != null) {
      return const Center(
        child: Text(
          '地图数据加载失败',
          style: TextStyle(fontSize: 16, color: _textSecondary),
        ),
      );
    }

    if (_nodes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_nodes!.isEmpty) {
      return const Center(
        child: Text(
          '暂无地图数据',
          style: TextStyle(fontSize: 16, color: _textSecondary),
        ),
      );
    }

    final visibleNodes = _visibleNodes;

    return Stack(
      key: _mapContentKey,
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handleMapPointerDown,
          onPointerUp: _handleMapPointerUp,
          onPointerCancel: _handleMapPointerCancel,
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _zoomBy(
                event.scrollDelta.dy > 0 ? -_zoomStep : _zoomStep,
                focalPoint: event.localPosition,
              );
            }
          },
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: _minScale,
            maxScale: _maxScale,
            boundaryMargin: const EdgeInsets.all(300),
            child: RepaintBoundary(
              child: SizedBox(
                width: 1000,
                height: 1000,
                child: CustomPaint(
                  painter: _LinePainter(nodes: visibleNodes),
                  // 连线在底层，节点在上层
                  child: RepaintBoundary(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: _buildNodeWidgets(visibleNodes),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 调试缩放工具栏
        Positioned(top: 8, right: 8, child: _buildZoomToolbar()),
      ],
    );
  }

  /// 构建所有可见节点 Widget（含重叠检测）
  List<Widget> _buildNodeWidgets(List<MapNode> nodes) {
    if (nodes.isEmpty) {
      _lastLabelOffsets = {};
      return [];
    }

    // 收集坐标
    final positions = <String, Offset>{};
    for (final n in nodes) {
      if (n.coordinates.length >= 2) {
        positions[n.id] = Offset(
          n.coordinates[0].toDouble(),
          n.coordinates[1].toDouble(),
        );
      }
    }

    // 重叠检测：距离过近时横向错开标签
    final labelOffsets = <String, Offset>{};
    const double minDist = 50.0;
    final ids = nodes.map((n) => n.id).toList();
    for (int i = 0; i < ids.length; i++) {
      final aPos = positions[ids[i]];
      if (aPos == null) continue;
      for (int j = i + 1; j < ids.length; j++) {
        final bPos = positions[ids[j]];
        if (bPos == null) continue;
        if ((aPos - bPos).distance < minDist) {
          labelOffsets[ids[i]] = const Offset(-24, 0);
          labelOffsets[ids[j]] = const Offset(24, 0);
        }
      }
    }

    _lastLabelOffsets = labelOffsets;

    return nodes.map((n) {
      return _buildNodeWidget(n, labelOffset: labelOffsets[n.id]);
    }).toList();
  }

  Widget _buildNodeWidget(MapNode node, {Offset? labelOffset}) {
    if (node.coordinates.length < 2) return const SizedBox.shrink();

    final x = node.coordinates[0].toDouble();
    final y = node.coordinates[1].toDouble();
    final isCurrent = node.id == _player.locationId;
    final bgColor = isCurrent
        ? const Color(0xFFE8F5E9)
        : (_nodeBgColors[node.type] ?? _card);
    final borderColor = isCurrent
        ? _accent
        : (_nodeBorderColors[node.type] ?? _border);
    final textColor = isCurrent
        ? const Color(0xFF2E7D32)
        : (_nodeTextColors[node.type] ?? const Color(0xFF333333));
    final leftOffset = labelOffset?.dx ?? 0;
    final topOffset = labelOffset?.dy ?? 0;

    if (kMapDebugMode) {
      debugPrint(
        '[MapNode] $x,$y  →  left:${x - _nodeButtonWidth / 2 + leftOffset} top:${y - _nodeButtonHeight / 2 + topOffset}  「${node.name}」(${node.type})',
      );
    }

    return Positioned(
      key: ValueKey('map_node_${node.id}'),
      left: x - _nodeButtonWidth / 2 + leftOffset,
      top: y - _nodeButtonHeight / 2 + topOffset,
      width: _nodeButtonWidth,
      height: _nodeButtonHeight,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: _nodeButtonWidth,
          height: _nodeButtonHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrent)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.location_on,
                      size: 12,
                      color: Color(0xFF7BAE7F),
                    ),
                  ),
                Flexible(
                  child: Text(
                    node.name,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 重置视图到初始缩放与位置
  void _resetZoom() {
    if (_nodes == null) return;
    _centerMap(_nodes!);
  }

  /// 调试缩放工具栏
  Widget _buildZoomToolbar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _zoomButton(
            Icons.remove,
            -_zoomStep,
            key: const ValueKey('map_zoom_out_button'),
          ),
          _zoomTextButton(
            '重置',
            _resetZoom,
            key: const ValueKey('map_reset_button'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _scaleText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          _zoomButton(
            Icons.add,
            _zoomStep,
            key: const ValueKey('map_zoom_in_button'),
          ),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, double delta, {Key? key}) {
    return SizedBox(
      key: key,
      width: 32,
      height: 32,
      child: Listener(
        onPointerDown: (_) => _startZoomPress(delta),
        onPointerUp: (_) => _endZoomPress(delta),
        onPointerCancel: (_) => _cancelZoomTimersOnly(),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 16, color: const Color(0xFF555555)),
        ),
      ),
    );
  }

  Widget _zoomTextButton(String label, VoidCallback onTap, {Key? key}) {
    return SizedBox(
      key: key,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF555555),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 连线绘制器 — 根据国家关系使用不同样式
class _LinePainter extends CustomPainter {
  final List<MapNode> nodes;

  _LinePainter({required this.nodes});

  static const _neutralCountries = ['中立地域'];

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final n in nodes) n.id: n};

    for (final node in nodes) {
      if (node.coordinates.length < 2) continue;
      final from = Offset(
        node.coordinates[0].toDouble(),
        node.coordinates[1].toDouble(),
      );

      for (final targetId in node.connectedNodes) {
        final target = nodeMap[targetId];
        if (target == null || target.coordinates.length < 2) continue;
        final to = Offset(
          target.coordinates[0].toDouble(),
          target.coordinates[1].toDouble(),
        );

        final paint = _linePaintFor(node, target);
        if (paint == null) continue;

        if (paint.style == PaintingStyle.stroke) {
          canvas.drawLine(from, to, paint);
        } else {
          _drawDashedLine(canvas, from, to, paint);
        }
      }
    }
  }

  /// 根据连线两端节点的国家关系决定样式
  Paint? _linePaintFor(MapNode a, MapNode b) {
    // 中立区域连线 → 灰色细线
    if (_neutralCountries.contains(a.country) ||
        _neutralCountries.contains(b.country)) {
      return Paint()
        ..color = const Color(0xFFBBBBBB)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
    }

    // 国家内部连线 → 红色细线
    if (a.country == b.country) {
      return Paint()
        ..color = const Color(0xFFCC3333)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
    }

    // 跨国家连线 → 橙色虚线
    return Paint()
      ..color = const Color(0xFFE67E22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    if (identical(oldDelegate.nodes, nodes)) return false;
    if (oldDelegate.nodes.length != nodes.length) return true;
    for (int i = 0; i < nodes.length; i++) {
      if (oldDelegate.nodes[i].id != nodes[i].id) return true;
    }
    return false;
  }
}
