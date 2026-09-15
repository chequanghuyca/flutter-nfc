# NFC eKYC Demo

Flutter app tối giản để đọc chip CCCD Việt Nam trực tiếp trên thiết bị. Luồng
được rút gọn từ `/Volumes/SSD/superapp`: chụp hai mặt -> OCR MRZ ->
xác nhận MRZ -> BAC -> EF.COM -> DG1 -> DG2 -> DG13 -> SOD. App không có
backend, tài khoản, Face ID hoặc lưu trữ dữ liệu lâu dài.

## Chạy app

Yêu cầu:

- Android 7.0 / API 24 trở lên có NFC, hoặc iPhone hỗ trợ Core NFC với iOS 13+.
- Thiết bị thật có camera; simulator/emulator không đọc được NFC.
- iOS cần Apple Developer provisioning profile có capability **Near Field
  Communication Tag Reading**.

```bash
flutter pub get
flutter run
```

## Luồng kiểm thử

1. Chụp mặt trước CCCD để giữ đúng luồng hai mặt; bước này không chặn bởi OCR.
2. Chụp mặt sau và đặt ba dòng MRZ trong khung hướng dẫn.
3. App lấy dữ liệu BAC từ MRZ và tự điền vào form kiểm tra.
4. Kiểm tra hoặc sửa lại ba giá trị trước khi bắt đầu đọc NFC:

   - **Số tài liệu MRZ**: đúng 9 chữ số ngay sau `IDVNM`. Đây không phải số CCCD
   12 chữ số.
   - **Ngày sinh**.
   - **Ngày hết hạn**.

Có thể bỏ qua camera và nhập tay ba trường trên để debug NFC riêng.

Ba giá trị này tạo khóa BAC để mở chip. Sau khi đọc thành công, app hiển thị
DG1, ảnh DG2 nếu codec thiết bị hỗ trợ, tình trạng DG13 và SOD. “Đã đọc SOD”
không có nghĩa chữ ký đã được xác minh với CSCA quốc gia.

## Mở rộng quốc gia khác

Tạo implementation mới của `DocumentProfile` trong
`lib/features/nfc_ekyc/domain/`, định nghĩa validation, access key candidate và
cách map MRZ của quốc gia đó. NFC transport trong `MrtdNfcDocumentReader` được
dùng lại cho giấy tờ ICAO 9303 hỗ trợ BAC.

## Quyền riêng tư

- Không gọi mạng hoặc backend.
- Không ghi log dữ liệu MRZ, khóa BAC, ảnh hay thông tin cá nhân.
- Ảnh do camera tạo được OCR rồi xóa file tạm; thumbnail và kết quả chỉ giữ
  trong bộ nhớ, mất khi app bị đóng.

Đây là demo **document capture + OCR + NFC**, chưa phải giải pháp eKYC hoàn
chỉnh: không có liveness, face matching, kiểm tra giả mạo ảnh hoặc xác minh chữ
ký SOD bằng CSCA tin cậy.
