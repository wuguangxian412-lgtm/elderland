import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/map_node.dart';
import '../models/player.dart';
import '../services/map_service.dart';
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
  static const bool kMapDebugMode = false;

  late Player _player;
  List<MapNode>? _nodes;
  final List<MapNode> _dynamicNodes = [];
  String? _error;
  DateTime? _lastTipTime;

  final TransformationController _controller = TransformationController();
  final Map<int, Offset> _mapPointerDownPositions = {};
  Map<String, Offset> _lastLabelOffsets = {};

  static const double _mapCanvasSize = 1600.0;
  static const double _mapCanvasPadding = 300.0;
  static const double _mapBoundaryMargin = 1200.0;
  static const double _nodeButtonWidth = 112.0;
  static const double _nodeButtonHeight = 40.0;
  static const double _nodeHitExtraPadding = 6.0;
  static const double _mapTapMoveTolerance = 10.0;

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF333333);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _accent = Color(0xFF7BAE7F);

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

  Map<String, MapNode>? _nodeMapCache;

  List<MapNode> get _allNodes => [...?_nodes, ..._dynamicNodes];

  Map<String, MapNode> get _nodeMap {
    _nodeMapCache ??= {for (final n in _allNodes) n.id: n};
    return _nodeMapCache!;
  }

  MapNode? get _currentLocationNode => _nodeMap[_player.locationId];

  Set<String> _buildVisitedLocationIds(Player player) {
    final visited = <String>{};
    final current = player.locationId.trim();
    if (current.isNotEmpty) visited.add(current);

    for (final event in player.eventRecords) {
      final eventLocationId = event.locationId.trim();
      if (eventLocationId.isNotEmpty) visited.add(eventLocationId);

      final from = event.metadata['fromLocationId'];
      if (from is String && from.trim().isNotEmpty) {
        visited.add(from.trim());
      }

      final to = event.metadata['toLocationId'];
      if (to is String && to.trim().isNotEmpty) {
        visited.add(to.trim());
      }
    }

    return visited;
  }

  Set<String> _buildVisibleLocationIds({
    required Player player,
    required List<MapNode> allNodes,
  }) {
    final nodeById = {for (final node in allNodes) node.id: node};
    final visited = _buildVisitedLocationIds(player);
    final visible = <String>{...visited};

    for (final id in visited) {
      final node = nodeById[id];
      if (node == null) continue;
      visible.addAll(node.connectedNodes);
    }

    return visible;
  }

  List<MapNode> get _visibleNodes {
    final allNodes = _allNodes;
    final visibleIds = _buildVisibleLocationIds(
      player: _player,
      allNodes: allNodes,
    );
    final visibleNodes = allNodes
        .where((node) => visibleIds.contains(node.id))
        .toList(growable: false);

    if (kMapDebugMode) {
      debugPrint('[Map] visible node count: ${visibleNodes.length}');
    }

    return visibleNodes;
  }

  bool _isAdjacentToCurrentLocation(MapNode targetNode) {
    final currentNode = _currentLocationNode;
    if (currentNode == null) return false;
    if (targetNode.id == currentNode.id) return false;
    return currentNode.connectedNodes.contains(targetNode.id) ||
        targetNode.connectedNodes.contains(currentNode.id);
  }

  void _showTip(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final now = DateTime.now();
    if (_lastTipTime != null &&
        now.difference(_lastTipTime!).inMilliseconds < 1000) {
      return;
    }
    _lastTipTime = now;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  /// 执行移动到目标地点。
  ///
  /// 注意：这里不直接保存 player_save。
  /// 地图关闭返回主界面后，由 GameMainPage 统一写入移动经历并保存，
  /// 避免出现“地点已经保存，但移动经历还没写入”的中间状态。
  Future<void> _movePlayerToNode(MapNode targetNode) async {
    debugPrint('[MapMove] 准备移动: ${_player.locationId} -> ${targetNode.id}');

    final movedPlayer = _player.copyWith(
      locationId: targetNode.id,
      location: targetNode.name,
      country: targetNode.country,
    );
    final advancedPlayer = TimeService.advanceOneDay(movedPlayer);

    if (!mounted) return;
    setState(() => _player = advancedPlayer);

    debugPrint(
      '[MapMove] 移动完成但暂不保存，等待主界面写入移动经历: '
      'locationId=${advancedPlayer.locationId}, location=${advancedPlayer.location}',
    );
    _showTip('已移动到：${targetNode.name}');
  }

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    debugPrint('[WorldMap] 打开地图 locationId=${_player.locationId}');
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final nodes = await MapService().loadMap();
      if (!mounted) return;
      setState(() {
        _nodes = nodes;
        _nodeMapCache = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerMap());
    } catch (e) {
      if (kMapDebugMode) debugPrint('[WorldMap] 加载地图数据失败: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _centerMap() {
    final target = _currentLocationNode;
    if (target == null || target.coordinates.length < 2) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final viewW = renderBox.size.width;
    final viewH = renderBox.size.height;
    if (viewW <= 0 || viewH <= 0) return;

    final cx = target.coordinates[0].toDouble() + _mapCanvasPadding;
    final cy = target.coordinates[1].toDouble() + _mapCanvasPadding;

    _controller.value = Matrix4.identity()
      ..translate(-cx + viewW / 2, -cy + viewH / 2);
  }

  void _handleMapPointerDown(PointerDownEvent event) {
    _mapPointerDownPositions[event.pointer] = event.localPosition;
  }

  void _handleMapPointerUp(PointerUpEvent event) {
    final downPosition = _mapPointerDownPositions.remove(event.pointer);
    if (downPosition == null) return;

    final movedDistance = (event.localPosition - downPosition).distance;
    if (movedDistance > _mapTapMoveTolerance) return;

    final scenePoint = _controller.toScene(event.localPosition);
    final hitNode = _hitTestNode(scenePoint);
    if (hitNode == null) return;

    debugPrint('[MapHitTest] 命中地图节点: ${hitNode.id} / ${hitNode.name}');
    _openLocationDetail(hitNode);
  }

  void _handleMapPointerCancel(PointerCancelEvent event) {
    _mapPointerDownPositions.remove(event.pointer);
  }

  MapNode? _hitTestNode(Offset scenePoint) {
    final nodes = _visibleNodes;

    for (final node in nodes.reversed) {
      if (node.coordinates.length < 2) continue;
      final x = node.coordinates[0].toDouble() + _mapCanvasPadding;
      final y = node.coordinates[1].toDouble() + _mapCanvasPadding;
      final labelOffset = _lastLabelOffsets[node.id] ?? Offset.zero;
      final rect = Rect.fromCenter(
        center: Offset(x + labelOffset.dx, y + labelOffset.dy),
        width: _nodeButtonWidth,
        height: _nodeButtonHeight,
      ).inflate(_nodeHitExtraPadding);

      if (rect.contains(scenePoint)) return node;
    }

    return null;
  }

  Future<void> _openLocationDetail(MapNode node) async {
    final isCurrent = node.id == _player.locationId;
    final canMove = _isAdjacentToCurrentLocation(node);
    final entered = await LocationDetailDialog.show(
      context,
      node,
      isCurrentLocation: isCurrent,
      canMoveHere: canMove,
      moveHintText: '前往此地',
      onMoveHere: canMove
          ? () async {
              await _movePlayerToNode(node);
            }
          : null,
    );
    if (entered == true && mounted) {
      Navigator.of(context).pop(_player);
    }
  }

  void addDynamicNode(MapNode node) {
    _nodeMapCache = null;
    setState(() => _dynamicNodes.add(node));
  }

  void addDynamicNodes(List<MapNode> nodes) {
    _nodeMapCache = null;
    setState(() => _dynamicNodes.addAll(nodes));
  }

  void clearDynamicNodes() {
    _nodeMapCache = null;
    setState(() => _dynamicNodes.clear());
  }

  void removeDynamicNode(String id) {
    _nodeMapCache = null;
    setState(() => _dynamicNodes.removeWhere((n) => n.id == id));
  }

  void updateDynamicNode(MapNode node) {
    _nodeMapCache = null;
    setState(() {
      final idx = _dynamicNodes.indexWhere((n) => n.id == node.id);
      if (idx != -1) _dynamicNodes[idx] = node;
    });
  }

  MapNode? findNodeById(String id) => _nodeMap[id];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogSize = math.min(size.width * 0.82, size.height * 0.72);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dialogSize,
        height: dialogSize,
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '世界地图',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_player.location} · ${_player.country}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _handleMapPointerDown,
              onPointerUp: _handleMapPointerUp,
              onPointerCancel: _handleMapPointerCancel,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1.0,
                maxScale: 1.0,
                scaleEnabled: false,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(_mapBoundaryMargin),
                child: RepaintBoundary(
                  child: SizedBox(
                    width: _mapCanvasSize,
                    height: _mapCanvasSize,
                    child: CustomPaint(
                      painter: _LinePainter(
                        nodes: visibleNodes,
                        canvasPadding: _mapCanvasPadding,
                      ),
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
        );
      },
    );
  }

  List<Widget> _buildNodeWidgets(List<MapNode> nodes) {
    if (nodes.isEmpty) {
      _lastLabelOffsets = {};
      return [];
    }

    final positions = <String, Offset>{};
    for (final n in nodes) {
      if (n.coordinates.length >= 2) {
        positions[n.id] = Offset(
          n.coordinates[0].toDouble() + _mapCanvasPadding,
          n.coordinates[1].toDouble() + _mapCanvasPadding,
        );
      }
    }

    final labelOffsets = <String, Offset>{};
    const minDist = 50.0;
    final ids = nodes.map((n) => n.id).toList();
    for (var i = 0; i < ids.length; i++) {
      final aPos = positions[ids[i]];
      if (aPos == null) continue;
      for (var j = i + 1; j < ids.length; j++) {
        final bPos = positions[ids[j]];
        if (bPos == null) continue;
        if ((aPos - bPos).distance < minDist) {
          labelOffsets[ids[i]] = const Offset(-24, 0);
          labelOffsets[ids[j]] = const Offset(24, 0);
        }
      }
    }

    _lastLabelOffsets = labelOffsets;
    return nodes
        .map((n) => _buildNodeWidget(n, labelOffset: labelOffsets[n.id]))
        .toList();
  }

  Widget _buildNodeWidget(MapNode node, {Offset? labelOffset}) {
    if (node.coordinates.length < 2) return const SizedBox.shrink();

    final x = node.coordinates[0].toDouble() + _mapCanvasPadding;
    final y = node.coordinates[1].toDouble() + _mapCanvasPadding;
    final isCurrent = node.id == _player.locationId;
    final canMove = _isAdjacentToCurrentLocation(node);
    final bgColor = isCurrent
        ? const Color(0xFFE8F5E9)
        : (_nodeBgColors[node.type] ?? _card);
    final borderColor = isCurrent
        ? _accent
        : canMove
            ? _accent.withValues(alpha: 0.7)
            : (_nodeBorderColors[node.type] ?? _border);
    final textColor = isCurrent
        ? const Color(0xFF2E7D32)
        : (_nodeTextColors[node.type] ?? _text);
    final leftOffset = labelOffset?.dx ?? 0;
    final topOffset = labelOffset?.dy ?? 0;

    return Positioned(
      key: ValueKey('map_location_${node.id}'),
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
            border: Border.all(
              color: borderColor,
              width: isCurrent || canMove ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isCurrent ? 0.10 : 0.05),
                blurRadius: isCurrent ? 8 : 4,
                offset: const Offset(0, 1),
              ),
            ],
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
                      color: _accent,
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
}

/// 连线绘制器 — 只接收可见节点，因此不会通过线条暴露未知地图。
class _LinePainter extends CustomPainter {
  final List<MapNode> nodes;
  final double canvasPadding;

  _LinePainter({required this.nodes, required this.canvasPadding});

  static const _neutralCountries = ['中立地域'];

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final n in nodes) n.id: n};
    final drawnPairs = <String>{};

    for (final node in nodes) {
      if (node.coordinates.length < 2) continue;
      final from = Offset(
        node.coordinates[0].toDouble() + canvasPadding,
        node.coordinates[1].toDouble() + canvasPadding,
      );

      for (final targetId in node.connectedNodes) {
        final target = nodeMap[targetId];
        if (target == null || target.coordinates.length < 2) continue;

        final pairKey = node.id.compareTo(target.id) < 0
            ? '${node.id}::$targetId'
            : '$targetId::${node.id}';
        if (!drawnPairs.add(pairKey)) continue;

        final to = Offset(
          target.coordinates[0].toDouble() + canvasPadding,
          target.coordinates[1].toDouble() + canvasPadding,
        );
        final paint = _linePaintFor(node, target);
        if (paint == null) continue;
        canvas.drawLine(from, to, paint);
      }
    }
  }

  Paint? _linePaintFor(MapNode a, MapNode b) {
    if (_neutralCountries.contains(a.country) ||
        _neutralCountries.contains(b.country)) {
      return Paint()
        ..color = const Color(0xFFBBBBBB)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
    }

    if (a.country == b.country) {
      return Paint()
        ..color = const Color(0xFFCC3333)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
    }

    return Paint()
      ..color = const Color(0xFFE67E22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    if (oldDelegate.canvasPadding != canvasPadding) return true;
    if (oldDelegate.nodes.length != nodes.length) return true;
    for (var i = 0; i < nodes.length; i++) {
      if (oldDelegate.nodes[i].id != nodes[i].id) return true;
    }
    return false;
  }
}
