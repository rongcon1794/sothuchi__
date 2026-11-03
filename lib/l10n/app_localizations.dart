import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Tên ứng dụng
  ///
  /// In vi, this message translates to:
  /// **'Sổ Thu Chi'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý tài chính cá nhân thông minh & tinh gọn'**
  String get appTagline;

  /// No description provided for @navOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get navOverview;

  /// No description provided for @navTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get navTransactions;

  /// No description provided for @navBudgets.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách'**
  String get navBudgets;

  /// No description provided for @navReports.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get navSettings;

  /// No description provided for @onboardingSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu ngay'**
  String get onboardingStart;

  /// No description provided for @onboarding1Title.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép thu chi trong 3 giây'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi mọi khoản thu nhập, chi tiêu và chuyển khoản với định dạng tiền Việt rõ ràng, chính xác đến từng đồng.'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2Title.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý đa ví & ngân sách chủ động'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý tiền mặt, tài khoản ngân hàng, ví điện tử và nhận cảnh báo sớm trước khi vượt ngân sách tháng.'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding3Title.
  ///
  /// In vi, this message translates to:
  /// **'Làm việc ngoại tuyến, đồng bộ tức thì'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép ngay cả khi không có mạng. Dữ liệu được bảo mật riêng tư và tự động đồng bộ lên đám mây khi kết nối lại.'**
  String get onboarding3Subtitle;

  /// No description provided for @signInTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng đến với Sổ Thu Chi'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng tài khoản Google để đồng bộ dữ liệu an toàn giữa các thiết bị của bạn.'**
  String get signInSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Google'**
  String get signInWithGoogle;

  /// No description provided for @tryOfflineDemo.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử chế độ Ngoại tuyến (Chưa cấu hình Firebase)'**
  String get tryOfflineDemo;

  /// No description provided for @firebaseUnconfiguredBanner.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tìm thấy cấu hình Firebase trên thiết bị. Bạn có thể xem hướng dẫn thiết lập hoặc trải nghiệm toàn bộ tính năng ở chế độ cục bộ.'**
  String get firebaseUnconfiguredBanner;

  /// No description provided for @viewSetupGuide.
  ///
  /// In vi, this message translates to:
  /// **'Xem hướng dẫn cấu hình'**
  String get viewSetupGuide;

  /// No description provided for @signOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất tài khoản?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể đăng nhập lại bất cứ lúc nào để tiếp tục đồng bộ dữ liệu.'**
  String get signOutConfirmBody;

  /// No description provided for @deleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản & toàn bộ dữ liệu'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn tài khoản?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ ví, danh mục, giao dịch, ngân sách và hồ sơ của bạn sẽ bị xóa vĩnh viễn và không thể khôi phục.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountAction.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn'**
  String get deleteAccountAction;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @undo.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get undo;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @all.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get all;

  /// No description provided for @today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get yesterday;

  /// No description provided for @totalBalance.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tài sản ròng'**
  String get totalBalance;

  /// No description provided for @showBalance.
  ///
  /// In vi, this message translates to:
  /// **'Hiện số dư'**
  String get showBalance;

  /// No description provided for @hideBalance.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn số dư'**
  String get hideBalance;

  /// No description provided for @thisMonthSummary.
  ///
  /// In vi, this message translates to:
  /// **'Tháng này'**
  String get thisMonthSummary;

  /// No description provided for @income.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get expense;

  /// No description provided for @transfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản'**
  String get transfer;

  /// No description provided for @netBalance.
  ///
  /// In vi, this message translates to:
  /// **'Chênh lệch ròng'**
  String get netBalance;

  /// No description provided for @recentTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch gần đây'**
  String get recentTransactions;

  /// No description provided for @viewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get viewAll;

  /// No description provided for @quickAddTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Thêm giao dịch'**
  String get quickAddTransaction;

  /// No description provided for @walletsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ví & Tài khoản'**
  String get walletsTitle;

  /// No description provided for @manageWallets.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý ví'**
  String get manageWallets;

  /// No description provided for @addWallet.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ví mới'**
  String get addWallet;

  /// No description provided for @editWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa ví'**
  String get editWallet;

  /// No description provided for @walletName.
  ///
  /// In vi, this message translates to:
  /// **'Tên ví'**
  String get walletName;

  /// No description provided for @walletNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Tiền mặt, Vietcombank, MoMo...'**
  String get walletNameHint;

  /// No description provided for @walletType.
  ///
  /// In vi, this message translates to:
  /// **'Loại tài khoản'**
  String get walletType;

  /// No description provided for @walletTypeCash.
  ///
  /// In vi, this message translates to:
  /// **'Tiền mặt'**
  String get walletTypeCash;

  /// No description provided for @walletTypeBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get walletTypeBank;

  /// No description provided for @walletTypeEwallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví điện tử'**
  String get walletTypeEwallet;

  /// No description provided for @walletTypeCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ tín dụng / ghi nợ'**
  String get walletTypeCard;

  /// No description provided for @initialBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư ban đầu'**
  String get initialBalance;

  /// No description provided for @currentBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư hiện tại'**
  String get currentBalance;

  /// No description provided for @archiveWallet.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ ví'**
  String get archiveWallet;

  /// No description provided for @unarchiveWallet.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục ví'**
  String get unarchiveWallet;

  /// No description provided for @archivedWallets.
  ///
  /// In vi, this message translates to:
  /// **'Ví đã lưu trữ'**
  String get archivedWallets;

  /// No description provided for @activeWallets.
  ///
  /// In vi, this message translates to:
  /// **'Ví đang sử dụng'**
  String get activeWallets;

  /// No description provided for @transferBetweenWallets.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển tiền giữa các ví'**
  String get transferBetweenWallets;

  /// No description provided for @fromWallet.
  ///
  /// In vi, this message translates to:
  /// **'Từ ví nguồn'**
  String get fromWallet;

  /// No description provided for @toWallet.
  ///
  /// In vi, this message translates to:
  /// **'Đến ví đích'**
  String get toWallet;

  /// No description provided for @emptyWalletsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ví nào'**
  String get emptyWalletsTitle;

  /// No description provided for @emptyWalletsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo ví đầu tiên để bắt đầu theo dõi dòng tiền hàng ngày.'**
  String get emptyWalletsSubtitle;

  /// No description provided for @categoriesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục thu chi'**
  String get categoriesTitle;

  /// No description provided for @manageCategories.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý danh mục'**
  String get manageCategories;

  /// No description provided for @addCategory.
  ///
  /// In vi, this message translates to:
  /// **'Thêm danh mục'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Cà phê, Xăng xe, Tiền nhà...'**
  String get categoryNameHint;

  /// No description provided for @defaultCategoryBadge.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định'**
  String get defaultCategoryBadge;

  /// No description provided for @selectIcon.
  ///
  /// In vi, this message translates to:
  /// **'Chọn biểu tượng'**
  String get selectIcon;

  /// No description provided for @selectColor.
  ///
  /// In vi, this message translates to:
  /// **'Chọn màu sắc'**
  String get selectColor;

  /// No description provided for @transactionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sổ giao dịch'**
  String get transactionsTitle;

  /// No description provided for @addTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Ghi giao dịch'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Sửa giao dịch'**
  String get editTransaction;

  /// No description provided for @transactionDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa giao dịch'**
  String get transactionDeleted;

  /// No description provided for @amount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get amount;

  /// No description provided for @amountRequiredError.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số tiền lớn hơn 0'**
  String get amountRequiredError;

  /// No description provided for @selectCategory.
  ///
  /// In vi, this message translates to:
  /// **'Chọn danh mục'**
  String get selectCategory;

  /// No description provided for @categoryRequiredError.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn danh mục'**
  String get categoryRequiredError;

  /// No description provided for @walletRequiredError.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn ví'**
  String get walletRequiredError;

  /// No description provided for @sameWalletTransferError.
  ///
  /// In vi, this message translates to:
  /// **'Ví nguồn và ví đích phải khác nhau'**
  String get sameWalletTransferError;

  /// No description provided for @date.
  ///
  /// In vi, this message translates to:
  /// **'Ngày giao dịch'**
  String get date;

  /// No description provided for @note.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get note;

  /// No description provided for @noteHint.
  ///
  /// In vi, this message translates to:
  /// **'Thêm mô tả ngắn (VD: Ăn trưa cùng đồng nghiệp)...'**
  String get noteHint;

  /// No description provided for @tags.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ (phân cách bằng dấu phẩy)'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: công tác, gia đình'**
  String get tagsHint;

  /// No description provided for @searchTransactionsHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo ghi chú hoặc thẻ...'**
  String get searchTransactionsHint;

  /// No description provided for @filterTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc giao dịch'**
  String get filterTransactions;

  /// No description provided for @clearFilters.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc'**
  String get clearFilters;

  /// No description provided for @dateRange.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng thời gian'**
  String get dateRange;

  /// No description provided for @selectDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Chọn khoảng ngày'**
  String get selectDateRange;

  /// No description provided for @emptyTransactionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch nào'**
  String get emptyTransactionsTitle;

  /// No description provided for @emptyTransactionsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn nút + để ghi khoản thu hoặc chi đầu tiên của bạn.'**
  String get emptyTransactionsSubtitle;

  /// No description provided for @noMatchingTransactionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giao dịch phù hợp'**
  String get noMatchingTransactionsTitle;

  /// No description provided for @noMatchingTransactionsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hãy thử thay đổi từ khóa tìm kiếm hoặc xóa bớt điều kiện lọc.'**
  String get noMatchingTransactionsSubtitle;

  /// No description provided for @budgetsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách tháng'**
  String get budgetsTitle;

  /// No description provided for @addBudget.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập ngân sách'**
  String get addBudget;

  /// No description provided for @editBudget.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa ngân sách'**
  String get editBudget;

  /// No description provided for @overallMonthlyBudget.
  ///
  /// In vi, this message translates to:
  /// **'Tổng ngân sách tháng'**
  String get overallMonthlyBudget;

  /// No description provided for @categoryBudget.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách theo danh mục'**
  String get categoryBudget;

  /// No description provided for @budgetScope.
  ///
  /// In vi, this message translates to:
  /// **'Phạm vi áp dụng'**
  String get budgetScope;

  /// No description provided for @budgetLimit.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mức tháng'**
  String get budgetLimit;

  /// No description provided for @alertThresholdLabel.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo khi chạm ngưỡng ({percent}%)'**
  String alertThresholdLabel(int percent);

  /// No description provided for @budgetSpentOf.
  ///
  /// In vi, this message translates to:
  /// **'Đã chi {spent} / {limit}'**
  String budgetSpentOf(String spent, String limit);

  /// No description provided for @budgetRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại {amount}'**
  String budgetRemaining(String amount);

  /// No description provided for @budgetExceededBy.
  ///
  /// In vi, this message translates to:
  /// **'Vượt ngân sách {amount}'**
  String budgetExceededBy(String amount);

  /// No description provided for @budgetWarningBanner.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo: {name} đã dùng {percent}% hạn mức tháng!'**
  String budgetWarningBanner(String name, int percent);

  /// No description provided for @emptyBudgetsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thiết lập ngân sách'**
  String get emptyBudgetsTitle;

  /// No description provided for @emptyBudgetsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt hạn mức chi tiêu hàng tháng để nhận cảnh báo sớm khi chi vượt kế hoạch.'**
  String get emptyBudgetsSubtitle;

  /// No description provided for @reportsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo & Phân tích'**
  String get reportsTitle;

  /// No description provided for @expenseByCategory.
  ///
  /// In vi, this message translates to:
  /// **'Cơ cấu chi tiêu theo danh mục'**
  String get expenseByCategory;

  /// No description provided for @incomeVsExpenseTrend.
  ///
  /// In vi, this message translates to:
  /// **'Xu hướng Thu nhập vs Chi tiêu (6 tháng)'**
  String get incomeVsExpenseTrend;

  /// No description provided for @savingsRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ tiết kiệm'**
  String get savingsRate;

  /// No description provided for @noReportDataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu báo cáo trong tháng này'**
  String get noReportDataTitle;

  /// No description provided for @noReportDataSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép các khoản thu chi để xem biểu đồ phân tích trực quan.'**
  String get noReportDataSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện & Hiển thị'**
  String get appearanceSection;

  /// No description provided for @themeMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ giao diện'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @languageVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @defaultCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị tiền tệ'**
  String get defaultCurrency;

  /// No description provided for @securitySection.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật & Dữ liệu'**
  String get securitySection;

  /// No description provided for @biometricLock.
  ///
  /// In vi, this message translates to:
  /// **'Khóa ứng dụng sinh trắc học'**
  String get biometricLock;

  /// No description provided for @biometricLockSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu vân tay / Face ID khi mở ứng dụng'**
  String get biometricLockSubtitle;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị hiện không hỗ trợ hoặc chưa cài đặt sinh trắc học.'**
  String get biometricNotAvailable;

  /// No description provided for @biometricPromptReason.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực sinh trắc học để mở Sổ Thu Chi'**
  String get biometricPromptReason;

  /// No description provided for @appLockedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sổ Thu Chi đang khóa'**
  String get appLockedTitle;

  /// No description provided for @appLockedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực danh tính để tiếp tục xem dữ liệu tài chính của bạn.'**
  String get appLockedSubtitle;

  /// No description provided for @unlockNow.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa ngay'**
  String get unlockNow;

  /// No description provided for @exportCsv.
  ///
  /// In vi, this message translates to:
  /// **'Xuất giao dịch ra tệp CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu hoặc chia sẻ toàn bộ lịch sử giao dịch cho Excel / Google Sheets'**
  String get exportCsvSubtitle;

  /// No description provided for @exportCsvSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo tệp CSV ({count} giao dịch)'**
  String exportCsvSuccess(int count);

  /// No description provided for @aboutSection.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin & Pháp lý'**
  String get aboutSection;

  /// No description provided for @privacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách quyền riêng tư'**
  String get privacyPolicy;

  /// No description provided for @aboutApp.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu ứng dụng'**
  String get aboutApp;

  /// No description provided for @accountSection.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get accountSection;

  /// No description provided for @offlineIndicator.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại tuyến — Thay đổi sẽ tự đồng bộ khi có mạng'**
  String get offlineIndicator;

  /// No description provided for @syncingIndicator.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ dữ liệu lên đám mây...'**
  String get syncingIndicator;

  /// No description provided for @syncedIndicator.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng bộ'**
  String get syncedIndicator;

  /// No description provided for @errorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối mạng. Vui lòng kiểm tra đường truyền.'**
  String get errorNetwork;

  /// No description provided for @errorAuthCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã hủy đăng nhập Google.'**
  String get errorAuthCancelled;

  /// No description provided for @errorAuthFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập không thành công. Vui lòng kiểm tra cấu hình Google/Firebase và thử lại.'**
  String get errorAuthFailed;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện thao tác này.'**
  String get errorPermissionDenied;

  /// No description provided for @errorValidation.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu nhập chưa hợp lệ. Vui lòng kiểm tra lại.'**
  String get errorValidation;

  /// No description provided for @catFood.
  ///
  /// In vi, this message translates to:
  /// **'Ăn uống'**
  String get catFood;

  /// No description provided for @catTransport.
  ///
  /// In vi, this message translates to:
  /// **'Di chuyển'**
  String get catTransport;

  /// No description provided for @catHousing.
  ///
  /// In vi, this message translates to:
  /// **'Nhà ở'**
  String get catHousing;

  /// No description provided for @catBills.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn & Tiện ích'**
  String get catBills;

  /// No description provided for @catShopping.
  ///
  /// In vi, this message translates to:
  /// **'Mua sắm'**
  String get catShopping;

  /// No description provided for @catEntertainment.
  ///
  /// In vi, this message translates to:
  /// **'Giải trí'**
  String get catEntertainment;

  /// No description provided for @catHealth.
  ///
  /// In vi, this message translates to:
  /// **'Sức khỏe'**
  String get catHealth;

  /// No description provided for @catEducation.
  ///
  /// In vi, this message translates to:
  /// **'Giáo dục'**
  String get catEducation;

  /// No description provided for @catSalary.
  ///
  /// In vi, this message translates to:
  /// **'Lương'**
  String get catSalary;

  /// No description provided for @catBonus.
  ///
  /// In vi, this message translates to:
  /// **'Thưởng'**
  String get catBonus;

  /// No description provided for @catInvestment.
  ///
  /// In vi, this message translates to:
  /// **'Đầu tư & Lãi'**
  String get catInvestment;

  /// No description provided for @catOtherExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu khác'**
  String get catOtherExpense;

  /// No description provided for @catOtherIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập khác'**
  String get catOtherIncome;

  /// No description provided for @defaultCashWalletName.
  ///
  /// In vi, this message translates to:
  /// **'Tiền mặt'**
  String get defaultCashWalletName;

  /// No description provided for @previousMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng trước'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng sau'**
  String get nextMonth;

  /// No description provided for @balanceHidden.
  ///
  /// In vi, this message translates to:
  /// **'Số dư đang ẩn'**
  String get balanceHidden;

  /// No description provided for @differentCurrencyTransferError.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hỗ trợ chuyển khoản giữa hai ví cùng đơn vị tiền tệ'**
  String get differentCurrencyTransferError;

  /// No description provided for @moreOptions.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn khác'**
  String get moreOptions;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
