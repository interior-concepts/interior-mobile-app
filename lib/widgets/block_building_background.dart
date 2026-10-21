import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A 60fps animated 3D Architectural CAD Wireframe Blueprint background on Studio White.
/// All animated elements (floor grid, walls, glass partitions, executive desks, conference table, chairs, planters)
/// are rendered as pure 3D Isometric Wireframe vector lines with NO solid fills.
class BlockBuildingBackground extends StatefulWidget {
  const BlockBuildingBackground({
    super.key,
    this.child,
  });

  final Widget? child;

  @override
  State<BlockBuildingBackground> createState() => _BlockBuildingBackgroundState();
}

class _BlockBuildingBackgroundState extends State<BlockBuildingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Clean Studio White base background
        Positioned.fill(
          child: Container(
            color: const Color(0xFFFAFAFA),
          ),
        ),

        // Animated 3D Architectural Wireframe Construction Canvas
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ArchitecturalWireframePainter(progress: _controller.value),
              );
            },
          ),
        ),

        // Subtle Studio Radial Gradient Overlay for crisp text contrast & legibility
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, 0.25),
                radius: 1.2,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.60),
                  const Color(0xFFF1F5F9).withValues(alpha: 0.90),
                ],
                stops: const [0.0, 0.60, 1.0],
              ),
            ),
          ),
        ),

        // Foreground Content (Form, Title, Text)
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _ArchitecturalWireframePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 animation loop

  _ArchitecturalWireframePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.56);
    const tileW = 54.0;
    const tileH = 30.0;

    // --- PHASE 1: Wireframe Floor Grid & Tiles (0.0 -> 0.25) ---
    final floorProgress = (progress / 0.25).clamp(0.0, 1.0);
    _drawWireframeBlueprintGrid(canvas, center, tileW, tileH, floorProgress);
    _drawWireframeFloorTiles(canvas, center, tileW, tileH, floorProgress);

    // --- PHASE 2: Wireframe Walls & Glass Dividers (0.18 -> 0.55) ---
    final wallProgress = ((progress - 0.18) / 0.35).clamp(0.0, 1.0);
    if (wallProgress > 0) {
      _drawWireframeWalls(canvas, center, tileW, tileH, wallProgress);
      _drawWireframeGlassPartitions(canvas, center, tileW, tileH, wallProgress);
    }

    // --- PHASE 3: Wireframe Furniture & Interior Objects (0.45 -> 0.82) ---
    final furnitureProgress = ((progress - 0.45) / 0.37).clamp(0.0, 1.0);
    if (furnitureProgress > 0) {
      _drawWireframeExecutiveDesks(canvas, center, tileW, tileH, furnitureProgress);
      _drawWireframeConferenceTable(canvas, center, tileW, tileH, furnitureProgress);
      _drawWireframeChairs(canvas, center, tileW, tileH, furnitureProgress);
      _drawWireframePlanters(canvas, center, tileW, tileH, furnitureProgress);
    }

    // --- PHASE 4: Wireframe Lighting & Beam Lines (0.75 -> 1.0) ---
    final lightProgress = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);
    if (lightProgress > 0) {
      _drawWireframeLighting(canvas, center, tileW, tileH, lightProgress);
    }

    // Floating Vector Wireframe Node Particles
    _drawWireframeParticles(canvas, center, size, progress);
  }

  // 1. Isometric Wireframe Blueprint Grid
  void _drawWireframeBlueprintGrid(Canvas canvas, Offset center, double tileW, double tileH, double p) {
    if (p <= 0) return;

    final gridPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.22 * p)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.45 * p)
      ..style = PaintingStyle.fill;

    const radius = 5;
    for (int x = -radius; x <= radius; x++) {
      for (int y = -radius; y <= radius; y++) {
        final isoX = (x - y) * (tileW * 0.5);
        final isoY = (x + y) * (tileH * 0.5) + 40.0;
        final point = Offset(center.dx + isoX, center.dy + isoY);

        canvas.drawCircle(point, 1.8, dotPaint);

        if (x < radius) {
          final nextIsoX = ((x + 1) - y) * (tileW * 0.5);
          final nextIsoY = ((x + 1) + y) * (tileH * 0.5) + 40.0;
          canvas.drawLine(point, Offset(center.dx + nextIsoX, center.dy + nextIsoY), gridPaint);
        }
        if (y < radius) {
          final nextIsoX = (x - (y + 1)) * (tileW * 0.5);
          final nextIsoY = (x + (y + 1)) * (tileH * 0.5) + 40.0;
          canvas.drawLine(point, Offset(center.dx + nextIsoX, center.dy + nextIsoY), gridPaint);
        }
      }
    }
  }

  // Wireframe Floor Tile Outlines
  void _drawWireframeFloorTiles(Canvas canvas, Offset center, double tileW, double tileH, double p) {
    if (p <= 0) return;

    const tileCoords = [
      [-2, -2], [-1, -2], [0, -2], [1, -2], [2, -2],
      [-2, -1], [-1, -1], [0, -1], [1, -1], [2, -1],
      [-2, 0],  [-1, 0],  [0, 0],  [1, 0],  [2, 0],
      [-2, 1],  [-1, 1],  [0, 1],  [1, 1],  [2, 1],
      [-2, 2],  [-1, 2],  [0, 2],  [1, 2],  [2, 2],
    ];

    for (int i = 0; i < tileCoords.length; i++) {
      final x = tileCoords[i][0];
      final y = tileCoords[i][1];

      final tileDelay = i / tileCoords.length * 0.5;
      final tileP = ((p - tileDelay) / 0.5).clamp(0.0, 1.0);
      if (tileP <= 0) continue;

      final isoX = (x - y) * (tileW * 0.5);
      final isoY = (x + y) * (tileH * 0.5) + 40.0;
      final pos = Offset(center.dx + isoX, center.dy + isoY);

      final isEven = (x + y) % 2 == 0;
      final wireframeColor = isEven
          ? const Color(0xFF2563EB).withValues(alpha: 0.5 * tileP)
          : const Color(0xFF64748B).withValues(alpha: 0.5 * tileP);

      final borderPaint = Paint()
        ..color = wireframeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final halfW = tileW * 0.5 * tileP;
      final halfH = tileH * 0.5 * tileP;

      final path = Path()
        ..moveTo(pos.dx, pos.dy - halfH)
        ..lineTo(pos.dx + halfW, pos.dy)
        ..lineTo(pos.dx, pos.dy + halfH)
        ..lineTo(pos.dx - halfW, pos.dy)
        ..close();

      canvas.drawPath(path, borderPaint);
    }
  }

  // 2. Wireframe Walls & Structural Columns
  void _drawWireframeWalls(Canvas canvas, Offset center, double tileW, double tileH, double p) {
    // Back Left Wireframe Wall
    _draw3DWireframeWall(
      canvas: canvas,
      center: center,
      tileW: tileW,
      tileH: tileH,
      startX: -3, startY: -3,
      endX: 3, endY: -3,
      wallHeight: 120.0,
      progress: p,
      wireframeColor: const Color(0xFF1E293B),
    );

    // Back Right Wireframe Wall
    _draw3DWireframeWall(
      canvas: canvas,
      center: center,
      tileW: tileW,
      tileH: tileH,
      startX: -3, startY: -3,
      endX: -3, endY: 3,
      wallHeight: 120.0,
      progress: p,
      wireframeColor: const Color(0xFF2563EB),
    );
  }

  // Wireframe Glass Partitions (Vector Stroke Line Art)
  void _drawWireframeGlassPartitions(Canvas canvas, Offset center, double tileW, double tileH, double p) {
    final glassP = _easeOutCubic(p);
    final glassHeight = 70.0 * glassP;

    final isoX = (0 - 0) * (tileW * 0.5);
    final isoY = (0 + 0) * (tileH * 0.5) + 40.0;
    final pos = Offset(center.dx + isoX, center.dy + isoY);

    final glassWireframePaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.85 * glassP)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final glassPath = Path()
      ..moveTo(pos.dx - tileW, pos.dy)
      ..lineTo(pos.dx, pos.dy + tileH * 0.5)
      ..lineTo(pos.dx, pos.dy + tileH * 0.5 - glassHeight)
      ..lineTo(pos.dx - tileW, pos.dy - glassHeight)
      ..close();

    canvas.drawPath(glassPath, glassWireframePaint);

    // Wireframe Diagonal Glass Grid / Sheen lines
    final innerGridPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.45 * glassP)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(pos.dx - tileW * 0.7, pos.dy - glassHeight * 0.1),
      Offset(pos.dx - tileW * 0.1, pos.dy - glassHeight * 0.8),
      innerGridPaint,
    );
    canvas.drawLine(
      Offset(pos.dx - tileW * 0.9, pos.dy - glassHeight * 0.3),
      Offset(pos.dx - tileW * 0.3, pos.dy - glassHeight * 0.95),
      innerGridPaint,
    );
  }

  // 3. Wireframe Executive Desks
  void _drawWireframeExecutiveDesks(Canvas canvas, Offset center, double tileW, double tileH, double p) {
    final deskP = _easeOutBack(((p - 0.1) / 0.8).clamp(0.0, 1.0));
    if (deskP <= 0) return;

    // Main Executive Desk Wireframe
    _draw3DWireframeCube(
      canvas: canvas,
      center: center,
      gridX: 1, gridY: -1,
      tileW: tileW * 1.2,
      tileH: tileH * 1.2,
      height: 24.0 * deskP,
      dropOffset: (1.0 - deskP) * -120.0,
      wireframeColor: const Color(0xFF0284C7),
      strokeWidth: 1.4,
    );

    // Workstation Desk Wireframe
    _draw3DWireframeCube(
      canvas: canvas,
      center: center,
      gridX: -1, gridY: 1,
      tileW: tileW * 1.1,
      tileH: tileH * 1.1,
      height: 22.0 * deskP,
      dropOffset: (1.0 - deskP) * -140.0,
      wireframeColor: const Color(0xFF4F46E5),
      strokeWidth: 1.3,
    );
  }

  // Wireframe Conference Table
  void _drawWireframeConferenceTable(Canvas canvas, Offset center, double tileW, double tileH, double p) {
    final confP = _easeOutBack(((p - 0.3) / 0.7).clamp(0.0, 1.0));
    if (confP <= 0) return;

    _draw3DWireframeCube(
      canvas: canvas,
      center: center,
      gridX: 0, gridY: 1,
      tileW: tileW * 1.4,
      tileH: tileH * 0.9,
      height: 20.0 * confP,
      dropOffset: (1.0 - confP) * -150.0,
      wireframeColor: const Color(0xFF6366F1),
      strokeWidth: 1.5,
    );
  }

  // Wireframe Office Chairs
  void _drawWireframeChairs(Canvas canvas, Offset center, double tileW, double tileH, double p) {
    final chairP = _easeOutCubic(((p - 0.4) / 0.6).clamp(0.0, 1.0));
    if (chairP <= 0) return;

    final chairPositions = [
      [1.4, -0.6], [-0.6, 1.4], [0.0, 1.6], [0.0, 0.4]
    ];

    for (final pos in chairPositions) {
      _draw3DWireframeCube(
        canvas: canvas,
        center: center,
        gridX: pos[0], gridY: pos[1],
        tileW: tileW * 0.4,
        tileH: tileH * 0.4,
        height: 32.0 * chairP,
        dropOffset: (1.0 - chairP) * -90.0,
        wireframeColor: const Color(0xFF2563EB),
        strokeWidth: 1.2,
      );
    }
  }

  // Wireframe Planter Box
  void _drawWireframePlanters(Canvas canvas, Offset center, double tileW, double tileH, double p) {
    final decorP = _easeOutCubic(((p - 0.5) / 0.5).clamp(0.0, 1.0));
    if (decorP <= 0) return;

    _draw3DWireframeCube(
      canvas: canvas,
      center: center,
      gridX: -2, gridY: -2,
      tileW: tileW * 0.6,
      tileH: tileH * 0.6,
      height: 40.0 * decorP,
      dropOffset: (1.0 - decorP) * -100.0,
      wireframeColor: const Color(0xFF059669),
      strokeWidth: 1.4,
    );
  }

  // 4. Wireframe Lighting & Track Vector Lines
  void _drawWireframeLighting(Canvas canvas, Offset center, double tileW, double tileH, double p) {
    final lightP = _easeOutCubic(p);
    final glowAlpha = (math.sin(lightP * math.pi) * 0.4 + 0.6).clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.85 * glowAlpha)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final rayPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35 * glowAlpha)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Light Beam Outline Wireframe (No Fill)
    final lightBeamPath = Path()
      ..moveTo(center.dx - 60, center.dy - 140)
      ..lineTo(center.dx + 60, center.dy - 140)
      ..lineTo(center.dx + 160, center.dy + 80)
      ..lineTo(center.dx - 160, center.dy + 80)
      ..close();

    canvas.drawPath(lightBeamPath, rayPaint);

    // Track Bar
    canvas.drawLine(
      Offset(center.dx - 100, center.dy - 140),
      Offset(center.dx + 100, center.dy - 140),
      trackPaint,
    );
  }

  // Helper: Draw 3D Isometric Wireframe Wall Panel (No Fills)
  void _draw3DWireframeWall({
    required Canvas canvas,
    required Offset center,
    required double tileW,
    required double tileH,
    required double startX, required double startY,
    required double endX, required double endY,
    required double wallHeight,
    required double progress,
    required Color wireframeColor,
  }) {
    final wallP = _easeOutCubic(progress);
    final h = wallHeight * wallP;

    final p1IsoX = (startX - startY) * (tileW * 0.5);
    final p1IsoY = (startX + startY) * (tileH * 0.5) + 40.0;
    final p1 = Offset(center.dx + p1IsoX, center.dy + p1IsoY);

    final p2IsoX = (endX - endY) * (tileW * 0.5);
    final p2IsoY = (endX + endY) * (tileH * 0.5) + 40.0;
    final p2 = Offset(center.dx + p2IsoX, center.dy + p2IsoY);

    final wallOutlinePath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p2.dx, p2.dy - h)
      ..lineTo(p1.dx, p1.dy - h)
      ..close();

    final wireframePaint = Paint()
      ..color = wireframeColor.withValues(alpha: 0.85 * wallP)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    canvas.drawPath(wallOutlinePath, wireframePaint);

    // Wall Internal Grid Line Wireframe (Architectural Stud Lines)
    const gridCount = 4;
    final gridLinePaint = Paint()
      ..color = wireframeColor.withValues(alpha: 0.35 * wallP)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 1; i < gridCount; i++) {
      final ratio = i / gridCount;
      final x = p1.dx + (p2.dx - p1.dx) * ratio;
      final y = p1.dy + (p2.dy - p1.dy) * ratio;
      canvas.drawLine(Offset(x, y), Offset(x, y - h), gridLinePaint);
    }
  }

  // Helper: Draw 3D Isometric Wireframe Cube (Strictly Vector Line Art / No Fills)
  void _draw3DWireframeCube({
    required Canvas canvas,
    required Offset center,
    required double gridX, required double gridY,
    required double tileW, required double tileH,
    required double height,
    required double dropOffset,
    required Color wireframeColor,
    double strokeWidth = 1.2,
  }) {
    final isoX = (gridX - gridY) * (tileW * 0.5);
    final isoY = (gridX + gridY) * (tileH * 0.5) + 40.0 + dropOffset;
    final pos = Offset(center.dx + isoX, center.dy + isoY);

    final halfW = tileW * 0.5;
    final halfH = tileH * 0.5;

    final wireframePaint = Paint()
      ..color = wireframeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final nodePaint = Paint()
      ..color = wireframeColor
      ..style = PaintingStyle.fill;

    // Top Face Wireframe Polygon
    final topPath = Path()
      ..moveTo(pos.dx, pos.dy - height)
      ..lineTo(pos.dx + halfW, pos.dy - height + halfH)
      ..lineTo(pos.dx, pos.dy - height + tileH)
      ..lineTo(pos.dx - halfW, pos.dy - height + halfH)
      ..close();
    canvas.drawPath(topPath, wireframePaint);

    // Vertical Corner Wireframe Edges
    canvas.drawLine(
      Offset(pos.dx - halfW, pos.dy - height + halfH),
      Offset(pos.dx - halfW, pos.dy + halfH),
      wireframePaint,
    );
    canvas.drawLine(
      Offset(pos.dx, pos.dy - height + tileH),
      Offset(pos.dx, pos.dy + tileH),
      wireframePaint,
    );
    canvas.drawLine(
      Offset(pos.dx + halfW, pos.dy - height + halfH),
      Offset(pos.dx + halfW, pos.dy + halfH),
      wireframePaint,
    );

    // Bottom Face Base Wireframe Edges
    final bottomBasePath = Path()
      ..moveTo(pos.dx - halfW, pos.dy + halfH)
      ..lineTo(pos.dx, pos.dy + tileH)
      ..lineTo(pos.dx + halfW, pos.dy + halfH);
    canvas.drawPath(bottomBasePath, wireframePaint);

    // Draw Wireframe Node Dots at Key Vertices for CAD feel
    canvas.drawCircle(Offset(pos.dx, pos.dy - height), 1.5, nodePaint);
    canvas.drawCircle(Offset(pos.dx + halfW, pos.dy - height + halfH), 1.5, nodePaint);
    canvas.drawCircle(Offset(pos.dx - halfW, pos.dy - height + halfH), 1.5, nodePaint);
    canvas.drawCircle(Offset(pos.dx, pos.dy - height + tileH), 1.5, nodePaint);
  }

  // Floating Wireframe Node Particles
  void _drawWireframeParticles(Canvas canvas, Offset center, Size size, double p) {
    final random = math.Random(1337);
    const count = 26;

    for (int i = 0; i < count; i++) {
      final speed = 0.2 + (random.nextDouble() * 0.3);
      final offsetSeed = i * 23.0;
      final partProgress = (p * speed + offsetSeed) % 1.0;

      final posX = (random.nextDouble() * size.width);
      final posY = size.height - (partProgress * size.height);
      final alpha = (math.sin(partProgress * math.pi) * 0.5).clamp(0.0, 0.6);

      final nodeRingPaint = Paint()
        ..color = (i % 2 == 0 ? const Color(0xFF0284C7) : const Color(0xFF6366F1)).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(Offset(posX, posY), 2.0 + (i % 3), nodeRingPaint);
    }
  }

  double _easeOutCubic(double x) {
    return 1.0 - math.pow(1.0 - x, 3).toDouble();
  }

  double _easeOutBack(double x) {
    const c1 = 1.70158;
    const c3 = c1 + 1.0;
    return 1.0 + c3 * math.pow(x - 1.0, 3) + c1 * math.pow(x - 1.0, 2);
  }

  @override
  bool shouldRepaint(covariant _ArchitecturalWireframePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
