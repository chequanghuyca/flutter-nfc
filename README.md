<!-- generated-by: gsd-doc-writer -->

# NFC eKYC Demo

Ứng dụng Flutter mẫu đọc chip CCCD Việt Nam và xác thực khuôn mặt hoàn toàn
trên thiết bị, dành cho việc thử nghiệm luồng NFC/eKYC trên Android và iOS.

Ứng dụng không sử dụng backend. Luồng chính gồm chụp hai mặt CCCD, nhận dạng
MRZ, mở chip bằng BAC, đọc dữ liệu ICAO 9303 và so khớp khuôn mặt camera trước
với ảnh chân dung DG2 bằng Luxand FaceSDK 8.3.

## Tính năng

- Chụp mặt trước và mặt sau CCCD bằng camera.
- Nhận dạng ba dòng MRZ bằng Google ML Kit và cho phép kiểm tra lại dữ liệu.
- Đọc chip qua NFC bằng BAC với:
  - `DG1`: dữ liệu MRZ/định danh;
  - `DG2`: ảnh chân dung;
  - `DG13`: dữ liệu bổ sung nếu chip có hỗ trợ;
  - `SOD`: trạng thái đọc file bảo mật.
- Giải mã ảnh DG2 dạng JPEG, PNG hoặc JPEG2000; iOS có native fallback bằng
  ImageIO.
- Quét FaceID hai bước, kiểm tra một khuôn mặt, liveness và độ tương đồng với
  ảnh DG2.
- Hiển thị tiến trình, lỗi NFC và kết quả Match/Liveness bằng tiếng Việt.
- Hỗ trợ Android ARM32/ARM64 và iOS 13 trở lên.

## Luồng hoạt động

```text
Chụp CCCD → OCR MRZ → Xác nhận dữ liệu BAC → Đọc NFC
           → DG1/DG2/DG13/SOD → Giải mã ảnh DG2
           → Quét FaceID → Liveness + Face Match → Kết quả
```

Ba trường dùng để tạo khóa BAC là:

1. Số tài liệu MRZ gồm 9 chữ số ngay sau `IDVNM` — không phải số định danh
   12 chữ số in trên CCCD.
2. Ngày sinh.
3. Ngày hết hạn.

Sau khi đọc chip thành công, ứng dụng tự mở màn xác thực khuôn mặt nếu DG2 có
ảnh hợp lệ. Có thể nhập ba trường BAC thủ công để kiểm thử riêng phần NFC.

## Quét FaceID

FaceID sử dụng camera trước và Luxand FaceSDK 8.3. Giao diện hướng dẫn nằm phía
trên vùng camera để không che khuôn mặt, đồng thời giữ phản hồi căn chỉnh trong
suốt phiên quét. Đây là tên luồng xác thực trong dự án, không sử dụng Apple
Face ID hoặc phần cứng TrueDepth.

Quy trình gồm hai bước:

1. **Căn chỉnh khuôn mặt** — đặt một khuôn mặt vào giữa khung, giữ đầu thẳng và
   điện thoại ngang tầm mắt.
2. **Đưa điện thoại lại gần** — tiến lại gần khung lớn hơn rồi giữ yên để SDK
   hoàn tất kiểm tra người thật và so khớp.

Ứng dụng chỉ chấp nhận kết quả khi:

- camera phát hiện đúng một khuôn mặt;
- khuôn mặt nằm đúng vị trí và khoảng cách yêu cầu;
- mẫu cuối vượt `LUXAND_LIVENESS_THRESHOLD`;
- mẫu cuối khớp ảnh DG2 theo `LUXAND_MATCH_THRESHOLD`;
- toàn bộ motion challenge đã hoàn thành.

Khi thành công, màn hình hiển thị ảnh xác minh cùng điểm Match và Liveness.
Ảnh DG2 và ảnh camera tạm được dọn theo cơ chế best-effort khi đóng màn xác
thực.

## Yêu cầu môi trường

### Chung

- Flutter SDK cung cấp Dart `>=3.11.4 <4.0.0`.
- Git để tải dependency `dmrtd`.
- Thiết bị thật có NFC và camera trước. Simulator/emulator không đọc được NFC.
- Bộ Luxand FaceSDK 8.3 và license hợp lệ cho từng nền tảng.

### Android

- Android 7.0 / API 24 trở lên.
- JDK 17.
- Android NDK `28.2.13676358`.
- Thiết bị ARM (`armeabi-v7a` hoặc `arm64-v8a`); binary Luxand trong dự án
  không hỗ trợ emulator x86/x86_64.

### iOS

- iOS 13 trở lên và iPhone hỗ trợ Core NFC.
- Xcode và CocoaPods.
- Apple Developer provisioning profile có capability **Near Field
  Communication Tag Reading**.

## Cài đặt

### 1. Cài dependency Flutter

```bash
flutter pub get
```

### 2. Provision Luxand native SDK

Raw Luxand binary không được lưu trong Git vì đây là SDK thương mại. Lấy các
binary từ bộ FaceSDK đã được cấp phép và đặt đúng vị trí:

```text
packages/flutter_face_sdk/android/src/main/jniLibs/arm64-v8a/libfsdk.so
packages/flutter_face_sdk/android/src/main/jniLibs/armeabi-v7a/libfsdk.so
packages/flutter_face_sdk/ios/Frameworks/fsdk.framework/
```

Không commit native SDK, vendor archive hoặc license key lên repository.

### 3. Cấu hình Luxand

Tạo file cấu hình local từ mẫu:

```bash
cp .luxand.env.example.json .luxand.env.json
chmod 600 .luxand.env.json
```

Điền license tương ứng và chỉ bật cờ runtime sau khi đã kiểm tra đúng binary
FaceSDK 8.3 cho nền tảng đó.

| Biến | Giá trị mẫu | Ý nghĩa |
| --- | ---: | --- |
| `LUXAND_ANDROID_KEY` | rỗng | License Android, bắt buộc khi chạy FaceID trên Android |
| `LUXAND_IOS_KEY` | rỗng | License iOS, bắt buộc khi chạy FaceID trên iOS |
| `LUXAND_ANDROID_83_VERIFIED` | `false` | Xác nhận runtime Android đã provision đúng phiên bản 8.3 |
| `LUXAND_IOS_83_VERIFIED` | `false` | Xác nhận runtime iOS đã provision đúng phiên bản 8.3 |
| `LUXAND_MATCH_THRESHOLD` | `0.95` | Ngưỡng so khớp ảnh DG2, trong khoảng `(0, 1]` |
| `LUXAND_LIVENESS_THRESHOLD` | `0.95` | Ngưỡng liveness, trong khoảng `(0, 1]` |
| `LUXAND_CAMERA_EXPOSURE_OFFSET` | `0.6` | Bù sáng camera nếu thiết bị hỗ trợ |

Hai trường `LUXAND_DIRECTION_*` trong file mẫu hiện chưa được sử dụng bởi luồng
FaceID hai bước.

File `.luxand.env.json` đã được `.gitignore`. Android Gradle và iOS Xcode build
phase tự nạp file này mà không in license ra log. Có thể truyền tường minh khi
chạy Flutter CLI:

```bash
flutter run --dart-define-from-file=.luxand.env.json
```

Nếu thiếu license hoặc cờ `*_83_VERIFIED`, ứng dụng sẽ không mở camera FaceID
và hiển thị lỗi cấu hình tương ứng.

## Chạy ứng dụng

Kết nối thiết bị thật rồi chạy:

```bash
flutter devices
flutter run --dart-define-from-file=.luxand.env.json
```

Trên iOS, mở `ios/Runner.xcworkspace` khi cần chọn Development Team và kiểm tra
capability NFC cho provisioning profile local.

## Build

### APK ARM64 nhẹ cho tester

```bash
flutter build apk \
  --release \
  --target-platform android-arm64 \
  --split-per-abi \
  --dart-define-from-file=.luxand.env.json
```

Artifact được tạo tại:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

> Cấu hình hiện tại dùng debug signing cho build `release` nhằm phục vụ thử
> nghiệm. Trước khi phát hành production, cần thay bằng signing config riêng và
> quản lý keystore ngoài repository.

### Android App Bundle

```bash
flutter build appbundle \
  --release \
  --dart-define-from-file=.luxand.env.json
```

Native bridge dùng NDK r28 và ELF alignment 16 KB cho thiết bị Android mới.

### iOS

Smoke build không ký mã:

```bash
flutter build ios \
  --release \
  --no-codesign \
  --dart-define-from-file=.luxand.env.json
```

Để cài lên thiết bị hoặc phân phối TestFlight, cấu hình signing/provisioning
trong Xcode và build không dùng `--no-codesign`.

## Kiểm thử và phân tích tĩnh

```bash
flutter test
dart analyze lib test packages/flutter_face_sdk/lib/src/presentation/faceid_view.dart
```

Bộ test hiện có bao phủ parser MRZ, validation BAC, DG2 portrait decoder,
FaceID framing/motion challenge, liveness/match policy và widget chính.

## Cấu trúc dự án

```text
lib/features/nfc_ekyc/
├── data/          # OCR, NFC reader, MRZ parser, DG2 decoder
├── domain/        # Model và policy theo loại giấy tờ
└── presentation/  # Capture, NFC progress, FaceID và màn kết quả

packages/flutter_face_sdk/
├── lib/           # Dart wrapper, tracker, liveness và face matching
├── src/           # Native FFI bridge
├── android/       # Android native integration
└── ios/           # iOS native integration

test/features/nfc_ekyc/  # Unit và widget tests
```

## Xử lý lỗi thường gặp

### `Luxand 8.3 chưa được bật bằng file env`

- Kiểm tra đúng key của nền tảng hiện tại.
- Kiểm tra native binary đã được đặt đúng thư mục.
- Chỉ đặt `LUXAND_ANDROID_83_VERIFIED` hoặc `LUXAND_IOS_83_VERIFIED` thành
  `true` sau khi xác nhận runtime đúng phiên bản 8.3.
- Chạy lại ứng dụng để Dart compile nhận cấu hình mới.

### Đọc được DG2 nhưng không hiển thị ảnh trên iOS

- Giữ CCCD sát vùng NFC của iPhone cho đến khi phiên đọc hoàn tất.
- Thử lại nếu chip bị di chuyển trong lúc đọc DG2.
- Đảm bảo đang chạy build mới có native ImageIO fallback cho JPEG2000.

### Camera không hoàn tất FaceID

- Chỉ để một khuôn mặt trong khung.
- Giữ điện thoại ngang tầm mắt, tránh nghiêng đầu.
- Đảm bảo mặt đủ sáng và không bị che khuất.
- Hoàn thành lần lượt bước căn chỉnh và bước đưa điện thoại lại gần.
- Kiểm tra lại Match/Liveness threshold nếu dùng bộ dữ liệu thử nghiệm riêng.

### Không đọc được NFC

- Dùng thiết bị thật; simulator/emulator không hỗ trợ phiên NFC này.
- Kiểm tra NFC đang bật trên Android.
- Trên iOS, kiểm tra entitlement và provisioning profile có capability NFC.
- Xác nhận số tài liệu MRZ, ngày sinh và ngày hết hạn trước khi thử lại.

## Quyền riêng tư và giới hạn

- Luồng demo không cấu hình backend và không tải ảnh CCCD/selfie lên server.
- OCR, NFC, giải mã DG2 và FaceID được xử lý trên thiết bị.
- Ảnh DG2 và mẫu camera được lưu tạm trong phiên rồi xóa theo cơ chế
  best-effort khi đóng màn xác thực.
- License Luxand, signing key và artifact build không được lưu trong Git.
- Trạng thái “đã đọc SOD” chỉ xác nhận file SOD có thể đọc; ứng dụng chưa xác
  minh chữ ký với CSCA quốc gia.
- Đây là demo kỹ thuật, chưa phải giải pháp eKYC production: chưa có audit
  trail, backend risk engine, chống giả mạo giấy tờ hoàn chỉnh hoặc quy trình
  tuân thủ pháp lý.

## License và third-party SDK

Repository hiện chưa khai báo một open-source license ở cấp dự án. Luxand
FaceSDK là dependency thương mại và chịu điều khoản license riêng; người sử
dụng phải tự bảo đảm quyền sử dụng và phân phối phù hợp.
