# Tài liệu Tổng quan Hệ thống - Journal Trend Analysis

Hệ thống **Journal Trend Analysis** là một ứng dụng di động & đa nền tảng được phát triển bằng **Flutter**, nhằm mục đích tìm kiếm, phân tích và thống kê các xu hướng nghiên cứu khoa học, tác giả, bài báo và từ khóa trong các tạp chí khoa học.

---

## 1. Kiến trúc Hệ thống (System Architecture)

Dự án được xây dựng theo mô hình **Clean Architecture** kết hợp với **BLoC (Business Logic Component)** để quản lý trạng thái (State Management). Cấu trúc mã nguồn được chia làm 3 lớp chính cho mỗi tính năng (Feature-first structure):

```
lib/
├── core/                   # Các thành phần dùng chung (theme, navigation, network, utils...)
├── features/               # Các chức năng chính của hệ thống
│   ├── home/               # Trang chủ, hiển thị tổng quan & dashboard xu hướng
│   ├── journal/            # Quản lý các bài báo, tạp chí khoa học
│   ├── author/             # Quản lý thông tin tác giả, công trình nghiên cứu
│   ├── keywords/           # Phân tích từ khóa phổ biến (Keyword trends)
│   ├── personalization/    # Cá nhân hóa trải nghiệm (lưu trữ, bookmark, đề xuất)
│   └── profile/            # Thông tin cá nhân, cài đặt giao diện (Theme, Language)
├── main.dart               # Điểm khởi chạy ứng dụng (Bootstrap)
└── injection_container.dart # Cấu hình Dependency Injection (GetIt & Injectable)
```

### Các lớp trong mỗi Tính năng (Features)
- **Data**: Đảm nhận việc lấy dữ liệu từ local (Hive, SharedPreferences) hoặc remote (API, Firebase). Gồm: *Models, Repositories Implementation, Data Sources*.
- **Domain**: Chứa logic nghiệp vụ cốt lõi, độc lập với UI. Gồm: *Entities, Repositories Interfaces, Use Cases*.
- **Presentation**: Lớp giao diện người dùng và quản lý luồng trạng thái. Gồm: *Blocs/Cubits, Pages/Screens, Widgets*.

---

## 2. Công nghệ & Thư viện sử dụng (Tech Stack)

| Công nghệ / Thư viện | Vai trò & Chức năng |
| :--- | :--- |
| **Flutter & Dart** | Khung phát triển ứng dụng đa nền tảng (Android, iOS, Web, Windows). |
| **Flutter BLoC / Cubit** | Quản lý trạng thái ứng dụng một cách nhất quán và dễ kiểm thử. |
| **GetIt & Injectable** | Service Locator & Dependency Injection (DI) giúp khởi tạo và quản lý vòng đời các đối tượng. |
| **Hive** | Cơ sở dữ liệu NoSQL cục bộ tốc độ cao, dùng để cache dữ liệu phân tích (`analytics_cache`) và lịch sử tìm kiếm (`search_history`). |
| **Firebase Core & Services** | Tích hợp dịch vụ đám mây của Google. |
| **Firebase Messaging** | Quản lý và tiếp nhận thông báo đẩy (Push Notifications). |
| **Firebase Remote Config** | Thay đổi cấu hình ứng dụng động từ xa mà không cần cập nhật ứng dụng. |
| **Easy Localization** | Hỗ trợ đa ngôn ngữ quốc tế (Mặc định hỗ trợ Tiếng Anh `en` và Tiếng Việt `vi`). |

---

## 3. Các Tính năng Chính (Core Features)

1. **Dashboard Xu hướng (Home Trend Analysis)**:
   - Thống kê các tạp chí và bài báo có lượt đọc/trích dẫn cao nhất.
   - Trực quan hóa số liệu nghiên cứu khoa học theo thời gian.
2. **Quản lý & Tra cứu Bài báo (Journal Feature)**:
   - Tìm kiếm bài báo khoa học theo bộ lọc nâng cao.
   - Xem chi tiết nội dung, tóm tắt (abstract), liên kết nguồn và tài liệu tham khảo.
3. **Phân tích Tác giả (Author Analytics)**:
   - Xem hồ sơ tác giả khoa học, các công trình đã công bố.
   - Thống kê chỉ số ảnh hưởng của tác giả.
4. **Xu hướng Từ khóa (Keyword Trends)**:
   - Theo dõi sự thay đổi tần suất xuất hiện của các từ khóa khoa học qua các năm để nắm bắt xu hướng công nghệ/nghiên cứu mới.
5. **Cá nhân hóa & Lịch sử (Personalization)**:
   - Lưu trữ bài báo yêu thích (Bookmark).
   - Lưu lịch sử tìm kiếm cục bộ thông qua cơ sở dữ liệu Hive.
6. **Cài đặt & Cấu hình (Profile & Settings)**:
   - Thay đổi chế độ giao diện sáng/tối (Light/Dark Mode).
   - Thay đổi ngôn ngữ hiển thị (English / Tiếng Việt).

## 3. Nguồn Dữ liệu & API (Data Sources & API Integration)

Hệ thống tích hợp dữ liệu nghiên cứu khoa học trực tiếp từ **OpenAlex API** (`https://api.openalex.org`), một cơ sở dữ liệu mở khổng lồ về các công trình nghiên cứu khoa học toàn cầu.

### Chi tiết tích hợp:
- **API Client (`ApiClient`)**: Sử dụng thư viện `Dio` để thực hiện các yêu cầu HTTP, hỗ trợ cấu hình timeout (40 giây) và tự động ghi log lỗi/phản hồi.
- **Tối ưu hóa Rate Limit**: Dự án tham gia vào **OpenAlex Polite Pool** bằng cách gửi email liên hệ trong tiêu đề `User-Agent` (`academic-analytics@fptu.edu.vn`). Điều này giúp tăng giới hạn lượt gọi API và đảm bảo độ ổn định của hệ thống.
- **Các Endpoint chính sử dụng**:
  - `/works`: Tìm kiếm, truy xuất bài báo khoa học, phân tích tác phẩm theo chủ đề (concepts) và lấy bài báo có sức ảnh hưởng lớn nhất.
  - `/sources`: Lấy thông tin chi tiết về các nguồn tạp chí, hội nghị khoa học hàng đầu và nhà xuất bản.

---

## 4. Cấu trúc Giao diện & Layout Frontend (FE Layout Detail)

Dưới đây là sơ đồ cấu trúc thư mục của các màn hình giao diện người dùng (Presentation Screens) trong thư mục `lib/features/`, mô tả trực tiếp bố cục và vị trí lưu trữ các thành phần giao diện trên ổ đĩa:

```text
lib/features/
├── personalization/ (Tính năng cá nhân hóa & xác thực)
│   └── presentation/
│       └── screens/
│           ├── login_screen.dart             # Màn hình Đăng nhập
│           │                                 - Xác thực người dùng bằng Firebase Auth.
│           │                                 - Giao diện đăng nhập tối giản và bảo mật.
│           └── setup_screen.dart             # Màn hình thiết lập ban đầu (Onboarding)
│                                             - Thiết lập Họ tên người dùng.
│                                             - Lựa chọn chủ đề/lĩnh vực nghiên cứu yêu thích (Concepts).
│
├── home/ (Tính năng Trang chủ - Dashboard)
│   └── presentation/
│       └── screens/
│           └── home_screen.dart              # Màn hình Trang chủ chính
│                                             - Lời chào cá nhân hóa + Nút đồng bộ nhanh (Sync).
│                                             - Thanh tìm kiếm chủ đề động (có màn hình overlay gợi ý và lịch sử tìm kiếm).
│                                             - Bento Grid 2 thẻ Metrics: Total Publications (Màu xanh) & Avg Citations (Màu hổ phách).
│                                             - Danh sách bài báo gợi ý theo sở thích kèm Badge Open/Closed Access & Citation stars.
│                                             - Tích hợp hiệu ứng flutter_animate (FadeIn, SlideY, Scale).
│
├── journal/ (Tính năng quản lý bài viết & tạp chí)
│   └── presentation/
│       └── screens/
│           ├── journal_screen.dart           # Màn hình Khám phá bài viết
│           │                                 - Danh sách bài báo khoa học hỗ trợ tìm kiếm nâng cao.
│           │                                 - Cơ chế cuộn vô hạn (Infinite Scroll) tự động tải trang kế tiếp khi vuốt xuống.
│           ├── journal_detail_screen.dart    # Màn hình chi tiết tạp chí
│           │                                 - Xem thông tin chi tiết về nhà xuất bản hoặc nguồn tạp chí/hội nghị.
│           └── publication_detail_screen.dart # Màn hình chi tiết bài báo
│                                             - Hiển thị đầy đủ Abstract (tóm tắt), thông tin nhóm tác giả, năm xuất bản.
│                                             - Số lượt trích dẫn và liên kết gốc (DOI).
│
├── keywords/ (Tính năng Phân tích Xu hướng & Thống kê)
│   └── presentation/
│       └── screens/
│           └── keywords_screen.dart          # Màn hình phân tích nâng cao (Gồm 4 TabBar con)
│                                             1. Topic Evolution: Biểu đồ đường LineChart (fl_chart) về lượng bài viết & trích dẫn qua các năm.
│                                             2. Top Keywords: Biểu đồ thanh ngang HorizontalBarChart & danh sách từ khóa mới nổi.
│                                             3. Author Productivity: Thống kê số lượng bài viết/trích dẫn của tác giả qua biểu đồ ScatterChart.
│                                             - Bản đồ mạng lưới tương tác vật lý (Author Collaboration Network) trực quan hóa các mối quan hệ đồng tác giả (GraphView + FruchtermanReingoldAlgorithm).
│                                             4. Journal Ranking: Bảng xếp hạng các tạp chí khoa học uy tín.
│
├── author/ (Tính năng hồ sơ tác giả)
│   └── presentation/
│       └── screens/
│           └── author_detail_screen.dart     # Màn hình Chi tiết tác giả
│                                             - Hiển thị thông tin học thuật của tác giả, h-index, đơn vị công tác.
│                                             - Danh sách các bài nghiên cứu đã công bố.
│
└── profile/ (Tính năng Cá nhân & Cài đặt hệ thống)
    └── presentation/
        └── screens/
            └── profile_screen.dart           # Màn hình Cài đặt & Hồ sơ cá nhân
                                              - Quản lý thông tin tài khoản cá nhân.
                                              - Chuyển đổi Light/Dark Mode (thông qua ThemeCubit).
                                              - Tùy chọn đa ngôn ngữ Tiếng Anh / Tiếng Việt (easy_localization).
                                              - Nút xóa cache tìm kiếm và Đăng xuất tài khoản.
```

---

## 5. Hướng dẫn Chạy Dự án (Getting Started)

### Yêu cầu hệ thống
- **Flutter SDK**: `>=3.0.0`
- **Dart SDK**
- Một thiết bị thật (Android/iOS) hoặc Trình duyệt web (Chrome/Edge).

### Các bước cài đặt và chạy ứng dụng

1. **Tải các gói phụ thuộc (Dependencies)**:
   ```bash
   flutter pub get
   ```

2. **Chạy Code Generation (Build Runner)**:
   Do dự án sử dụng `injectable` để tự động tạo mã Dependency Injection, bạn cần chạy lệnh sau trước khi chạy app:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Chạy ứng dụng**:
   - Chạy trên trình duyệt Web (Chrome):
     ```bash
     flutter run -d chrome
     ```
   - Chạy trên thiết bị di động / máy ảo (nếu có):
     ```bash
     flutter run
     ```
