# Walkthrough - Tái cấu trúc Màn hình & Tối ưu hóa UI/UX

Tôi đã hoàn thành tất cả các thay đổi giao diện theo yêu cầu trong kế hoạch triển khai của **Phase 12**, đồng thời khắc phục tất cả linter và biên dịch thành công ứng dụng trên Web (`Release Mode`).

## Các thay đổi chính (Changes Made)

### 1. Tối ưu hóa UI/UX & Cấu hình nhanh
- **Icon trích dẫn**: Cập nhật toàn bộ icon đại diện cho trích dẫn (Citations) sang icon dạng quote học thuật (`Icons.format_quote`) tại các màn hình:
  - [home_screen.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/features/home/presentation/screens/home_screen.dart)
  - [journal_screen.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/features/journal/presentation/screens/journal_screen.dart)
  - [publication_detail_screen.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/features/journal/presentation/screens/publication_detail_screen.dart)
  - [keywords_screen.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/features/keywords/presentation/screens/keywords_screen.dart)
- **Nút Bỏ qua (Skip)**: Bổ sung tùy chọn `Skip for now` tại [setup_screen.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/features/personalization/presentation/screens/setup_screen.dart) cho phép người dùng lướt nhanh onboarding với dữ liệu cấu hình Guest mặc định.
- **Bản đồ quan hệ**: Giới hạn đồ thị Fruchterman-Reingold xuống tối đa 20 tác giả hàng đầu để tối ưu hiệu năng và tránh giật lag máy ảo.

### 2. Bento Grid 6 thẻ chỉ số trang chủ
- Mở rộng Dashboard trang chủ để hiển thị đầy đủ 6 thẻ phân tích bắt buộc:
  - Tổng số ấn phẩm (Total Publications)
  - Số trích dẫn trung bình (Average Citations)
  - Năm hoạt động nhiều nhất (Most Active Year)
  - Tác giả đóng góp hàng đầu (Top Author)
  - Tạp chí hàng đầu (Top Journal)
  - Bài báo ảnh hưởng nhất (Most Influential Paper)

### 3. Tái cấu trúc phân tích Tạp chí (Top Journals & Chart)
- Thay đổi màn hình [journal_screen.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/features/journal/presentation/screens/journal_screen.dart) từ danh sách bài viết sang danh sách xếp hạng tạp chí đóng góp nhiều nhất.
- Hiển thị biểu đồ thanh ngang đóng góp của tạp chí ở đầu trang thông qua widget dùng chung [horizontal_bar_chart.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/core/widgets/horizontal_bar_chart.dart).

### 4. Màn hình chi tiết Từ khóa (KeywordDetailScreen)
- Tạo mới màn hình [keyword_detail_screen.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/features/keywords/presentation/screens/keyword_detail_screen.dart) với 3 Tab chính phân tích chuyên sâu cho từng từ khóa (chủ đề) cụ thể:
  - **Topic Evolution**: Hiển thị LineChart tiến trình phát triển và danh sách ấn phẩm liên quan.
  - **Author Productivity**: Xếp hạng và phân tích năng suất đóng góp của các tác giả trong từ khóa đó.
  - **Journal Ranking**: Danh sách tạp chí hoạt động tích cực nhất cho chủ đề đó.
- Cập nhật [keywords_screen.dart](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/lib/features/keywords/presentation/screens/keywords_screen.dart) thành một trang danh mục tìm kiếm từ khóa tinh gọn, chạm vào từ khóa sẽ tự động điều hướng sang màn hình chi tiết mới.

---

## Kết quả kiểm tra & Xác thực (Verification & Build Results)

1. **Kiểm tra Linter & Code Quality**:
   - `flutter analyze` báo cáo: **No issues found!**
   - Loại bỏ toàn bộ các cảnh báo linter cũ, thay thế các hàm opacity deprecated thành `.withValues(alpha: ...)`.

2. **Xác thực Biên dịch**:
   - Chạy lệnh `flutter build web --release` hoàn thành xuất sắc trong 65.9 giây mà không phát sinh bất kỳ lỗi biên dịch nào.
   - Thư mục đầu ra: `build/web` đã được đóng gói thành công.
