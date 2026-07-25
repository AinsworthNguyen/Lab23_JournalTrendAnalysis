# Hướng dẫn Cấu hình & Sử dụng SonarQube Scanner cho Journal Trend Analysis (Flutter)

Tài liệu này hướng dẫn cách quét và phân tích chất lượng mã nguồn (Code Quality), Code Smells, Bugs, Security Hotspots và Độ bao phủ kiểm thử (Test Coverage) cho ứng dụng Flutter này bằng SonarQube.

---

## 1. Tổng quan các File Cấu hình đã được Tạo

- **`sonar-project.properties`**: File cấu hình chính của SonarQube Scanner.
- **`run_sonar_analysis.ps1`**: Script PowerShell tự động chạy test coverage và kích hoạt SonarScanner trên Windows.
- **`run_sonar_analysis.sh`**: Script Bash cho macOS/Linux.
- **`.github/workflows/sonarqube.yml`**: Cấu hình tự động quét chất lượng code trên GitHub Actions.

---

## 2. Hướng dẫn Chạy SonarQube Server Cục bộ (Local) bằng Docker

Nếu bạn chưa có máy chủ SonarQube tập trung, bạn có thể dễ dàng khởi chạy một instance SonarQube Community Edition bằng Docker:

```bash
docker run -d --name sonarqube \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -p 9000:9000 \
  sonarqube:lts-community
```

- Mở trình duyệt và truy cập: **`http://localhost:9000`**
- Tài khoản mặc định:
  - **Username**: `admin`
  - **Password**: `admin` (Hệ thống sẽ yêu cầu đổi mật khẩu ở lần đăng nhập đầu tiên).

### Tạo Access Token trên SonarQube:
1. Vào **User Profile** (Góc trên bên phải) -> chọn **Account** -> chọn tab **Security**.
2. Tại mục **Generate Token**, đặt tên token (ví dụ: `flutter-local`), chọn Type là **Global Analysis Token** hoặc **User Token**, sau đó bấm **Generate**.
3. Lưu lại mã Token vừa tạo.

---

## 3. Hướng dẫn Chạy Quét Code Quality trên Máy Cục bộ

### Bước 1: Tạo báo cáo Test Coverage (`lcov.info`)

Chạy lệnh sau tại thư mục dự án Flutter (`Lab23_JournalTrendAnalysis`):

```bash
flutter test --coverage
```
Lệnh này sẽ tạo file báo cáo độ bao phủ tại: `coverage/lcov.info`.

### Bước 2: Chạy SonarScanner

#### Cách A: Chạy bằng Command Prompt (cmd.exe)
```cmd
run_sonar_analysis.bat "http://localhost:9000" "<YOUR_SONAR_TOKEN>"
```

#### Cách B: Chạy bằng PowerShell
```powershell
.\run_sonar_analysis.ps1 -HostUrl "http://localhost:9000" -Token "<YOUR_SONAR_TOKEN>"
```

#### Cách C: Chạy trực tiếp qua lệnh `sonar-scanner`
```bash
sonar-scanner -Dsonar.host.url=http://localhost:9000 -Dsonar.token=<YOUR_SONAR_TOKEN>
```
*(Nếu SonarQube của bạn cho phép quét không cần token hoặc cấu hình trong server, bạn chỉ cần chạy `sonar-scanner`)*

---

## 4. Tích hợp SonarQube với CI/CD (GitHub Actions)

Trong repository đã được tạo sẵn workflow `.github/workflows/sonarqube.yml`. Để sử dụng trên GitHub:

1. Vào repository trên GitHub -> **Settings** -> **Secrets and variables** -> **Actions**.
2. Thêm 2 Secrets:
   - `SONAR_HOST_URL`: URL máy chủ SonarQube (ví dụ: `https://sonar.yourdomain.com` hoặc SonarCloud `https://sonarcloud.io`).
   - `SONAR_TOKEN`: Token dùng để xác thực với SonarQube.

---

## 5. Danh mục Quy tắc Exclude trong `sonar-project.properties`

Để đảm bảo kết quả đánh giá khách quan và chính xác, các file sinh tự động và mã nguồn nền tảng gốc đã được loại trừ khỏi quá trình quét:

- **File được tạo tự động**: `**/*.g.dart`, `**/*.freezed.dart`, `lib/generated/**`
- **Mã nguồn Platform**: `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`
- **Thư mục build & tool**: `build/`, `.dart_tool/`
