import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/map_node.dart';
import '../models/player.dart';
import '../services/map_service.dart';
import '../services/natural_time_service.dart';
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
  final GlobalKey _mapViewportKey = GlobalKey();
  final Map<int, Offset> _mapPointerDownPositions = {};
  final Map<String, Offset> _lastLabelOffsets = {};

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
    final advancedPlayer = await NaturalTimeService.consumeAction(
      movedPlayer,
      NaturalTimeAction.mapLocationTravel,
      fallbackMinutes: 120,
    );

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
      _scheduleCenterOnCurrentLocation();
    } catch (e) {
      if (kMapDebugMode) debugPrint('[WorldMap] 加载地图数据失败: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _scheduleCenterOnCurrentLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _centerOnCurrentLocation();
      });
    });
  }

  void _centerOnCurrentLocation() {
    final target = _currentLocationNode;
    if (target == null || target.coordinates.length < 2) return;

    final viewportContext = _mapViewportKey.currentContext;
    if (viewportContext == null) return;

    final renderBox = viewportContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final viewW = renderBox.size.width;
    final viewH = renderBox.size.height;
    if (viewW <= 0 || viewH <= 0) return;

    final cx = target.coordinates[0].toDouble() + _mapCanvasPadding;
    final cy = target.coordinates[1].toDouble() + _mapCanvasPadding;

    final tx = -cx + viewW / 2;
    final ty = -cy + viewH / 2;

    _controller.value = Matrix4.identity()..translateByDouble(tx, ty, 0, 1);
  }

  void _handleMapPointerDown(PointerDownEvent event) {
    _mapPointerDownPositions[event.pointer] = event.localPosition;
  }

  void _handleMapPointerUp(PointerUpEvent event) {
    final downPosition = _mapPointerDownPositions.remove(event.pointer);
    if (downPosition == null) return;

    if ((event.localPosition - downPosition).distance > _mapTapMoveTolerance) {
      return;
    }

    final inverseMatrix = Matrix4.inverted(_controller.value);
    final local = MatrixUtils.transformPoint(inverseMatrix, event.localPosition);
    final tappedNode = _hitTestNode(local);
    if (tappedNode != null) {
      _onNodeTap(tappedNode);
    }
  }

  MapNode? _hitTestNode(Offset local) {
    final nodes = _visibleNodes;
    for (final node in nodes.reversed) {
      final nodeRect = Rect.fromLTWH(
        node.coordinates[0].toDouble() +
            _mapCanvasPadding -
            _nodeButtonWidth / 2,
        node.coordinates[1].toDouble() +
            _mapCanvasPadding -
            _nodeButtonHeight / 2,
        _nodeButtonWidth,
        _nodeButtonHeight,
      ).inflate(_nodeHitExtraPadding);

      if (nodeRect.contains(local)) return node;
    }
    return null;
  }

  void _onNodeTap(MapNode node) {
    if (node.id == _player.locationId) {
      LocationDetailDialog.show(context, node, isCurrentLocation: true);
      return;
    }

    if (!_isAdjacentToCurrentLocation(node)) {
      final currentNode = _currentLocationNode;
      final currentName = currentNode?.name ?? _player.location;
      _showTip('只能从$currentName前往相邻地点');
      return;
    }

    LocationDetailDialog.show(
      context,
      node,
      isCurrentLocation: false,
      canMoveHere: true,
      onMoveHere: () async {
        await _movePlayerToNode(node);
      },
      moveHintText: '前往${node.name}',
    );
  }

  Offset _offsetForLabel({
    required Rect buttonRect,
    required MapNode node,
    required Map<String, Rect> occupiedRects,
  }) {
    final candidates = [
      const Offset(0, -54),
      const Offset(0, 54),
      const Offset(-124, 0),
      const Offset(124, 0),
      const Offset(-94, -44),
      const Offset(94, -44),
      const Offset(-94, 44),
      const Offset(94, 44),
    ];

    Offset best = candidates.first;
    var bestScore = double.negativeInfinity;

    for (final candidate in candidates) {
      final labelRect = _labelRectFor(buttonRect, candidate);
      final insideCanvas = _canvasRect.contains(labelRect.topLeft) &&
          _canvasRect.contains(labelRect.bottomRight);
      final overlaps = occupiedRects.values.any((r) => r.overlaps(labelRect));
      final distanceFromNode = (candidate.distance).clamp(1.0, 999.0);
      final score =
          (insideCanvas ? 1000.0 : -1000.0) -
          (overlaps ? 600.0 : 0.0) -
          distanceFromNode;

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    final last = _lastLabelOffsets[node.id];
    if (last != null) {
      final lastRect = _labelRectFor(buttonRect, last);
      final stillOk = _canvasRect.contains(lastRect.topLeft) &&
          _canvasRect.contains(lastRect.bottomRight) &&
          !occupiedRects.values.any((r) => r.overlaps(lastRect));
      if (stillOk) return last;
    }

    _lastLabelOffsets[node.id] = best;
    return best;
  }

  Rect get _canvasRect => Rect.fromLTWH(0, 0, _mapCanvasSize, _mapCanvasSize);

  Rect _labelRectFor(Rect buttonRect, Offset offset) {
    const labelW = 180.0;
    const labelH = 42.0;
    final center = buttonRect.center + offset;
    return Rect.fromCenter(center: center, width: labelW, height: labelH);
  }

  Widget _buildNodeButton(MapNode node) {
    final isCurrent = node.id == _player.locationId;
    final canMove = !isCurrent && _isAdjacentToCurrentLocation(node);
    final bg = isCurrent
        ? _accent
        : _nodeBgColors[node.type] ?? const Color(0xFFF3F4F6);
    final border = isCurrent
        ? _accent
        : (canMove
              ? _accent
              : _nodeBorderColors[node.type] ?? const Color(0xFFD1D5DB));
    final textColor = isCurrent
        ? Colors.white
        : _nodeTextColors[node.type] ?? _text;

    return SizedBox(
      width: _nodeButtonWidth,
      height: _nodeButtonHeight,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: isCurrent ? 2 : 1.2),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            node.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeLabel(MapNode node, Offset offset) {
    return SizedBox(
      width: 180,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                node.type,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                canMoveLabel(node),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _nodeTextColors[node.type] ?? _text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String canMoveLabel(MapNode node) {
    if (node.id == _player.locationId) return '当前位置';
    if (_isAdjacentToCurrentLocation(node)) return '可前往';
    return '未连通';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogW = math.min(size.width * 0.92, 700.0);
    final dialogH = math.min(size.height * 0.78, 760.0);

    return Dialog(
      backgroundColor: _card,
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: dialogW,
        height: dialogH,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '世界地图',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_player),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Expanded(
              child: _error != null
                  ? Center(child: Text(_error!))
                  : _nodes == null
                      ? const Center(child: CircularProgressIndicator())
                      : Listener(
                          onPointerDown: _handleMapPointerDown,
                          onPointerUp: _handleMapPointerUp,
                          child: InteractiveViewer(
                            key: _mapViewportKey,
                            transformationController: _controller,
                            boundaryMargin: const EdgeInsets.all(
                              _mapBoundaryMargin,
                            ),
                            minScale: 0.3,
                            maxScale: 1.5,
                            constrained: false,
                            child: SizedBox(
                              width: _mapCanvasSize,
                              height: _mapCanvasSize,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _MapConnectionPainter(
                                        nodes: _visibleNodes,
                                        allNodes: _allNodes,
                                        padding: _mapCanvasPadding,
                                        currentLocationId: _player.locationId,
                                      ),
                                    ),
                                  ),
                                  ..._visibleNodes.map((node) {
                                    final left =
                                        node.coordinates[0].toDouble() +
                                        _mapCanvasPadding -
                                        _nodeButtonWidth / 2;
                                    final top =
                                        node.coordinates[1].toDouble() +
                                        _mapCanvasPadding -
                                        _nodeButtonHeight / 2;
                                    return Positioned(
                                      left: left,
                                      top: top,
                                      child: _buildNodeButton(node),
                                    );
                                  }),
                                  ..._buildLabels(),
                                ],
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

  List<Widget> _buildLabels() {
    final occupied = <String, Rect>{};
    final widgets = <Widget>[];
    for (final node in _visibleNodes) {
      final left =
          node.coordinates[0].toDouble() + _mapCanvasPadding - _nodeButtonWidth / 2;
      final top =
          node.coordinates[1].toDouble() + _mapCanvasPadding - _nodeButtonHeight / 2;
      final buttonRect = Rect.fromLTWH(
        left,
        top,
        _nodeButtonWidth,
        _nodeButtonHeight,
      );
      final offset = _offsetForLabel(
        buttonRect: buttonRect,
        node: node,
        occupiedRects: occupied,
      );
      final rect = _labelRectFor(buttonRect, offset);
      occupied[node.id] = rect;
      widgets.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          child: _buildNodeLabel(node, offset),
        ),
      );
    }
    return widgets;
  }
}

class _MapConnectionPainter extends CustomPainter {
  final List<MapNode> nodes;
  final List<MapNode> allNodes;
  final double padding;
  final String currentLocationId;

  const _MapConnectionPainter({
    required this.nodes,
    required this.allNodes,
    required this.padding,
    required this.currentLocationId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleMap = {for (final n in nodes) n.id: n};
    final allMap = {for (final n in allNodes) n.id: n};
    final drawn = <String>{};
    final paint = Paint()
      ..color = const Color(0xFFD7D3CE)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (final node in nodes) {
      for (final targetId in node.connectedNodes) {
        final target = visibleMap[targetId];
        if (target == null) {
          continue;
        }
        final key = [node.id, targetId]..sort();
        final lineKey = key.join('_');
        if (drawn.contains(lineKey)) continue;
        drawn.add(lineKey);

        final p1 = Offset(
          node.coordinates[0].toDouble() + padding,
          node.coordinates[1].toDouble() + padding,
        );
        final p2 = Offset(
          target.coordinates[0].toDouble() + padding,
          target.coordinates[1].toDouble() + padding,
        );
        canvas.drawLine(p1, p2, paint);
      }
    }

    final current = allMap[currentLocationId];
    if (current == null) return;
    final currentVisible = visibleMap[currentLocationId] != null;
    if (!currentVisible) return;

    final highlightPaint = Paint()
      ..color = const Color(0xFF7BAE7F).withValues(alpha: 0.45)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (final targetId in current.connectedNodes) {
      final target = visibleMap[targetId];
      if (target == null) continue;
      final p1 = Offset(
        current.coordinates[0].toDouble() + padding,
        current.coordinates[1].toDouble() + padding,
      );
      final p2 = Offset(
        target.coordinates[0].toDouble() + padding,
        target.coordinates[1].toDouble() + padding,
      );
      canvas.drawLine(p1, p2, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapConnectionPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.allNodes != allNodes ||
        oldDelegate.padding != padding ||
        oldDelegate.currentLocationId != currentLocationId;
  }
}
