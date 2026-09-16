import 'package:flutter/material.dart';
import 'package:flutter_face_sdk/src/presentation/widgets/face_fill_light.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('banking face guide is a centered portrait capsule', () {
    const viewport = Size(390, 560);
    final guide = embeddedFaceGuideRRect(viewport);

    expect(guide.width, lessThanOrEqualTo(viewport.width * 0.82));
    expect(guide.height / guide.width, moreOrLessEquals(1.34));
    expect(guide.tlRadiusX, moreOrLessEquals(guide.width / 2));
    expect(guide.center.dx, moreOrLessEquals(viewport.width / 2));
    expect(guide.center.dy, moreOrLessEquals(viewport.height * 0.52));
    expect(guide.left, greaterThanOrEqualTo(0));
    expect(guide.top, greaterThanOrEqualTo(0));
    expect(guide.right, lessThanOrEqualTo(viewport.width));
    expect(guide.bottom, lessThanOrEqualTo(viewport.height));
  });

  test('initial distance guide preserves shape while scaling down', () {
    const viewport = Size(390, 560);
    final fullGuide = embeddedFaceGuideRRect(viewport);
    final initialGuide = embeddedFaceGuideRRect(viewport, scale: 0.78);

    expect(initialGuide.width / fullGuide.width, moreOrLessEquals(0.78));
    expect(initialGuide.height / fullGuide.height, moreOrLessEquals(0.78));
    expect(initialGuide.center.dx, moreOrLessEquals(fullGuide.center.dx));
    expect(initialGuide.center.dy, moreOrLessEquals(fullGuide.center.dy));
  });
}
