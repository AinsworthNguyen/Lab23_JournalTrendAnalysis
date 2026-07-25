---
name: journal-trend-flutter-design
description: Quy chuẩn thiết kế giao diện Flutter cho dự án Journal Trend Analysis. Dành riêng cho tệp người dùng là nhà nghiên cứu — ưu tiên UI clean, UX rõ ràng, và biểu đồ dữ liệu trực quan. Định nghĩa đầy đủ color tokens, typography, spacing, component patterns, data visualization (fl_chart), animation, và Admin Dashboard. Bắt buộc đọc trước khi xây dựng bất kỳ màn hình mới nào.
---

# Journal Trend Analysis — Flutter Design System

> Đây là bộ quy chuẩn bắt buộc cho toàn bộ giao diện Flutter trong dự án.
> Mọi màn hình mới phải tuân thủ tất cả các quy tắc dưới đây.
> **Không được** tự ý dùng màu ngoài bảng màu, font khác, hay shadow style khác.

---

## 0. THIẾT KẾ TỔNG QUAN

### 0.A Bản sắc thiết kế — Ưu tiên Nghiên cứu Viên
Ứng dụng dành cho **các nhà nghiên cứu và học thuật** — người dùng chuyên nghiệp, làm việc với lượng lớn dữ liệu khoa học hàng ngày. Họ cần thông tin **nhanh, chính xác, không nhiễu loạn**.

**Giá trị cốt lõi của UI (theo thứ tự ưu tiên):**
1. **Clarity (Rõ ràng)** — Thông tin nào quan trọng nhất phải nổi bật nhất. Không gây nhầm lẫn.
2. **Efficiency (Hiệu quả)** — Người dùng tìm thấy dữ liệu cần thiết trong ít thao tác nhất.
3. **Trust (Đáng tin cậy)** — UI phải truyền đạt tính khoa học, chính xác — không vui tươi, không hào nhoáng.
4. **Beauty (Thẩm mỹ)** — Đẹp theo kiểu công cụ cao cấp, không phải đẹp theo kiểu game hay social app.

**Nguyên tắc thiết kế đặc thù cho nhà nghiên cứu:**
- **Tránh distraction:** Không animation chạy lúc người dùng đang đọc dữ liệu.
- **Data first:** Biểu đồ và số liệu phải ở vị trí trung tâm — không bị chìm bởi decoration.
- **Label rõ ràng:** Mọi số liệu, trục biểu đồ, và badge đều có label đầy đủ — không để người dùng đoán.
- **Consistent pattern:** Cùng loại dữ liệu phải dùng cùng cách trình bày ở mọi màn hình.
- **Không overload:** Tối đa 3-4 insight chính mỗi màn hình — nhà nghiên cứu cần focus, không cần full dashboard.

**Phong cách:** Premium academic dark — tối, sạch, chính xác, dữ liệu nổi bật.
**Tránh:** Animation quá nhiều khi xem dữ liệu; màu sắc loạn; icon không rõ nghĩa; số liệu không có đơn vị.

### 0.B Hai chế độ giao diện
- **User mode:** Bottom navigation 5 tab (Home, Topics, Journals, Authors, Profile)
- **Admin mode:** Bottom navigation riêng biệt (Dashboard, Users, Analytics, Config, Back to App)

---

## 1. COLOR SYSTEM (Bảng màu — bắt buộc dùng `AppColors`)

Không được hardcode hex color trực tiếp. Luôn dùng qua class `AppColors`.

### 1.A Dark Theme (mặc định)

| Tên Token | Giá trị Hex | Dùng cho |
|---|---|---|
| `AppColors.background` | `#0B0F19` | Nền toàn màn hình (Scaffold) |
| `AppColors.surface` | `#1E293B` | Card, BottomNav, AppBar |
| `AppColors.primary` | `#6366F1` | Nút chính, icon active, highlight |
| `AppColors.secondary` | `#10B981` | Badge thành công, trend tích cực |
| `AppColors.highlight` | `#F43F5E` | Cảnh báo, badge lỗi, xóa |
| `AppColors.textMain` | `#F8FAFC` | Text tiêu đề, nội dung chính |
| `AppColors.textSecondary` | `#94A3B8` | Text phụ, placeholder, hint |
| `AppColors.border` | `#334155` | Viền card, divider, input border |
| `AppColors.glowIndigo` | `#336366F1` | Hào quang/glow nút chính (20% opacity) |
| `AppColors.glowEmerald` | `#3310B981` | Hào quang accent xanh |
| `AppColors.glowRose` | `#33F43F5E` | Hào quang cảnh báo |

### 1.B Admin Accent (màu đặc trưng cho Admin Dashboard)

Dùng màu bổ sung để phân biệt Admin khỏi User UI:

| Tên | Hex | Mục đích |
|---|---|---|
| `adminAccent` | `#F59E0B` | Amber Gold — đặc trưng admin, badge, tiêu đề section |
| `adminSurface` | `#1C1A0E` | Nền tối ấm cho admin card (khác với user surface) |
| `adminBorder` | `#44380B` | Viền card admin |
| `adminGlow` | `#33F59E0B` | Hào quang amber |

**Nguyên tắc màu Admin:**
- Admin dashboard sẽ dùng **Amber Gold** làm accent thay vì Indigo — giúp người dùng ngay lập tức nhận ra mình đang ở khu vực quản trị.
- Nền Scaffold vẫn là `AppColors.background` — không thay đổi toàn bộ palette, chỉ thay accent.
- Badge "ADMIN" trên avatar dùng `adminAccent` với nền `adminSurface`.

### 1.C Quy tắc màu bắt buộc

- **Không bao giờ** dùng màu trắng thuần `Colors.white` cho text trên nền dark — dùng `AppColors.textMain`.
- **Không bao giờ** dùng `Colors.black` cho bất cứ thứ gì.
- Opacity overlay trên ảnh: `Colors.black.withValues(alpha: 0.6)` — không bao giờ dùng `withOpacity`.
- Gradient primary direction: luôn từ `primary` → `secondary` (indigo → emerald), hoặc `primary` (indigo đơn sắc với opacity gradient).

---

## 2. TYPOGRAPHY SYSTEM

### 2.A Font Family

| Font | Dùng cho |
|---|---|
| **Outfit** (via `GoogleFonts.outfit`) | Tất cả tiêu đề (Display, Headline, Title) |
| **Inter** (via `GoogleFonts.inter`) | Tất cả body text, caption, label |

Không dùng font khác. Tham chiếu qua `AppTheme.darkTheme.textTheme`.

### 2.B Text Scale (ThemeData TextTheme)

| Style | Font Size | Weight | Dùng cho |
|---|---|---|---|
| `displayLarge` | 32sp | W700 | Tiêu đề màn hình lớn |
| `displayMedium` | 28sp, h:1.2 | W700 | Tiêu đề section |
| `displaySmall` | 24sp | W600 | Phụ tiêu đề section |
| `headlineMedium` | 20sp, h:1.3 | W600 | Card title, AppBar title |
| `titleMedium` | 16sp, h:1.4 | W600 | Item title, button label |
| `bodyLarge` | 15sp, h:1.6 | W400 | Nội dung chính, description |
| `bodyMedium` | 12sp, h:1.4 | W400 | Caption, metadata, timestamp |

### 2.C Quy tắc Typography bắt buộc

- `TextOverflow.ellipsis` bắt buộc cho mọi text có thể tràn dòng — không để text vỡ layout.
- Tiêu đề Card: max 2 dòng (`maxLines: 2`).
- Caption/metadata: max 1 dòng (`maxLines: 1`).
- Không dùng `fontSize` hardcode trực tiếp — luôn dùng qua `Theme.of(context).textTheme.*`.

---

## 3. SPACING & LAYOUT SYSTEM

### 3.A Khoảng cách chuẩn

```dart
// Sử dụng các giá trị này — không hardcode số khác
const double kSpaceXS = 4.0;
const double kSpaceSM = 8.0;
const double kSpaceMD = 12.0;
const double kSpaceLG = 16.0;
const double kSpaceXL = 20.0;
const double kSpace2XL = 24.0;
const double kSpace3XL = 32.0;
const double kSpace4XL = 48.0;
```

Nếu chưa có file constants, dùng giá trị tương ứng trong SizedBox/EdgeInsets.

### 3.B Border Radius chuẩn

| Dùng cho | Radius |
|---|---|
| Card thông thường | `BorderRadius.circular(20)` |
| Chip/Badge nhỏ | `BorderRadius.circular(12)` |
| Input field | `BorderRadius.circular(12)` |
| Button | `BorderRadius.circular(12)` |
| Avatar | `BorderRadius.circular(24)` (hoặc CircleAvatar) |
| Bottom Sheet | `BorderRadius.vertical(top: Radius.circular(24))` |

Không dùng `BorderRadius.circular(0)` trừ khi có lý do đặc biệt.

### 3.C Padding chuẩn cho màn hình

```dart
// Padding toàn màn hình
padding: const EdgeInsets.all(16.0)

// Padding AppBar
padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)

// Padding Card nội dung
padding: const EdgeInsets.all(20.0)

// Padding Bottom Navigation — luôn thêm SafeArea
```

### 3.D Card Design chuẩn

```dart
Card(
  color: AppColors.surface,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: BorderSide(
      color: AppColors.border.withValues(alpha: 0.3),
      width: 1.0,
    ),
  ),
  child: ...,
)
```

Không dùng Card với `elevation > 0` trên nền dark — dùng border thay vì shadow.

---

## 4. COMPONENT PATTERNS

### 4.A AppBar chuẩn

```dart
AppBar(
  backgroundColor: AppColors.background,
  elevation: 0,
  scrolledUnderElevation: 0,
  title: Text(
    'Tiêu đề',
    style: Theme.of(context).textTheme.headlineMedium,
  ),
  actions: [/* icons */],
)
```

Không dùng AppBar có nền màu khác `AppColors.background`.

### 4.B Bottom Navigation chuẩn

```dart
BottomNavigationBar(
  backgroundColor: AppColors.surface,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textSecondary,
  type: BottomNavigationBarType.fixed,
  // ...
)
```

**Admin Bottom Navigation dùng:**
```dart
selectedItemColor: adminAccentColor, // Amber Gold
```

### 4.C Button chuẩn

**Primary Button:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

**Admin Action Button (dùng Amber):**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFF59E0B),
    foregroundColor: const Color(0xFF0B0F19),
    // ...
  ),
)
```

**Destructive Button (xóa, khóa):**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.highlight,
    foregroundColor: Colors.white,
    // ...
  ),
)
```

### 4.D Loading State chuẩn

```dart
// Skeleton loader — KHÔNG dùng CircularProgressIndicator đơn độc
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    color: AppColors.surface,
  ),
  // Thêm shimmer effect nếu có thư viện shimmer
)

// Loading overlay toàn màn hình
Center(
  child: CircularProgressIndicator(
    color: AppColors.primary,
    strokeWidth: 2.0,
  ),
)
```

### 4.E Empty State chuẩn

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.*, size: 64, color: AppColors.textSecondary),
    const SizedBox(height: 16),
    Text('Chưa có dữ liệu', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 8),
    Text('Mô tả thêm', style: Theme.of(context).textTheme.bodyMedium),
  ],
)
```

### 4.F Admin Stat Card chuẩn

```dart
// Card thống kê 2x2 grid
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: const Color(0xFF1C1A0E),  // adminSurface
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color(0xFF44380B),  // adminBorder
      width: 1.0,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.*, color: Color(0xFFF59E0B), size: 28),  // adminAccent
      const SizedBox(height: 12),
      Text(value, style: textTheme.displaySmall?.copyWith(
        color: Color(0xFFF59E0B),
        fontWeight: FontWeight.w700,
      )),
      Text(label, style: textTheme.bodyMedium),
    ],
  ),
)
```

---

## 5. ANIMATION & MICRO-INTERACTION GUIDELINES

### 5.A Nguyên tắc Animation

- **Có lý do:** Mỗi animation phải truyền đạt trạng thái (loading, success, error) hoặc hướng dẫn sự chú ý.
- **Không phô trương:** Thời lượng animation mặc định `300ms` — không kéo dài hơn `500ms`.
- **Easing chuẩn:** `Curves.easeInOut` cho các transition thông thường; `Curves.elasticOut` cho pop-in confirmation.
- **Không animation vòng lặp vô tận** trừ loading spinner và skeleton.

### 5.B Transition giữa màn hình

```dart
// Route transition chuẩn
PageRouteBuilder(
  transitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, __, ___) => TargetScreen(),
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: child,
      ),
    );
  },
)
```

### 5.C Hero Animation cho Chi tiết

```dart
// List item → Detail screen
Hero(
  tag: 'publication-${item.id}',
  child: /* image hoặc icon */,
)
```

### 5.D AnimatedSwitcher cho State Changes

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: isLoading
      ? const LoadingWidget(key: ValueKey('loading'))
      : ContentWidget(key: ValueKey('content')),
)
```

---

## 6. ADMIN DASHBOARD — NGUYÊN TẮC THIẾT KẾ

### 6.A Nguyên tắc phân biệt Admin vs User UI

1. **Amber Gold accent** thay thế Indigo trên toàn bộ Admin UI.
2. Thêm **badge "ADMIN"** màu amber ở góc trên màn hình đầu tiên sau đăng nhập.
3. AppBar Admin có subtitle "Admin Dashboard" với font nhỏ hơn màu amber.
4. Mọi action nguy hiểm (khóa tài khoản, xóa) phải có **ConfirmationDialog** trước khi thực hiện.

### 6.B Cấu trúc Admin Dashboard

```
AdminShell (MaterialApp riêng hoặc Navigator riêng)
├── AdminDashboardScreen (tổng quan)
├── AdminUsersScreen (quản lý người dùng)
├── AdminAnalyticsScreen (thống kê hệ thống)
└── AdminConfigScreen (cấu hình Remote Config)
```

### 6.C Admin Stats Grid

Sắp xếp 2x2 grid cho các chỉ số chính:
- Tổng số người dùng
- Người dùng đang hoạt động (tuần này)
- Bài báo được xem nhiều nhất (top 1)
- Số lượt xuất PDF

### 6.D User Management Table

Dùng `ListView.separated` thay vì DataTable cho mobile — mỗi item là một Card với:
- Avatar + tên + email (trái)
- Badge trạng thái: `active` (emerald) / `blocked` (rose) (phải)
- Trailing: `IconButton` menu (xem, khóa, mở khóa)

### 6.E Confirmation Dialog chuẩn cho Admin

```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    title: Row(children: [
      Icon(Icons.warning_amber_rounded, color: AppColors.highlight),
      SizedBox(width: 8),
      Text('Xác nhận', style: textTheme.titleMedium),
    ]),
    content: Text('Bạn có chắc muốn [hành động]?'),
    actions: [
      TextButton(
        child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
        onPressed: () => Navigator.pop(context),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.highlight),
        child: Text('Xác nhận'),
        onPressed: () { /* thực hiện */ Navigator.pop(context); },
      ),
    ],
  ),
)
```

---

## 7. FIRESTORE DATA CONVENTION (cho Admin)

### 7.A User Document Structure

```
Firestore: users/{uid}
{
  "fullName": "...",
  "email": "...",
  "photoUrl": "...",
  "role": "user" | "admin",          // MỚI — phân quyền
  "isBlocked": false,                 // MỚI — admin có thể khóa
  "interestConceptId": "...",
  "interestConceptName": "...",
  "createdAt": Timestamp,
  "lastActiveAt": Timestamp,
  "pdfExportCount": 0,
  "viewCount": 0,
}
```

### 7.B Cách kiểm tra quyền Admin trong ứng dụng

```dart
// Trong Auth/User service
Future<bool> isAdmin(String uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  return doc.data()?['role'] == 'admin';
}
```

### 7.C Analytics Collection (cho Admin Dashboard)

```
Firestore: app_analytics/summary
{
  "totalUsers": 0,
  "activeUsersThisWeek": 0,
  "totalPdfExports": 0,
  "topPublications": [...],
  "lastUpdated": Timestamp
}
```

---

## 8. DATA VISUALIZATION & CHART STANDARDS

> Biểu đồ là ngôn ngữ chính của nhà nghiên cứu. Mỗi chart phải trả lời **đúng một câu hỏi** và trả lời nó thật rõ ràng.

### 8.A Thư viện biểu đồ

**Bắt buộc dùng `fl_chart`** (đã có trong dự án). Không dùng thư viện khác.

```yaml
# pubspec.yaml — đảm bảo có:
fl_chart: ^0.68.0  # hoặc version đang dùng
```

### 8.B Bảng màu biểu đồ (Chart Color Palette)

Dùng đúng bộ màu này — đủ tương phản trên nền dark, có ý nghĩa ngữ nghĩa:

```dart
// Dùng trong order 1→2→3→4→5 khi có nhiều series
const chartColors = [
  Color(0xFF6366F1),  // [1] Indigo — primary metric, trend chính
  Color(0xFF10B981),  // [2] Emerald — growth, positive change
  Color(0xFFF59E0B),  // [3] Amber — secondary metric, highlight
  Color(0xFFF43F5E),  // [4] Rose — warning, negative, comparison
  Color(0xFF64748B),  // [5] Slate — baseline, reference, average
];

// Grid lines và axes
const chartGridColor = Color(0x1A334155);  // border với 10% opacity
const chartAxisColor = Color(0xFF334155);   // border thuần
const chartLabelColor = Color(0xFF94A3B8); // textSecondary
```

**Quy tắc màu biểu đồ:**
- Series đầu tiên LUÔN là `Indigo` (primary metric).
- Series "so sánh/tham chiếu" LUÔN là `Slate` (màu xám trung tính).
- Màu `Rose` chỉ dùng cho giá trị âm, giảm, hoặc cảnh báo.
- Không dùng quá 4 màu trong cùng 1 biểu đồ — quá nhiều màu gây nhiễu.

### 8.C Loại biểu đồ và khi nào dùng

| Loại biểu đồ | fl_chart class | Dùng cho | Không dùng cho |
|---|---|---|---|
| **Line Chart** | `LineChart` | Xu hướng theo thời gian (số bài báo qua các năm) | So sánh nhiều danh mục |
| **Bar Chart** | `BarChart` | So sánh số lượng giữa các danh mục (top journals, top topics) | Xu hướng chuỗi thời gian dài |
| **Pie/Donut** | `PieChart` | Tỷ lệ phần trăm (≤ 5 phần) | Xu hướng, so sánh tuyệt đối |
| **Scatter** | `ScatterChart` | Tương quan giữa 2 biến số | Đơn độc — chỉ dùng khi có đủ data points |

**Quy tắc chọn biểu đồ:**
- Câu hỏi "Xu hướng theo thời gian?" → **Line Chart**
- Câu hỏi "Cái nào nhiều/ít nhất?" → **Bar Chart** (horizontal nếu label dài)
- Câu hỏi "Chiếm bao nhiêu %?" → **Pie/Donut** (≤ 5 phần, nếu > 5 dùng Bar)
- Không bao giờ dùng 3D chart — gây nhầm lẫn tỉ lệ.

### 8.D Line Chart chuẩn (xu hướng theo năm)

```dart
LineChart(
  LineChartData(
    // Grid — nhạt, không gây nhiễu
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false, // chỉ horizontal grid
      horizontalInterval: /* tự tính từ data range */,
      getDrawingHorizontalLine: (_) => FlLine(
        color: const Color(0x1A334155),
        strokeWidth: 1,
      ),
    ),
    // Titles — rõ ràng, đủ label
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (value, meta) => Text(
            _formatNumber(value.toInt()), // luôn format số (1K, 2.5K)
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(), // năm
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    // Border — chỉ bottom và left axis
    borderData: FlBorderData(
      show: true,
      border: const Border(
        left: BorderSide(color: Color(0xFF334155)),
        bottom: BorderSide(color: Color(0xFF334155)),
      ),
    ),
    // Line
    lineBarsData: [
      LineChartBarData(
        spots: dataSpots,
        isCurved: true,           // đường cong mượt mà hơn
        curveSmoothness: 0.3,
        color: const Color(0xFF6366F1),
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false), // ẩn dot mặc định
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.2),
              const Color(0xFF6366F1).withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    ],
    // Tooltip khi chạm vào
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => const Color(0xFF1E293B),
        tooltipBorder: const BorderSide(color: Color(0xFF6366F1), width: 1),
        getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
          return LineTooltipItem(
            '${spot.x.toInt()}: ${_formatNumber(spot.y.toInt())} bài báo',
            const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13),
          );
        }).toList(),
      ),
    ),
  ),
)
```

### 8.E Bar Chart chuẩn (so sánh top N)

```dart
// Horizontal bar chart — tốt hơn cho label dài (tên journal, tên topic)
BarChart(
  BarChartData(
    alignment: BarChartAlignment.spaceAround,
    maxY: maxValue * 1.2, // thêm 20% khoảng trên để label không bị cắt
    barGroups: data.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.count.toDouble(),
            color: const Color(0xFF6366F1),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList(),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final label = data[value.toInt()].shortName; // tên rút gọn
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    ),
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => const FlLine(
        color: Color(0x1A334155),
        strokeWidth: 1,
      ),
    ),
    borderData: FlBorderData(show: false),
  ),
)
```

### 8.F Pie/Donut Chart chuẩn (tỉ lệ)

```dart
PieChart(
  PieChartData(
    centerSpaceRadius: 48, // donut — không dùng pie đặc
    sectionsSpace: 2,
    sections: data.asMap().entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.percentage,
        color: chartColors[entry.key % chartColors.length],
        radius: 60,
        title: '${entry.value.percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList(),
  ),
)
// LUÔN đi kèm legend bên dưới
```

### 8.G Quy tắc UX cho biểu đồ

**Bắt buộc:**
- **Tiêu đề biểu đồ:** Mỗi biểu đồ phải có tiêu đề rõ ràng phía trên, dùng `textTheme.titleMedium`. Ví dụ: "Xu hướng số bài báo theo năm" — không để biểu đồ không có tiêu đề.
- **Đơn vị:** Nếu trục Y là số bài báo, ghi "(bài báo)" hoặc format tooltip đầy đủ. Nếu là %, ghi "%".
- **Tooltip khi chạm:** Tất cả biểu đồ đều phải có `touchData` để hiện tooltip khi người dùng chạm vào điểm dữ liệu.
- **Legend:** Nếu có ≥ 2 series, bắt buộc có legend chú thích. Đặt phía dưới hoặc bên phải biểu đồ.
- **Loading state:** Khi đang tải data, hiện skeleton placeholder có cùng chiều cao với biểu đồ thực.
- **Empty state:** Nếu không có data, hiện empty state với message giải thích (ví dụ: "Chưa có dữ liệu cho giai đoạn này").

**Cấm:**
- **Không dùng biểu đồ khi chỉ có 1-2 data points** — dùng số liệu text thay vì biểu đồ.
- **Không để trục Y bắt đầu từ giá trị tùy ý** — luôn từ 0, trừ khi có lý do rõ ràng và ghi chú rõ.
- **Không dùng màu ngẫu nhiên** — luôn dùng `chartColors` theo thứ tự.
- **Không để nhãn bị cắt** — tính toán `reservedSize` đủ lớn cho label.
- **Không nhồi quá nhiều biểu đồ** — tối đa 2 biểu đồ mỗi màn hình, cách nhau ít nhất `24px`.

### 8.H Wrapper Chart chuẩn

Mọi biểu đồ phải được bọc trong wrapper này:

```dart
Widget _buildChartCard({
  required String title,
  String? subtitle,
  required Widget chart,
  double height = 220,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.border.withValues(alpha: 0.3),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        SizedBox(height: height, child: chart),
      ],
    ),
  );
}
```

---

## 9. UX CLARITY RULES (Cho Nhà Nghiên Cứu)

### 9.A Information Hierarchy — Thứ tự ưu tiên thông tin

Mỗi màn hình phải có **cấu trúc thông tin 3 lớp rõ ràng**:
1. **Hero metric / Primary insight** — Số liệu quan trọng nhất, font lớn, nhìn thấy ngay.
2. **Supporting data** — Bảng, list, hoặc biểu đồ bổ trợ cho metric chính.
3. **Contextual details** — Nguồn dữ liệu, timestamp, link đến chi tiết.

### 9.B Số liệu cần có context

Số đứng một mình không có nghĩa với nhà nghiên cứu. Luôn đi kèm:

```dart
// Sai — chỉ có số
Text('1,234')

// Đúng — có label + trend + unit
Column(children: [
  Text('1,234', style: /* displaySmall */),
  Row(children: [
    Icon(Icons.trending_up, color: AppColors.secondary, size: 14),
    Text('+12% so với tháng trước', style: /* bodyMedium */),
  ]),
  Text('bài báo được xem', style: /* bodyMedium secondary */),
])
```

### 9.C Search & Filter — Phải nhanh và rõ

- Search bar luôn ở trên cùng, không ẩn sau menu.
- Filter chip hiển thị inline (horizontal scroll), không ẩn trong dropdown khi có ≤ 5 options.
- Kết quả filter phải cập nhật realtime hoặc có progress indicator rõ ràng.
- Khi không có kết quả: hiện empty state với gợi ý mở rộng tìm kiếm.

### 9.D List Item cho Bài báo / Journal

Cấu trúc chuẩn cho một item trong danh sách học thuật:

```
[Year badge] Tiêu đề bài báo (maxLines: 2)
             Tên tạp chí • Số trích dẫn • Năm
             [Keywords chips — max 3]
```

- Năm phải nổi bật (badge màu primary mờ).
- Số trích dẫn là metric quan trọng — không để nhỏ hoặc ẩn.
- Tên tác giả: nếu nhiều → hiện 2 tên + "và X khác".

### 9.E Tooltip và Label — Không để người dùng đoán

- Icon không phổ biến (ít hơn Google Material icons chuẩn) **bắt buộc** có `Tooltip`.
- Số viết tắt (1K, 2.4M) bắt buộc có tooltip hiện số đầy đủ khi chạm.
- Tên tạp chí dài bị truncate bắt buộc có thể expand hoặc xem full tên khi chạm.

---

## 10. PRE-FLIGHT CHECKLIST (Kiểm tra trước khi ship màn hình mới)

Trước khi hoàn thành bất kỳ màn hình nào, kiểm tra toàn bộ danh sách sau:

**UI Cơ bản:**
- [ ] **Color:** Không có hex hardcode nào ngoài file `AppColors`. Tất cả màu đều từ bảng màu.
- [ ] **Typography:** Tất cả Text đều dùng `textTheme.*` từ Theme. Không có `fontSize` hardcode.
- [ ] **Overflow:** Mọi Text có thể tràn đều có `overflow: TextOverflow.ellipsis` và `maxLines`.
- [ ] **SafeArea:** Wrap toàn bộ Scaffold content với SafeArea.

**States (Bắt buộc đủ 3):**
- [ ] **Loading state:** Skeleton hoặc spinner khi đang tải.
- [ ] **Empty state:** UI rõ ràng khi không có dữ liệu.
- [ ] **Error state:** SnackBar hoặc inline error khi gặp lỗi.

**UX Clarity (Cho nhà nghiên cứu):**
- [ ] **Information hierarchy:** Metric quan trọng nhất dễ nhìn thấy nhất.
- [ ] **Số liệu có context:** Mọi con số đều có label, đơn vị, và trend (nếu có).
- [ ] **Tooltip đầy đủ:** Icon ít phổ biến và số viết tắt có Tooltip.
- [ ] **Filter/Search:** Filter chips hiển thị inline, kết quả cập nhật rõ ràng.

**Data Visualization:**
- [ ] **Tiêu đề biểu đồ:** Mỗi chart có tiêu đề rõ ràng phía trên.
- [ ] **Đơn vị trục:** Trục Y và tooltip có đơn vị đầy đủ.
- [ ] **Tooltip chart:** Tất cả chart có touchData/tooltip khi chạm.
- [ ] **Legend:** Chart có ≥ 2 series phải có legend chú thích.
- [ ] **Màu biểu đồ:** Dùng `chartColors` theo thứ tự — không dùng màu ngẫu nhiên.
- [ ] **Chart wrapper:** Tất cả chart bọc trong `_buildChartCard()` pattern.
- [ ] **Không quá 2 chart/màn hình.**

**Admin (chỉ áp dụng cho màn hình Admin):**
- [ ] **Role check:** Có guard kiểm tra `role == 'admin'` trước khi render.
- [ ] **ConfirmationDialog:** Mọi hành động nguy hiểm có dialog xác nhận.
- [ ] **Amber accent:** Admin UI dùng màu Amber, không phải Indigo.
- [ ] **Navigation:** Admin navigation tách biệt hoàn toàn khỏi User navigation.
