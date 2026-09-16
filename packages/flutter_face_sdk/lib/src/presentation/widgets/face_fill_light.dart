import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Portrait capsule used by the embedded banking verification flow.
///
/// The first step intentionally starts smaller so the user can establish a
/// baseline distance. The proximity step expands the same guide without
/// changing its center or aspect ratio.
RRect embeddedFaceGuideRRect(Size size, {double scale = 1.0}) {
  final baseWidth = math.min(size.width * 0.82, (size.height * 0.82) / 1.34);
  final width = baseWidth * scale;
  final height = width * 1.34;
  final rect = Rect.fromCenter(
    center: Offset(size.width / 2, size.height * 0.52),
    width: width,
    height: height,
  );
  return RRect.fromRectAndRadius(
    rect,
    Radius.circular(width / 2),
  );
}

Rect embeddedFaceGuide(Size size, {double scale = 1.0}) =>
    embeddedFaceGuideRRect(size, scale: scale).outerRect;

class FaceFillLightClipper extends CustomClipper<Path> {
  final double scale;
  const FaceFillLightClipper({this.scale = 1.0});

  @override
  Path getClip(Size size) => Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(embeddedFaceGuideRRect(size, scale: scale)),
      );

  @override
  bool shouldReclip(FaceFillLightClipper oldClipper) =>
      oldClipper.scale != scale;
}

/// Fills the preview outside the capsule with the host surface colour. The
/// light surface also helps illuminate the face on dim devices.
class FaceFillLight extends StatelessWidget {
  final double scale;
  final Color color;

  const FaceFillLight({
    super.key,
    this.scale = 1.0,
    this.color = const Color(0xFFF7F8FC),
  });

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ClipPath(
          clipper: FaceFillLightClipper(scale: scale),
          child: ColoredBox(color: color),
        ),
      );
}
