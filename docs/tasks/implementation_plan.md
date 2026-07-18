# Kế hoạch Triển khai & Phát triển - Journal Trend Analysis

Tài liệu này vạch ra kế hoạch chi tiết cho việc tối ưu hóa giao diện (UI/UX), giải quyết các cảnh báo mã nguồn, tái cấu trúc các màn hình theo yêu cầu Lab 3 và triển khai kiểm thử tự động Patrol.

---

## 1. Yêu cầu Bắt buộc trước khi chỉnh sửa Code (Pre-requisites)

> [!IMPORTANT]
> **Quy định bắt buộc về Git**:
> Trước khi thực hiện bất kỳ chỉnh sửa nào đối với mã nguồn (`lib/`, `assets/`, `pubspec.yaml`,...), bắt buộc phải:
> 1. Tạo một nhánh (branch) mới tên là `kiet` từ nhánh hiện tại.
> 2. Chuyển sang nhánh `kiet` (`git checkout kiet`).
> 3. Mọi thay đổi và commit chỉ được thực hiện trên nhánh `kiet`.

> [!WARNING]
> **Sửa toàn bộ Cảnh báo SonarQube & Linter**:
> - Chạy lệnh phân tích mã nguồn: `flutter analyze`.
> - Sửa toàn bộ các cảnh báo (warnings), thông báo linter (lint rules) và các code smell để đạt tiêu chuẩn kiểm duyệt SonarQube/Kodus AI trước khi nộp bài.

---

## 2. Kế hoạch Hoạt động & Thay đổi Đề xuất (Proposed Changes)

### ❖ Giai đoạn 1: Thiết lập Git & Sửa lỗi Linter (Git & Code Smell Fixes)

#### [MODIFY] [api_client.dart](file:///d:/FPT/Semester_8\PRM393\Lab23_JournalTrendAnalysis\lib\core\network\api_client.dart)
- Rút ngắn thời gian `connectTimeout` và `receiveTimeout` từ 40 giây xuống còn **8 giây** để tránh đơ ứng dụng khi kết nối mạng yếu.

---

### ❖ Giai đoạn 2: Tái cấu trúc Màn hình (Phase 12 - Screen Restructuring)

#### [MODIFY] [home_screen.dart](file:///d:/FPT/Semester_8\FPT\Semester_8\PRM393\Lab23_JournalTrendAnalysis\lib\features\home\presentation\screens\home_screen.dart)
- Mở rộng Bento Grid hiển thị chỉ số trang chủ từ 2 thẻ lên **6 thẻ chỉ số** bắt buộc:
  1. Total publications (Tổng số bài báo)
  2. Avg citation count (Lượt trích dẫn trung bình)
  3. Most active publication year (Năm nghiên cứu sôi nổi nhất)
  4. Top contributing author (Tác giả cống hiến nhiều nhất)
  5. Top journal (Tạp chí hàng đầu)
  6. Most influential publication (Bài báo có sức ảnh hưởng lớn nhất)
- Cập nhật icon trích dẫn từ `Icons.star` sang `Icons.format_quote` (hoặc icon trích dẫn học thuật) để tránh hiểu nhầm về rating sao.

#### [MODIFY] [journal_screen.dart](file:///d:/FPT/Semester_8\PRM393\Lab23_JournalTrendAnalysis\lib\features\journal\presentation\screens\journal_screen.dart)
- Thiết kế lại màn hình Journal: Thay thế danh sách bài viết bằng giao diện **Xếp hạng tạp chí (Journal Rankings)** đóng góp hàng đầu theo lượt xuất bản.
- Tích hợp biểu đồ thanh ngang đóng góp của tạp chí (Journal contribution charts) và thống kê trích dẫn.

#### [NEW] [keyword_detail_screen.dart](file:///d:/FPT/Semester_8\PRM393\Lab23_JournalTrendAnalysis\lib\features\keywords\presentation\screens\keyword_detail_screen.dart)
- Tạo mới màn hình chi tiết từ khóa. Khi người dùng chọn một từ khóa từ tab Keywords, ứng dụng sẽ điều hướng tới màn hình này để hiển thị:
  - Biểu đồ tiến trình từ khóa qua các năm (LineChart).
  - Danh sách các tạp chí liên quan và bài viết liên quan.
  - Danh sách tác giả cống hiến hàng đầu sắp xếp theo số lượng bài viết giảm dần.

#### [MODIFY] [keywords_screen.dart](file:///d:/FPT/Semester_8\PRM393\Lab23_JournalTrendAnalysis\lib\features\keywords\presentation\screens\keywords_screen.dart)
- Tối giản hóa màn hình Keywords chỉ tập trung vào việc tìm kiếm từ khóa, danh sách từ khóa phổ biến/mới nổi.
- Thiết lập điều hướng (`GoRouter`) sang `KeywordDetailScreen`.
- Giới hạn số lượng nút vẽ trên Bản đồ mạng lưới hợp tác tác giả (`GraphView`) xuống tối đa 20 tác giả hàng đầu để tránh đơ giao diện trên thiết bị di động.

---

### ❖ Giai đoạn 3: Kiểm thử tự động với Patrol (Phase 13 - Patrol Testing)

#### [NEW] [authentication_test.dart](file:///d:/FPT/Semester_8\PRM393\Lab23_JournalTrendAnalysis\integration_test\authentication_test.dart)
- E2E Test: Đăng nhập Google, xác thực điều hướng sang Home, và đăng xuất.
#### [NEW] [publication_test.dart](file:///d:/FPT/Semester_8\PRM393\Lab23_JournalTrendAnalysis\integration_test\publication_test.dart)
- E2E Test: Tìm kiếm chủ đề, hiển thị kết quả bài báo, và xem chi tiết bài báo.
#### [NEW] [journal_test.dart](file:///d:/FPT/Semester_8\PRM393\Lab23_JournalTrendAnalysis\integration_test\journal_test.dart)
- E2E Test: Điều hướng trang Journals, kiểm tra danh sách xếp hạng tạp chí, mở xem chi tiết một tạp chí.
#### [NEW] [keyword_test.dart](file:///d:/FPT/Semester_8\PRM393\Lab23_JournalTrendAnalysis\integration_test\keyword_test.dart)
- E2E Test: Tìm kiếm từ khóa, mở xem chi tiết từ khóa (`KeywordDetailScreen`), kiểm tra biểu đồ và danh sách tác giả.
#### [NEW] [export_test.dart](file:///d:/FPT/Semester_8\PRM393\Lab23_JournalTrendAnalysis\integration_test\export_test.dart)
- E2E Test: Xuất báo cáo PDF tại màn Profile và tải lên Firebase Storage thành công.

---

## 3. Kế hoạch Kiểm thử & Xác minh (Verification Plan)

### Kiểm thử Thủ công (Manual Verification)
1. **Kiểm tra Giao diện trên Chrome Mobile Emulation**:
   - Chạy `flutter run -d chrome`.
   - Bật F12 và chuyển chế độ hiển thị sang Mobile (Pixel/iPhone) để xác minh độ phản hồi (responsive) của Bento Grid 6 thẻ chỉ số và các tab biểu đồ fl_chart.
2. **Kiểm tra Firebase Console**:
   - Xác nhận file PDF được lưu trữ chính xác trên Firebase Storage sau khi nhấn nút Export.
   - Xác nhận Analytics ghi nhận đầy đủ 7 sự kiện bắt buộc (`login`, `search_topic`, `view_publication`, `view_journal`, `view_keyword`, `export_pdf`, `logout`).
   - Gửi thử Push Notification từ Firebase Cloud Messaging console và kiểm tra xem thông báo có hiển thị ở Profile Notification Center không.
   - Nhấn "Force App Crash" trên Profile screen và xác nhận Crashlytics bắt được log crash trên Firebase Console.

### Kiểm thử Tự động (Automated Tests)
Chạy bộ kiểm thử E2E sử dụng CLI của Patrol:
```bash
patrol test -t integration_test/authentication_test.dart
patrol test -t integration_test/publication_test.dart
patrol test -t integration_test/journal_test.dart
patrol test -t integration_test/keyword_test.dart
patrol test -t integration_test/export_test.dart
```

---

## 4. Định nghĩa Hoàn thành (Definition of Done - DoD)

Một nhiệm vụ hoặc tính năng chỉ được coi là hoàn thành (Done) khi đáp ứng toàn bộ các tiêu chí sau:

1. **Nhánh Git hợp lệ**: Toàn bộ code thay đổi được commit và đẩy lên nhánh `kiet`. Không commit trực tiếp lên `main` hay `master`.
2. **Không còn Cảnh báo Linter**: Lệnh `flutter analyze` chạy thành công và không trả về bất kỳ lỗi hay cảnh báo linter nào.
3. **Đạt chỉ tiêu SonarQube**: Không còn các lỗi code smells nghiêm trọng nào tồn tại trong các file chỉnh sửa mới.
4. **Hoàn thiện Tính năng**:
   - Trang chủ hiển thị đầy đủ 6 metrics.
   - Trang Journals hiển thị danh sách tạp chí xếp hạng và biểu đồ đóng góp.
   - Trang Keywords hỗ trợ điều hướng sang màn hình con `KeywordDetailScreen`.
   - Trang Profile hoạt động đầy đủ FCM, PDF Export (Storage), Remote Config, và Crashlytics hooks.
5. **Vượt qua Kiểm thử**: Các kịch bản Patrol E2E test chạy thành công và trả về trạng thái **Pass** trên môi trường giả lập.
