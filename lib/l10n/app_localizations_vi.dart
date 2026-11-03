// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Sổ Thu Chi';

  @override
  String get appTagline => 'Quản lý tài chính cá nhân thông minh & tinh gọn';

  @override
  String get navOverview => 'Tổng quan';

  @override
  String get navTransactions => 'Giao dịch';

  @override
  String get navBudgets => 'Ngân sách';

  @override
  String get navReports => 'Báo cáo';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get onboardingNext => 'Tiếp tục';

  @override
  String get onboardingStart => 'Bắt đầu ngay';

  @override
  String get onboarding1Title => 'Ghi chép thu chi trong 3 giây';

  @override
  String get onboarding1Subtitle =>
      'Theo dõi mọi khoản thu nhập, chi tiêu và chuyển khoản với định dạng tiền Việt rõ ràng, chính xác đến từng đồng.';

  @override
  String get onboarding2Title => 'Quản lý đa ví & ngân sách chủ động';

  @override
  String get onboarding2Subtitle =>
      'Quản lý tiền mặt, tài khoản ngân hàng, ví điện tử và nhận cảnh báo sớm trước khi vượt ngân sách tháng.';

  @override
  String get onboarding3Title => 'Làm việc ngoại tuyến, đồng bộ tức thì';

  @override
  String get onboarding3Subtitle =>
      'Ghi chép ngay cả khi không có mạng. Dữ liệu được bảo mật riêng tư và tự động đồng bộ lên đám mây khi kết nối lại.';

  @override
  String get signInTitle => 'Chào mừng đến với Sổ Thu Chi';

  @override
  String get signInSubtitle =>
      'Đăng nhập bằng tài khoản Google để đồng bộ dữ liệu an toàn giữa các thiết bị của bạn.';

  @override
  String get signInWithGoogle => 'Đăng nhập với Google';

  @override
  String get tryOfflineDemo =>
      'Dùng thử chế độ Ngoại tuyến (Chưa cấu hình Firebase)';

  @override
  String get firebaseUnconfiguredBanner =>
      'Chưa tìm thấy cấu hình Firebase trên thiết bị. Bạn có thể xem hướng dẫn thiết lập hoặc trải nghiệm toàn bộ tính năng ở chế độ cục bộ.';

  @override
  String get viewSetupGuide => 'Xem hướng dẫn cấu hình';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get signOutConfirmTitle => 'Đăng xuất tài khoản?';

  @override
  String get signOutConfirmBody =>
      'Bạn có thể đăng nhập lại bất cứ lúc nào để tiếp tục đồng bộ dữ liệu.';

  @override
  String get deleteAccount => 'Xóa tài khoản & toàn bộ dữ liệu';

  @override
  String get deleteAccountConfirmTitle => 'Xóa vĩnh viễn tài khoản?';

  @override
  String get deleteAccountConfirmBody =>
      'Toàn bộ ví, danh mục, giao dịch, ngân sách và hồ sơ của bạn sẽ bị xóa vĩnh viễn và không thể khôi phục.';

  @override
  String get deleteAccountAction => 'Xóa vĩnh viễn';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get delete => 'Xóa';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get close => 'Đóng';

  @override
  String get retry => 'Thử lại';

  @override
  String get all => 'Tất cả';

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get totalBalance => 'Tổng tài sản ròng';

  @override
  String get showBalance => 'Hiện số dư';

  @override
  String get hideBalance => 'Ẩn số dư';

  @override
  String get thisMonthSummary => 'Tháng này';

  @override
  String get income => 'Thu nhập';

  @override
  String get expense => 'Chi tiêu';

  @override
  String get transfer => 'Chuyển khoản';

  @override
  String get netBalance => 'Chênh lệch ròng';

  @override
  String get recentTransactions => 'Giao dịch gần đây';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get quickAddTransaction => 'Thêm giao dịch';

  @override
  String get walletsTitle => 'Ví & Tài khoản';

  @override
  String get manageWallets => 'Quản lý ví';

  @override
  String get addWallet => 'Thêm ví mới';

  @override
  String get editWallet => 'Chỉnh sửa ví';

  @override
  String get walletName => 'Tên ví';

  @override
  String get walletNameHint => 'VD: Tiền mặt, Vietcombank, MoMo...';

  @override
  String get walletType => 'Loại tài khoản';

  @override
  String get walletTypeCash => 'Tiền mặt';

  @override
  String get walletTypeBank => 'Ngân hàng';

  @override
  String get walletTypeEwallet => 'Ví điện tử';

  @override
  String get walletTypeCard => 'Thẻ tín dụng / ghi nợ';

  @override
  String get initialBalance => 'Số dư ban đầu';

  @override
  String get currentBalance => 'Số dư hiện tại';

  @override
  String get archiveWallet => 'Lưu trữ ví';

  @override
  String get unarchiveWallet => 'Khôi phục ví';

  @override
  String get archivedWallets => 'Ví đã lưu trữ';

  @override
  String get activeWallets => 'Ví đang sử dụng';

  @override
  String get transferBetweenWallets => 'Chuyển tiền giữa các ví';

  @override
  String get fromWallet => 'Từ ví nguồn';

  @override
  String get toWallet => 'Đến ví đích';

  @override
  String get emptyWalletsTitle => 'Chưa có ví nào';

  @override
  String get emptyWalletsSubtitle =>
      'Tạo ví đầu tiên để bắt đầu theo dõi dòng tiền hàng ngày.';

  @override
  String get categoriesTitle => 'Danh mục thu chi';

  @override
  String get manageCategories => 'Quản lý danh mục';

  @override
  String get addCategory => 'Thêm danh mục';

  @override
  String get editCategory => 'Sửa danh mục';

  @override
  String get categoryName => 'Tên danh mục';

  @override
  String get categoryNameHint => 'VD: Cà phê, Xăng xe, Tiền nhà...';

  @override
  String get defaultCategoryBadge => 'Mặc định';

  @override
  String get selectIcon => 'Chọn biểu tượng';

  @override
  String get selectColor => 'Chọn màu sắc';

  @override
  String get transactionsTitle => 'Sổ giao dịch';

  @override
  String get addTransaction => 'Ghi giao dịch';

  @override
  String get editTransaction => 'Sửa giao dịch';

  @override
  String get transactionDeleted => 'Đã xóa giao dịch';

  @override
  String get amount => 'Số tiền';

  @override
  String get amountRequiredError => 'Vui lòng nhập số tiền lớn hơn 0';

  @override
  String get selectCategory => 'Chọn danh mục';

  @override
  String get categoryRequiredError => 'Vui lòng chọn danh mục';

  @override
  String get walletRequiredError => 'Vui lòng chọn ví';

  @override
  String get sameWalletTransferError => 'Ví nguồn và ví đích phải khác nhau';

  @override
  String get date => 'Ngày giao dịch';

  @override
  String get note => 'Ghi chú';

  @override
  String get noteHint => 'Thêm mô tả ngắn (VD: Ăn trưa cùng đồng nghiệp)...';

  @override
  String get tags => 'Thẻ (phân cách bằng dấu phẩy)';

  @override
  String get tagsHint => 'VD: công tác, gia đình';

  @override
  String get searchTransactionsHint => 'Tìm theo ghi chú hoặc thẻ...';

  @override
  String get filterTransactions => 'Bộ lọc giao dịch';

  @override
  String get clearFilters => 'Xóa bộ lọc';

  @override
  String get dateRange => 'Khoảng thời gian';

  @override
  String get selectDateRange => 'Chọn khoảng ngày';

  @override
  String get emptyTransactionsTitle => 'Chưa có giao dịch nào';

  @override
  String get emptyTransactionsSubtitle =>
      'Nhấn nút + để ghi khoản thu hoặc chi đầu tiên của bạn.';

  @override
  String get noMatchingTransactionsTitle => 'Không tìm thấy giao dịch phù hợp';

  @override
  String get noMatchingTransactionsSubtitle =>
      'Hãy thử thay đổi từ khóa tìm kiếm hoặc xóa bớt điều kiện lọc.';

  @override
  String get budgetsTitle => 'Ngân sách tháng';

  @override
  String get addBudget => 'Thiết lập ngân sách';

  @override
  String get editBudget => 'Chỉnh sửa ngân sách';

  @override
  String get overallMonthlyBudget => 'Tổng ngân sách tháng';

  @override
  String get categoryBudget => 'Ngân sách theo danh mục';

  @override
  String get budgetScope => 'Phạm vi áp dụng';

  @override
  String get budgetLimit => 'Hạn mức tháng';

  @override
  String alertThresholdLabel(int percent) {
    return 'Cảnh báo khi chạm ngưỡng ($percent%)';
  }

  @override
  String budgetSpentOf(String spent, String limit) {
    return 'Đã chi $spent / $limit';
  }

  @override
  String budgetRemaining(String amount) {
    return 'Còn lại $amount';
  }

  @override
  String budgetExceededBy(String amount) {
    return 'Vượt ngân sách $amount';
  }

  @override
  String budgetWarningBanner(String name, int percent) {
    return 'Cảnh báo: $name đã dùng $percent% hạn mức tháng!';
  }

  @override
  String get emptyBudgetsTitle => 'Chưa thiết lập ngân sách';

  @override
  String get emptyBudgetsSubtitle =>
      'Đặt hạn mức chi tiêu hàng tháng để nhận cảnh báo sớm khi chi vượt kế hoạch.';

  @override
  String get reportsTitle => 'Báo cáo & Phân tích';

  @override
  String get expenseByCategory => 'Cơ cấu chi tiêu theo danh mục';

  @override
  String get incomeVsExpenseTrend => 'Xu hướng Thu nhập vs Chi tiêu (6 tháng)';

  @override
  String get savingsRate => 'Tỷ lệ tiết kiệm';

  @override
  String get noReportDataTitle => 'Chưa có dữ liệu báo cáo trong tháng này';

  @override
  String get noReportDataSubtitle =>
      'Ghi chép các khoản thu chi để xem biểu đồ phân tích trực quan.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get appearanceSection => 'Giao diện & Hiển thị';

  @override
  String get themeMode => 'Chế độ giao diện';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get defaultCurrency => 'Đơn vị tiền tệ';

  @override
  String get securitySection => 'Bảo mật & Dữ liệu';

  @override
  String get biometricLock => 'Khóa ứng dụng sinh trắc học';

  @override
  String get biometricLockSubtitle =>
      'Yêu cầu vân tay / Face ID khi mở ứng dụng';

  @override
  String get biometricNotAvailable =>
      'Thiết bị hiện không hỗ trợ hoặc chưa cài đặt sinh trắc học.';

  @override
  String get biometricPromptReason => 'Xác thực sinh trắc học để mở Sổ Thu Chi';

  @override
  String get appLockedTitle => 'Sổ Thu Chi đang khóa';

  @override
  String get appLockedSubtitle =>
      'Xác thực danh tính để tiếp tục xem dữ liệu tài chính của bạn.';

  @override
  String get unlockNow => 'Mở khóa ngay';

  @override
  String get exportCsv => 'Xuất giao dịch ra tệp CSV';

  @override
  String get exportCsvSubtitle =>
      'Lưu hoặc chia sẻ toàn bộ lịch sử giao dịch cho Excel / Google Sheets';

  @override
  String exportCsvSuccess(int count) {
    return 'Đã tạo tệp CSV ($count giao dịch)';
  }

  @override
  String get aboutSection => 'Thông tin & Pháp lý';

  @override
  String get privacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get aboutApp => 'Giới thiệu ứng dụng';

  @override
  String get accountSection => 'Tài khoản';

  @override
  String get offlineIndicator =>
      'Ngoại tuyến — Thay đổi sẽ tự đồng bộ khi có mạng';

  @override
  String get syncingIndicator => 'Đang đồng bộ dữ liệu lên đám mây...';

  @override
  String get syncedIndicator => 'Đã đồng bộ';

  @override
  String get errorGeneric => 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';

  @override
  String get errorNetwork =>
      'Không có kết nối mạng. Vui lòng kiểm tra đường truyền.';

  @override
  String get errorAuthCancelled => 'Bạn đã hủy đăng nhập Google.';

  @override
  String get errorAuthFailed =>
      'Đăng nhập không thành công. Vui lòng kiểm tra cấu hình Google/Firebase và thử lại.';

  @override
  String get errorPermissionDenied =>
      'Bạn không có quyền thực hiện thao tác này.';

  @override
  String get errorValidation =>
      'Dữ liệu nhập chưa hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get catFood => 'Ăn uống';

  @override
  String get catTransport => 'Di chuyển';

  @override
  String get catHousing => 'Nhà ở';

  @override
  String get catBills => 'Hóa đơn & Tiện ích';

  @override
  String get catShopping => 'Mua sắm';

  @override
  String get catEntertainment => 'Giải trí';

  @override
  String get catHealth => 'Sức khỏe';

  @override
  String get catEducation => 'Giáo dục';

  @override
  String get catSalary => 'Lương';

  @override
  String get catBonus => 'Thưởng';

  @override
  String get catInvestment => 'Đầu tư & Lãi';

  @override
  String get catOtherExpense => 'Chi tiêu khác';

  @override
  String get catOtherIncome => 'Thu nhập khác';

  @override
  String get defaultCashWalletName => 'Tiền mặt';

  @override
  String get previousMonth => 'Tháng trước';

  @override
  String get nextMonth => 'Tháng sau';

  @override
  String get balanceHidden => 'Số dư đang ẩn';

  @override
  String get differentCurrencyTransferError =>
      'Chỉ hỗ trợ chuyển khoản giữa hai ví cùng đơn vị tiền tệ';

  @override
  String get moreOptions => 'Tùy chọn khác';
}
