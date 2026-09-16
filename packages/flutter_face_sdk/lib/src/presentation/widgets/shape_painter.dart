import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_face_sdk/src/core/face_tracker.dart';

class ShapePainter extends CustomPainter {
  final double radius1;
  final double radius2;
  final double circleRadius;
  final FacesTracker tracker;
  ShapePainter({
    required this.radius1,
    required this.radius2,
    required this.tracker,
    required this.circleRadius,
  });

  var overlayPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 500
    ..style = PaintingStyle.stroke;

  var strokePaint = Paint()
    ..color = const Color(0XFFFC2E55)
    ..strokeWidth = 10
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final circlePath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: circleRadius,
      ));

    // final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final overlayPath =
        Path.combine(PathOperation.difference, circlePath, circlePath);
    final overlayPath2 =
        Path.combine(PathOperation.difference, circlePath, circlePath);

    var angle = (pi * 2) / 50;

    Offset center = Offset(size.width / 2, size.height / 2);
    Offset startPoint = Offset(radius1 * cos(radius1), radius1 * sin(radius1));
    Offset startPoint2 = Offset(radius2 * cos(radius2), radius2 * sin(radius2));

    overlayPath.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);
    overlayPath2.moveTo(startPoint2.dx + center.dx, startPoint2.dy + center.dy);

    for (int i = 1; i <= 50; i++) {
      double x = radius1 * cos(radius1 + angle * i) + center.dx;
      double y = radius1 * sin(radius1 + angle * i) + center.dy;
      double x2 = radius2 * cos(radius2 + angle * i) + center.dx;
      double y2 = radius2 * sin(radius2 + angle * i) + center.dy;
      overlayPath.lineTo(x, y);
      overlayPath2.lineTo(x2, y2);
    }
    overlayPath.close();
    overlayPath2.close();
    canvas.drawPath(overlayPath, overlayPaint);
    canvas.drawPath(overlayPath2, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
