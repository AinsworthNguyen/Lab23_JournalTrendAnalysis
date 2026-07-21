# Kế Hoạch Thực Hiện & Tiến Độ — Chức Năng Admin Role

> **Dự án:** Journal Trend Analysis (Lab23)  
> **Tệp người dùng:** Nhà nghiên cứu & Admin quản trị  
> **Quy chuẩn UI/UX:** [journal-trend-flutter-design](file:///d:/FPT/Semester_8/PRM393/Lab23_JournalTrendAnalysis/.agents/skills/journal-trend-flutter-design/SKILL.md)  
> **Ngày khởi tạo:** 21/07/2026

---

## 🎯 Mục Tiêu Chức Năng

Xây dựng hệ thống phân quyền và giao diện Quản trị (Admin Dashboard) hoàn chỉnh cho ứng dụng Journal Trend Analysis:
1. **Phân quyền người dùng:** Đọc/ghi trường `role` (`"admin"` | `"user"`) và `isBlocked` từ Firestore.
2. **Khu vực Admin riêng biệt:** Tách biệt hoàn toàn khỏi User UI, sử dụng **Amber Gold (`#F59E0B`)** làm accent color chủ đạo.
3. **Quản lý người dùng (Users Management):** Tìm kiếm, lọc, xem chi tiết, và khóa/mở khóa tài khoản realtime.
4. **Thống kê hệ thống (Analytics):** Biểu đồ trực quan bằng `fl_chart` (lượt xem, xuất PDF, top bài báo).
5. **Cấu hình ứng dụng (Remote Config):** Điều chỉnh giới hạn tạp chí (`max_journals_limit`) và từ khóa (`max_keywords_limit`) trực tiếp từ giao diện admin.

---

## 🛠️ Danh Sách Công Việc (Checklist & Tiến Độ)

### 1. Data Layer & Data Models
- [x] **Entity:** Thêm `role` và `isBlocked` vào `UserPreferences` (`lib/features/personalization/domain/entities/user_preferences.dart`).
- [x] **Model:** Cập nhật `UserPreferencesModel` hỗ trợ `fromJson`, `toJson`, `fromEntity` cho Firestore (`lib/features/personalization/data/models/user_preferences_model.dart`).
- [x] **Admin Models:** Tạo `AdminUserModel` và `AppAnalyticsSummary` (`lib/core/firebase/firebase_user_service.dart`).

### 2. Services & Business Logic (Firestore)
- [x] **IFirebaseUserService:** Viết service chuyên biệt xử lý các thao tác admin với Firestore (`lib/core/firebase/firebase_user_service.dart`):
  - `isAdmin(uid)` — kiểm tra quyền admin.
  - `watchAllUsers()` — Stream realtime danh sách tất cả người dùng.
  - `blockUser(uid)` / `unblockUser(uid)` — khóa/mở khóa tài khoản.
  - `getAnalyticsSummary()` — đọc dữ liệu thống kê tổng hợp.
- [x] **AdminUsersCubit:** State management cho tìm kiếm, lọc status (All/Active/Blocked/Admin), và các thao tác khóa user (`lib/features/admin/presentation/blocs/admin_users_cubit.dart`).
- [x] **AdminAnalyticsCubit:** State management cho việc load dữ liệu thống kê hệ thống (`lib/features/admin/presentation/blocs/admin_analytics_cubit.dart`).

### 3. Navigation & Routing (GoRouter)
- [x] **Admin Guard:** Phân quyền tuyến đường `/admin` trong `app_router.dart` — chuyển hướng người dùng không phải admin về `/home`.
- [x] **Admin Shell:** Tạo `AdminShell` với AppBar riêng (badge ADMIN) và Bottom Navigation riêng (`/admin/dashboard`, `/admin/users`, `/admin/analytics`, `/admin/config`).
- [x] **Profile Screen Entry:** Thêm thẻ "Admin Dashboard" trong màn hình `ProfileScreen` (chỉ hiển thị khi `isAdmin == true`).

### 4. Giao Diện Admin (Admin Screens)
- [x] **AdminShell** (`lib/features/admin/presentation/screens/admin_shell.dart`):
  - AppBar chứa badge `ADMIN` màu Amber Gold + nút `← Về ứng dụng`.
  - BottomNavigationBar màu Amber Gold với 4 tab chính.
- [x] **Dashboard Overview** (`lib/features/admin/presentation/screens/admin_dashboard_screen.dart`):
  - Card chào mừng theo thời gian thực + timestamp cập nhật.
  - Stats Grid 2x2: Tổng users, Hoạt động tuần, Lượt xem bài báo, Lượt xuất PDF.
  - Phím tắt chuyển nhanh (Quick Actions).
- [x] **Users Management** (`lib/features/admin/presentation/screens/admin_users_screen.dart`):
  - Thanh tìm kiếm realtime theo tên/email.
  - Filter chips: Tất cả · Đang hoạt động · Bị khóa · Admin.
  - Thẻ người dùng với Popup Menu (Xem chi tiết, Khóa/Mở khóa).
  - Modal ConfirmationDialog trước khi thực hiện hành động khóa tài khoản.
- [x] **Analytics & Data Visualization** (`lib/features/admin/presentation/screens/admin_analytics_screen.dart`):
  - Biểu đồ cột (Bar Chart) `fl_chart` cho tổng quan người dùng và hoạt động hệ thống.
  - Danh sách Top 5 bài báo được xem nhiều nhất với rank badge.
  - Thiết kế tuân thủ tiêu chí: đơn vị rõ ràng, tooltip khi chạm, màu chuẩn ngữ nghĩa.
- [x] **Remote Config** (`lib/features/admin/presentation/screens/admin_config_screen.dart`):
  - Slider điều chỉnh `max_journals_limit` và `max_keywords_limit`.
  - Nút áp dụng cấu hình và kích hoạt `fetchAndActivate()`.

### 5. Dependency Injection & Verification
- [x] Đăng ký `IFirebaseUserService`, `AdminUsersCubit`, `AdminAnalyticsCubit` vào `injection_container.config.dart`.
- [x] Chạy kiểm thử thủ công và kiểm tra biên dịch (`flutter analyze` — No issues found!).

---

## 🎨 Quy Chuẩn Thẩm Mỹ & UX Áp Dụng

1. **Màu sắc phân biệt:**
   - User mode: **Indigo Indigo (`#6366F1`)**
   - Admin mode: **Amber Gold (`#F59E0B`)** + nền card **`#1C1A0E`** + viền **`#44380B`**
2. **Data-first for Researchers:**
   - Mọi số liệu đi kèm đơn vị rõ ràng và tooltip giải thích.
   - Thao tác khóa/mở khóa luôn hỏi xác nhận qua `AlertDialog`.
   - Responsive, có skeleton khi đang tải dữ liệu.

---

## 📌 Hướng Dẫn Thiết Lập Admin Đầu Tiên (Firestore)

Để gán quyền Admin cho một người dùng thử nghiệm trong Firebase Console:
1. Mở **Firebase Console** -> **Firestore Database**.
2. Tìm collection `users` -> chọn document có `UID` của người dùng.
3. Thêm/sửa trường:
   - Trường: `role`
   - Kiểu dữ liệu: `string`
   - Giá trị: `admin`
4. Mở ứng dụng, vào màn hình Profile -> Thẻ **Admin Dashboard** sẽ tự động xuất hiện!
