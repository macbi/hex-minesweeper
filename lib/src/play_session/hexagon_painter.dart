import 'package:flutter/material.dart';
import 'dart:math' as math;


class HexagonPainter extends CustomPainter {
  static const int sidesOfHexagon = 6;
  final double radius;
  final Offset center;
  final Color _color;

  HexagonPainter(this.center, this.radius, {Color? color}): _color = color ?? Colors.orange;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = _color;
    Path path = createHexagonPath();
    canvas.drawPath(path, paint);
  }

  Path createHexagonPath() {
    final path = Path();
    var angle = (math.pi * 2) / sidesOfHexagon;
    Offset firstPoint = Offset(radius * math.cos(0.0), radius * math.sin(0.0));
    path.moveTo(firstPoint.dx + center.dx, firstPoint.dy + center.dy);
    for (int i = 1; i <= sidesOfHexagon; i++) {
      double x = radius * math.cos(angle * i) + center.dx;
      double y = radius * math.sin(angle * i) + center.dy;
      path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate){
    return _color != oldDelegate._color;
  }

  @override
  bool hitTest(Offset position) {
    final Path path = createHexagonPath();
    return path.contains(position);
  }
}