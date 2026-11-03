# Sổ Thu Chi (SoThuChi) — Ứng dụng Quản lý Tài chính Cá nhân Thông minh

Ứng dụng theo dõi thu chi, đa ví, ngân sách và báo cáo trực quan dành cho người dùng Việt Nam (**Tiếng Việt** mặc định, hỗ trợ **Tiếng Anh**; tiền tệ mặc định **VND** không phần thập phân `1.250.000 ₫`, hỗ trợ chuyển đổi `USD`, `EUR`, `JPY`, `KRW`).

Xây dựng trên một mã nguồn **Flutter** duy nhất cho **Android** và **iOS**, tuân thủ chặt chẽ kiến trúc **Feature-First Clean Architecture**, đồng bộ đám mây ngoại tuyến (**Offline-First Cloud Firestore**), đăng nhập **Google Sign-In v7.x API mới**, khóa sinh trắc học và xuất CSV chuẩn UTF-8 BOM.

---

## 1. Tính năng Phase 1 (MVP)

1. **Splash, Onboarding & Đăng nhập Google (`google_sign_in` v7.x):**
   - 3 màn hình giới thiệu ngắn gọn ở lần mở đầu tiên.
   - Đăng nhập bằng tài khoản Google qua API mới (`GoogleSignIn.instance.initialize()` + `authenticate()` -> Firebase Credential).
   - Duy trì phiên đăng nhập, hỗ trợ **Đăng xuất** và **Xóa vĩnh viễn tài khoản + toàn bộ dữ liệu** (`users/{uid}`, `accounts`, `categories`, `transactions`, `budgets`).
   - Tự động nhận diện khi chưa có cấu hình Firebase trên máy để hiển thị hướng dẫn thiết lập và cho phép dùng thử chế độ Ngoại tuyến cục bộ.
2. **Trang chủ (Home Dashboard):**
   - Thẻ tổng tài sản ròng kèm nút **Ẩn / Hiện số dư** (`•••••• ₫`).
   - Thống kê **Thu nhập vs Chi tiêu** tháng hiện tại, dải ví đang dùng, cảnh báo ngân sách, danh sách giao dịch gần đây và nút thêm nhanh `+`.
3. **Ví & Tài khoản (`cash | bank | ewallet | card`):**
   - Tạo, chỉnh sửa, lưu trữ/khôi phục ví (`archived`), tự động đồng bộ số dư nguyên tử khi phát sinh giao dịch và chuyển khoản nội bộ giữa các ví.
4. **Sổ Giao dịch (`income | expense | transfer`):**
   - Thêm, sửa, **xóa mềm (`deletedAt`) kèm nút Hoàn tác (Undo)**, thao tác vuốt nhanh sang hai bên (`Dismissible`).
   - Tìm kiếm từ khóa theo thời gian thực và lọc đa chiều (khoảng ngày, danh mục, ví, loại giao dịch), gom nhóm theo ngày.
5. **Danh mục Thu Chi:**
   - Tự động khởi tạo 13 danh mục tiếng Việt thân thiện ngay lần đăng nhập đầu tiên (*Ăn uống, Di chuyển, Nhà ở, Hóa đơn & Tiện ích, Mua sắm, Giải trí, Sức khỏe, Giáo dục, Lương, Thưởng, Đầu tư & Lãi, Chi tiêu khác, Thu nhập khác*) + tạo/sửa danh mục tùy chỉnh với bộ chọn biểu tượng & màu sắc.
6. **Ngân sách tháng:**
   - Thiết lập hạn mức tổng thể tháng (`categoryId == null`) hoặc theo từng danh mục chi tiêu, thanh tiến độ và cảnh báo tức thì khi vượt ngưỡng `alertThreshold` (mặc định 80%).
7. **Báo cáo & Phân tích (`fl_chart`):**
   - Bộ chuyển tháng nhanh, tổng hợp Thu – Chi – Chênh lệch ròng – Tỷ lệ tiết kiệm, biểu đồ tròn Donut cơ cấu chi tiêu theo danh mục và biểu đồ cột xu hướng Thu vs Chi 6 tháng gần nhất.
8. **Cài đặt, Bảo mật & Xuất dữ liệu:**
   - Giao diện **Hệ thống / Sáng / Tối** (Material 3, hạt giống màu Ngọc bích `#0D7C66`, chữ số `tabularFigures`), ngôn ngữ (`vi` / `en`), đơn vị tiền tệ.
   - **Khóa ứng dụng sinh trắc học** (`local_auth` + `flutter_secure_storage`) tự khóa khi mở lại từ nền.
   - **Xuất giao dịch ra tệp CSV** có UTF-8 BOM (mở tiếng Việt trên Microsoft Excel / Google Sheets không lỗi dấu) và chia sẻ qua `share_plus`.
9. **Chế độ Ngoại tuyến (Offline-First):**
   - Bật lưu trữ ngoại tuyến không giới hạn cho Cloud Firestore, ghi nhận giao dịch bằng `WriteBatch` + `FieldValue.increment` hoạt động mượt mà khi mất mạng và hiển thị thanh trạng thái Ngoại tuyến / Đang đồng bộ (`OfflineSyncBanner`).

---

## 2. Hướng dẫn Thiết lập Thủ công Firebase & Google Sign-In (Bắt buộc cho Đồng bộ Đám mây)

> **Lưu ý bảo mật:** Dự án **không** lưu trữ khóa bí mật hay tệp cấu hình thật trong Git (`google-services.json`, `GoogleService-Info.plist`, `lib/firebase_options.dart`, `.env*` đều đã được đưa vào `.gitignore`). Các tệp mẫu `*.example` được cung cấp sẵn để tham khảo.

### Bước 1: Tạo Firebase Project, Authentication & Cloud Firestore
1. Truy cập [Firebase Console](https://console.firebase.google.com/) và nhấn **Create a project** (ví dụ: `so-thu-chi-prod`).
2. Vào **Build > Authentication > Get started > Sign-in method**:
   - Bật nhà cung cấp **Google** (*Enable*), nhập **Project support email** và nhấn **Save**.
   - Ghi lại giá trị **Web SDK configuration -> Web client ID** (có dạng `xxx.apps.googleusercontent.com`) nếu bạn muốn truyền qua `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
3. Vào **Build > Firestore Database > Create database**:
   - Chọn khu vực gần Việt Nam nhất (ví dụ: `asia-southeast1` — Singapore), bắt đầu ở chế độ **Production mode**.

### Bước 2: Chạy `flutterfire configure`
Cài đặt Firebase CLI & FlutterFire CLI (nếu chưa có), đăng nhập và sinh tệp cấu hình cho Android + iOS:
```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli

# Chạy tại thư mục gốc của dự án SoThuChiAndroid:
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID> --platforms=android,ios
```
Lệnh trên sẽ tự động tạo:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

*(Sau khi có `lib/firebase_options.dart`, bạn có thể truyền `options: DefaultFirebaseOptions.currentPlatform` vào `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` trong `lib/data/firebase/firebase_providers.dart`).*

### Bước 3: Thêm SHA-1 & SHA-256 cho Android (Bắt buộc để Google Sign-In hoạt động)
1. Lấy chứng chỉ SHA-1 và SHA-256 của debug keystore (và release keystore khi phát hành):
   ```bash
   cd android
   ./gradlew signingReport
   ```
   *(Hoặc dùng `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`).*
2. Mở **Firebase Console > Project Settings > Your apps > Android app (`vn.sothuchi.so_thu_chi`)**:
   - Nhấn **Add fingerprint** và dán lần lượt cả **SHA-1** và **SHA-256**.
   - Tải lại tệp **`google-services.json`** mới nhất và đặt vào `android/app/google-services.json` (build script `android/app/build.gradle.kts` sẽ tự động kích hoạt plugin `com.google.gms.google-services` ngay khi phát hiện tệp này).

### Bước 4: Cấu hình URL Scheme cho iOS (`GoogleService-Info.plist`)
1. Đặt tệp `GoogleService-Info.plist` vào `ios/Runner/GoogleService-Info.plist` thông qua Xcode (*Runner > Add Files to "Runner"*).
2. Mở `ios/Runner/GoogleService-Info.plist`, sao chép giá trị của khóa **`REVERSED_CLIENT_ID`** (ví dụ: `com.googleusercontent.apps.123456789-abcdef`).
3. Thêm đoạn `CFBundleURLTypes` sau vào `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>PASTE_YOUR_REVERSED_CLIENT_ID_HERE</string>
       </array>
     </dict>
   </array>
   ```

### Bước 5: Triển khai Quy tắc Bảo mật & Chỉ mục Firestore
```bash
firebase deploy --only firestore:rules,firestore:indexes --project=<YOUR_FIREBASE_PROJECT_ID>
```

---

## 3. Tổng quan Kiến trúc (Feature-First Clean Architecture)

```text
lib/
  core/
    constants/    # Danh mục tiền tệ (VND/USD/EUR/JPY/KRW), bảng Icon & Màu sắc hằng số
    contracts/    # Hợp đồng mở rộng TransactionDraft & TransactionDraftProducer cho AI tương lai
    errors/       # Sealed Result<T> (Success | Failure) & AppException phân loại rõ ràng
    l10n/         # Tiện ích bản địa hóa thông báo lỗi tiếng Việt/Anh & danh mục mặc định
    router/       # go_router + StatefulShellRoute.indexedStack + Auth/Onboarding redirect guard
    theme/        # Material 3 Light/Dark từ seed #0D7C66 + FinanceColors ThemeExtension
    utils/        # Money (100% int minor units, 0 double), MoneyInputFormatter, AppDateUtils
    widgets/      # AppShellScaffold, BiometricLockGate, OfflineSyncBanner, EmptyStateView, SkeletonBox
  data/
    firebase/     # Riverpod providers bọc toàn bộ Firebase SDK (dễ dàng thay bằng Fake khi test)
    providers/    # Điểm kết nối Dependency Injection giữa Repository Interfaces và Implementations
    services/     # BiometricService, CsvExportService (UTF-8 BOM), SyncStatusService
  features/
    auth/
    accounts/
    categories/
    transactions/
    budgets/
    reports/
    settings/
      data/         # DTOs (freezed + json_serializable), Firestore & In-Memory Repositories
      domain/       # Entities bất biến & Repository INTERFACES thuần Dart
      presentation/ # Màn hình, Widgets nhỏ gọn (const) & Riverpod Controllers
```

### Các nguyên tắc cốt lõi được kiểm chứng tự động bằng Test:
- **Tách biệt tầng tuyệt đối:** `domain/` và `presentation/` chỉ phụ thuộc vào **Repository Interfaces**, không bao giờ import `cloud_firestore`, `firebase_auth` hay `google_sign_in`. Có thể thay thế hoặc bổ sung cơ sở dữ liệu cục bộ (như Drift/SQLite) trong tầng `data/` mà không cần sửa bất kỳ dòng UI nào.
- **Độ chính xác tiền tệ tuyệt đối:** Mọi số tiền được lưu và tính toán bằng số nguyên `int` theo đơn vị nhỏ nhất (`minorUnits`) kèm mã tiền tệ (`currencyCode`). Không bao giờ dùng `double` cho tiền tệ.
- **Sẵn sàng đồng bộ & xử lý xung đột:** Mọi tài liệu Firestore đều có đầy đủ `createdAt`, `updatedAt` và `deletedAt` (xóa mềm).

---

## 4. Cách Thêm Module Tính năng Mới (Ví dụ: Module `lib/features/ai/`)

Ứng dụng đã thiết kế sẵn hợp đồng mở rộng tại `lib/core/contracts/transaction_draft_contract.dart` và khe cắm UI `aiQuickEntrySlotProvider` để bạn thêm tính năng AI nhập liệu tự nhiên (*"ăn phở 50k hôm qua"*), quét hóa đơn OCR hoặc phân loại thông minh **mà không phải sửa các module hiện có**:

1. Tạo thư mục theo chuẩn 3 tầng:
   ```text
   lib/features/ai/
     domain/       # AiParserRepository interface triển khai TransactionDraftProducer
     data/         # Kết nối Gemini API / ML Kit OCR trả về TransactionDraft
     presentation/ # AiQuickEntryCard widget & AiEntryController
   ```
2. Khi người dùng nhập câu tự nhiên hoặc chụp hóa đơn, controller gọi `parseInput(rawText)` để sinh đối tượng `TransactionDraft(amountMinorUnits: 50000, note: 'Ăn phở', kind: TransactionDraftKind.expense, source: 'ai_nlp')`.
3. Điều hướng thẳng tới màn hình tạo giao dịch có sẵn bằng:
   ```dart
   context.push(AppRoutes.transactionNew, extra: draft);
   ```
   `TransactionFormScreen` sẽ tự động điền sẵn số tiền, loại giao dịch, ví, danh mục, ngày và ghi chú để người dùng xác nhận trong 1 chạm!
4. Để hiển thị thanh nhập nhanh AI ngay trên Trang chủ, chỉ cần override `aiQuickEntrySlotProvider` ở `ProviderScope` gốc.

---

## 5. Chạy Phân tích Tĩnh & Kiểm thử (Unit, Widget & Firestore Security Rules)

### Kiểm tra mã nguồn & chạy toàn bộ Unit + Widget Tests (Flutter)
```bash
# Sinh mã nguồn tự động (freezed / json_serializable / gen-l10n) khi cập nhật model hoặc file ARB
flutter gen-l10n
dart run build_runner build

# Phân tích tĩnh toàn bộ dự án (yêu cầu 0 lỗi / 0 cảnh báo)
flutter analyze

# Chạy toàn bộ Unit Tests, Architecture Guardrail Tests & Widget Tests (với Fake providers)
flutter test
```

### Chạy Kiểm thử Quy tắc Bảo mật `firestore.rules` trên Firestore Emulator
*(Yêu cầu cài sẵn Node.js và Java JDK 17+ trên máy):*
```bash
cd test_rules
npm install
npm test
```

### Chạy ứng dụng trên Thiết bị / Máy ảo Android & iOS
```bash
flutter run
```
*(Nếu trên máy Windows/macOS mới cài Android Studio chưa chấp nhận giấy phép SDK hoặc thiếu `cmdline-tools`, mở **Android Studio > Settings > Languages & Frameworks > Android SDK > SDK Tools**, tích chọn **Android SDK Command-line Tools (latest)** rồi chạy `flutter doctor --android-licenses`).*
