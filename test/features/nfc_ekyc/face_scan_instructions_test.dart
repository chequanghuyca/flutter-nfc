import 'package:flutter/material.dart';
import 'package:flutter_face_sdk/flutter_face_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/presentation/luxand_face_verification_screen.dart';

void main() {
  testWidgets('guidance stays above controls while framing feedback changes', (
    tester,
  ) async {
    final challenge = FaceMotionChallenge();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaceScanGuidance(challenge: challenge),
                const FaceScanInstructions(),
              ],
            ),
          ),
        ),
      ),
    );
    final initialSize = tester.getSize(find.byType(FaceScanGuidance));
    final banner = tester.widget<AnimatedContainer>(
      find.byKey(const Key('face-guidance-banner')),
    );
    final bannerDecoration = banner.decoration! as BoxDecoration;
    expect(bannerDecoration.color, const Color(0xFF006A9D));
    expect(bannerDecoration.border, isNotNull);
    expect(bannerDecoration.borderRadius, BorderRadius.circular(16));
    expect(find.text('Đặt khuôn mặt vào trong khung hình'), findsOneWidget);
    expect(find.text('Hướng dẫn'), findsOneWidget);
    expect(find.text('Bước 1/2  ·  Căn chỉnh khuôn mặt'), findsOneWidget);
    expect(find.textContaining('VietinBank'), findsNothing);
    expect(find.textContaining('iPay'), findsNothing);
    const feedback = 'Đưa điện thoại ngang tầm mắt và đặt mặt vào khung hình';
    challenge.interruptObservation(feedback);
    await tester.idle();
    await tester.pump();
    expect(find.text(feedback), findsOneWidget);
    expect(tester.getSize(find.byType(FaceScanGuidance)), initialSize);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('face-verification-help')));
    await tester.pumpAndSettle();
    expect(find.text('Hướng dẫn xác thực'), findsOneWidget);
    expect(
      find.text('Giữ điện thoại ngang tầm mắt và nhìn thẳng vào camera.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    challenge.dispose();
  });
}
