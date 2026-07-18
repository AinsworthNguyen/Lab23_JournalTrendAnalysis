# Danh sách công việc thực hiện (Task List)

## ❖ Chuẩn bị & Sửa lỗi Linter (Pre-requisites & Code Quality)
- [x] Tạo nhánh Git mới tên là `kiet` từ nhánh hiện tại
- [x] Chuyển sang nhánh `kiet` trước khi bắt đầu chỉnh sửa source code
- [x] Chạy lệnh `flutter analyze` để quét toàn bộ cảnh báo SonarQube & Linter
- [x] Khắc phục toàn bộ các cảnh báo linter hiện có trong mã nguồn (Không phát hiện lỗi/cảnh báo)

## ❖ Tối ưu hóa UI/UX & Cấu hình nhanh
- [x] Giảm thời gian chờ Dio timeout của `ApiClient` xuống 8 giây (trong [api_client.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/core/network/api_client.dart))
- [x] Thay đổi icon trích dẫn từ `Icons.star` sang `Icons.format_quote` học thuật trên toàn bộ ứng dụng
- [x] Bổ sung tùy chọn "Skip" trên màn hình thiết lập sở thích [setup_screen.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/features/personalization/presentation/screens/setup_screen.dart)
- [x] Giới hạn tối đa 20 nút trên Bản đồ mạng lưới quan hệ đồng tác giả ở tab Keywords để tránh lag máy ảo

## ❖ Phase 12 — Tái cấu trúc Màn hình (Screen Restructuring)
- [x] Mở rộng Bento Grid trang chủ `home_screen.dart` thành đủ 6 thẻ chỉ số phân tích bắt buộc
- [x] Thiết kế lại màn hình `journal_screen.dart` hiển thị danh sách tạp chí xếp hạng và biểu đồ đóng góp của tạp chí thay vì danh sách bài viết
- [x] Tạo mới màn hình chi tiết từ khóa `KeywordDetailScreen` hiển thị biểu đồ tiến trình xu hướng (LineChart) và xếp hạng tác giả đóng góp
- [x] Rút gọn `keywords_screen.dart` thành danh mục tìm kiếm từ khóa, kết nối điều hướng sang `KeywordDetailScreen`

## ❖ Phase 13 — Kiểm thử tự động với Patrol (Patrol Integration Testing)
- [ ] Cấu hình thư viện `patrol` trong `pubspec.yaml` và cài đặt công cụ dòng lệnh `patrol_cli`
- [ ] Cấu hình thiết lập test runner trong Gradle (`android/app/build.gradle`)
- [ ] Viết kịch bản kiểm thử đăng nhập/đăng xuất (`authentication_test.dart`)
- [ ] Viết kịch bản kiểm thử tìm kiếm chủ đề và xem chi tiết bài báo (`publication_test.dart`)
- [ ] Viết kịch bản kiểm thử điều hướng trang và chi tiết tạp chí (`journal_test.dart`)
- [ ] Viết kịch bản kiểm thử trang từ khóa và xem chi tiết từ khóa (`keyword_test.dart`)
- [ ] Viết kịch bản kiểm thử xuất báo cáo PDF và tải lên Firebase Storage (`export_test.dart`)
- [ ] Chạy kiểm thử tự động trên máy ảo Android và xác nhận toàn bộ 11 test cases đều vượt qua (Pass)
