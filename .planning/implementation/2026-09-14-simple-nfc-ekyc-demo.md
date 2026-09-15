# Simple NFC eKYC demo — 2026-09-14

## Phạm vi

Tạo app Flutter độc lập, tối giản để kiểm thử đọc chip CCCD Việt Nam dựa trên
luồng NFC/eKYC của `/Volumes/SSD/superapp`. Giữ document capture và OCR cần cho
MRZ nhưng không clone Bloc, backend, Face ID hoặc luồng đăng ký tài khoản.

## Hành vi

- Home chia ba bước: chụp CCCD, kiểm tra dữ liệu MRZ, đọc NFC.
- Camera chụp mặt trước để giữ luồng hai mặt, sau đó chụp mặt sau và OCR ba dòng
  MRZ. Với app test NFC, OCR mặt trước không còn là điều kiện chặn.
- Tự điền số tài liệu MRZ 9 chữ số, ngày sinh và ngày hết hạn; vẫn cho sửa tay
  hoặc nhập tay để debug NFC độc lập.
- Mở chip bằng BAC, đọc EF.COM, DG1, DG2, DG13 và SOD.
- File ảnh camera được xóa sau OCR; thumbnail và kết quả chỉ giữ trong RAM.
- Không log, upload hoặc persist PII.
- Hủy session NFC cả khi đang chờ tag.
- Map lỗi timeout, tag lost, BAC và communication thành thông báo an toàn.
- `DocumentProfile` cô lập validation/mapping Việt Nam để có thể bổ sung profile
  quốc gia khác mà không đổi NFC transport.

## File/screen chính

- `lib/features/nfc_ekyc/presentation/nfc_home_screen.dart`: form, tiến trình và
  kết quả đọc chip, cùng preview ảnh hai mặt.
- `lib/features/nfc_ekyc/presentation/identity_capture_screen.dart`: camera và
  hướng dẫn chụp tuần tự mặt trước/mặt sau.
- `lib/features/nfc_ekyc/presentation/camera_preview_geometry.dart`: chuẩn hóa
  kích thước preview theo orientation để không kéo giãn ảnh camera.
- `lib/features/nfc_ekyc/presentation/nfc_read_controller.dart`: state và vòng
  đời phiên đọc.
- `lib/features/nfc_ekyc/data/nfc_document_reader.dart`: NFC/DMRTD transport.
- `lib/features/nfc_ekyc/data/identity_document_recognition_service.dart`: OCR
  on-device qua ML Kit.
- `lib/features/nfc_ekyc/data/vietnamese_cccd_mrz_parser.dart`: normalize lỗi OCR
  phổ biến và parse dữ liệu BAC.
- `lib/features/nfc_ekyc/domain/`: input, output và profile CCCD Việt Nam.
- `android/app/src/main/AndroidManifest.xml`: NFC permission/feature.
- `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`: Core NFC usage,
  ISO7816 AID và entitlement.

## Dependency

- `dmrtd` pin commit `3b6c091843573b275ae68a87335e1872f8b60ea0`, cùng
  revision SuperApp tham chiếu.
- `flutter_nfc_kit` pin `3.6.2` để kiểm tra và kết thúc session an toàn.
- `camera ^0.10.5+9` và `google_mlkit_text_recognition ^0.11.0`, theo source
  SuperApp và đã được người dùng phê duyệt bổ sung.

## Verify

- `dart format --output=none --set-exit-if-changed lib test`: pass.
- `dart analyze lib test`: pass, không có issue.
- `flutter test`: pass 12 tests, gồm geometry preview, parser OCR/MRZ và widget
  validation.
- `flutter build apk --debug`: pass; APK tại
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Android merged manifest chứa quyền camera/NFC cùng camera/NFC feature.
- `flutter build ios --debug --no-codesign`: pass; app bundle build thành công,
  có camera/NFC usage description, ISO7816 MRTD AID và minimum iOS 13.
- `flutter analyze`: không chạy được do Flutter SDK cục bộ tìm tên snapshot cũ
  `analysis_server.dart.snapshot`; đã thay bằng `dart analyze lib test` từ cùng
  Dart SDK và pass.
- Chưa thể xác minh capture -> OCR -> NFC end-to-end vì cần CCCD thật trên thiết
  bị vật lý.

## Sửa tỷ lệ camera preview — 2026-09-14

- Nguyên nhân: màn hình dọc bọc `CameraPreview` bằng tỷ lệ landscape của sensor,
  xung đột với cơ chế đảo tỷ lệ sẵn có của plugin `camera` và làm ảnh bị bóp.
- Preview hiện đổi kích thước sensor theo orientation, dùng `BoxFit.cover` để
  crop phần dư mà không kéo giãn nội dung.
- Padding được đưa ra ngoài `AspectRatio`, vì vậy khung căn CCCD giữ đúng tỷ lệ
  vật lý `85.6 / 54`.
- Bổ sung regression test cho kích thước preview ở portrait và landscape.

## Cải thiện độ chính xác OCR camera — 2026-09-14

- Log thiết bị cho thấy ảnh JPEG chỉ có kích thước `720 x 1280`; autofocus và
  auto-exposure đều đã hội tụ nên đây không phải lỗi focus/capture.
- Đổi camera từ `ResolutionPreset.high` sang `ResolutionPreset.ultraHigh`, khớp
  với pipeline camera của SuperApp. Chữ nhỏ trên CCCD và ba dòng MRZ nhờ đó có
  nhiều pixel hơn trước khi chuyển vào ML Kit OCR.
- Không thêm dependency và không thay đổi parser, luồng lưu/xóa ảnh hay NFC.

## Sửa đối chiếu số CCCD từ MRZ — 2026-09-15

- Ảnh mặt sau đã được OCR/parse thành công nhưng bị báo không khớp mặt trước.
- Nguyên nhân: parser tìm chuỗi 12 số từ offset 14 của dòng TD1; offset này là
  check-digit của số tài liệu, nên MRZ không có filler giữa hai trường sẽ tạo
  kết quả sai gồm `check-digit + 11 số đầu của CCCD`.
- Bắt đầu đọc optional data từ offset 15 như SuperApp và chuẩn ICAO TD1.
- Bổ sung regression test với dòng MRZ có check-digit liền số CCCD.

## Tự động quét MRZ — 2026-09-15

- Khi chụp mặt trước thành công và chuyển sang mặt sau, app tự chụp/OCR MRZ mỗi
  3 giây giống nhịp auto scan của SuperApp; nút `Quét ngay` vẫn được giữ lại.
- Ảnh không rõ hoặc kết quả OCR tạm thời không khớp sẽ được thử lại tự động,
  thay vì bắt người dùng bấm chụp lặp lại.
- Timer dừng khi app ra nền, người dùng chụp lại từ đầu, đọc thành công hoặc
  đóng màn hình; mỗi ảnh tạm vẫn được xóa sau OCR.
- Không thêm dependency mới và không thay đổi luồng NFC.

## Giảm false-negative khi quét — 2026-09-15

- Bỏ hard gate OCR/đối chiếu số ở mặt trước. App vẫn bắt buộc chụp đủ hai mặt,
  nhưng BAC chỉ phụ thuộc số tài liệu, ngày sinh và ngày hết hạn từ MRZ.
- Parser ghép hai dòng OCR liền kề khi ML Kit vô tình tách một dòng MRZ.
- Chuẩn hóa thêm `1DVNM`/`I0VNM`, ký tự `«` và lỗi `K` thành filler `<` ở
  vùng dữ liệu MRZ.
- Giữ toàn bộ xử lý on-device, không log hoặc persist dữ liệu CCCD.

## Ổn định ảnh auto-scan mặt sau — 2026-09-15

- Dữ liệu trong ảnh kiểm thử đã được parse đúng, nhưng app chốt ngay frame OCR
  thành công đầu tiên nên thumbnail mặt sau có thể còn nghiêng/lệch.
- Auto-scan chỉ hoàn tất khi hai lần liên tiếp cho cùng số tài liệu, ngày sinh,
  ngày hết hạn và số định danh; ảnh của lần xác nhận thứ hai được sử dụng.
- Nút `Quét ngay` vẫn chốt một lần theo chủ ý người dùng, không bắt đợi hai nhịp.
- Sửa mô tả màn hình kết quả để không còn tuyên bố đã đối chiếu OCR hai mặt.

## Giới hạn chủ động

- Đây là document capture + OCR + NFC, chưa có liveness/face matching.
- SOD chỉ được đọc và báo trạng thái, chưa verify chain với CSCA quốc gia.
