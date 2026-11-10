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

  /// No description provided for @onboardingPrev.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get onboardingPrev;

  /// No description provided for @onboardingStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu ngay'**
  String get onboardingStart;

  /// No description provided for @onboarding1Tag.
  ///
  /// In vi, this message translates to:
  /// **'GHI CHÉP & ĐA VÍ'**
  String get onboarding1Tag;

  /// No description provided for @onboarding1Title.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép thu chi trong 3 giây'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập thu chi trong 3 giây với bàn phím thông minh và quét hóa đơn AI. Theo dõi tiền mặt, tài khoản ngân hàng và ví điện tử trực quan.'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2Tag.
  ///
  /// In vi, this message translates to:
  /// **'NGÂN SÁCH THÔNG MINH'**
  String get onboarding2Tag;

  /// No description provided for @onboarding2Title.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách & Kiểm soát chi tiêu'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập hạn mức theo từng danh mục. Theo dõi nhịp chi an toàn mỗi ngày và nhận cảnh báo kịp thời trước khi vượt ngân sách.'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding3Tag.
  ///
  /// In vi, this message translates to:
  /// **'MỤC TIÊU & HÓA ĐƠN'**
  String get onboarding3Tag;

  /// No description provided for @onboarding3Title.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu tiết kiệm & Hóa đơn định kỳ'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hũ tích lũy cho những ước mơ lớn. Quản lý hóa đơn điện, nước, dịch vụ định kỳ và tự động nhắc nhở khi đến hạn.'**
  String get onboarding3Subtitle;

  /// No description provided for @onboarding4Tag.
  ///
  /// In vi, this message translates to:
  /// **'BÁO CÁO TÀI CHÍNH'**
  String get onboarding4Tag;

  /// No description provided for @onboarding4Title.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo trực quan & Phân tích chuyên sâu'**
  String get onboarding4Title;

  /// No description provided for @onboarding4Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá cơ cấu chi tiêu qua biểu đồ sắc nét, nắm bắt xu hướng dòng tiền ròng và xuất báo cáo Excel, PDF tiện lợi.'**
  String get onboarding4Subtitle;

  /// No description provided for @onboarding5Tag.
  ///
  /// In vi, this message translates to:
  /// **'BẢO MẬT & ĐỒNG BỘ'**
  String get onboarding5Tag;

  /// No description provided for @onboarding5Title.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật riêng tư & Đồng bộ đám mây'**
  String get onboarding5Title;

  /// No description provided for @onboarding5Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khóa an toàn bằng Face ID, vân tay và mã PIN. Sử dụng mượt mà 100% ngoại tuyến và tự động sao lưu tức thì khi có mạng.'**
  String get onboarding5Subtitle;

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

  /// No description provided for @dangerZoneSection.
  ///
  /// In vi, this message translates to:
  /// **'VÙNG NGUY HIỂM'**
  String get dangerZoneSection;

  /// No description provided for @deleteDataAndAccountSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn toàn bộ dữ liệu, giao dịch và tài khoản'**
  String get deleteDataAndAccountSubtitle;

  /// No description provided for @keyboard.
  ///
  /// In vi, this message translates to:
  /// **'Bàn phím'**
  String get keyboard;

  /// No description provided for @hideKeyboard.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn bàn phím'**
  String get hideKeyboard;

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

  /// No description provided for @suggestedNotes.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý mô tả'**
  String get suggestedNotes;

  /// No description provided for @tags.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ phân loại'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: công tác, gia đình'**
  String get tagsHint;

  /// No description provided for @frequentTags.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ hay dùng'**
  String get frequentTags;

  /// No description provided for @addTag.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thẻ'**
  String get addTag;

  /// No description provided for @addTagHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên thẻ rồi bấm Thêm hoặc Enter...'**
  String get addTagHint;

  /// No description provided for @zeroSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý thêm số 0'**
  String get zeroSuggestions;

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

  /// No description provided for @debtBookTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sổ Ghi Nợ'**
  String get debtBookTitle;

  /// No description provided for @debtNew.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nợ mới'**
  String get debtNew;

  /// No description provided for @debtEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thông tin'**
  String get debtEdit;

  /// No description provided for @debtDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khoản nợ'**
  String get debtDelete;

  /// No description provided for @debtDeleteConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa'**
  String get debtDeleteConfirmTitle;

  /// No description provided for @debtDeleteConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa khoản nợ của {name}?'**
  String debtDeleteConfirmBody(String name);

  /// No description provided for @debtLent.
  ///
  /// In vi, this message translates to:
  /// **'Cho vay'**
  String get debtLent;

  /// No description provided for @debtBorrowed.
  ///
  /// In vi, this message translates to:
  /// **'Đi vay'**
  String get debtBorrowed;

  /// No description provided for @debtLentSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cần thu hồi'**
  String get debtLentSubtitle;

  /// No description provided for @debtBorrowedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cần thanh toán'**
  String get debtBorrowedSubtitle;

  /// No description provided for @debtTotalLent.
  ///
  /// In vi, this message translates to:
  /// **'Tổng cho vay'**
  String get debtTotalLent;

  /// No description provided for @debtTotalBorrowed.
  ///
  /// In vi, this message translates to:
  /// **'Tổng đi vay'**
  String get debtTotalBorrowed;

  /// No description provided for @debtFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get debtFilterAll;

  /// No description provided for @debtFilterUnsettled.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thanh toán'**
  String get debtFilterUnsettled;

  /// No description provided for @debtFilterSettled.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán xong'**
  String get debtFilterSettled;

  /// No description provided for @debtFilterLent.
  ///
  /// In vi, this message translates to:
  /// **'Cho vay'**
  String get debtFilterLent;

  /// No description provided for @debtFilterBorrowed.
  ///
  /// In vi, this message translates to:
  /// **'Đi vay'**
  String get debtFilterBorrowed;

  /// No description provided for @debtRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại'**
  String get debtRemaining;

  /// No description provided for @debtDueDate.
  ///
  /// In vi, this message translates to:
  /// **'Hạn: {date}'**
  String debtDueDate(String date);

  /// No description provided for @debtRepay.
  ///
  /// In vi, this message translates to:
  /// **'Trả bớt'**
  String get debtRepay;

  /// No description provided for @debtCollect.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi'**
  String get debtCollect;

  /// No description provided for @debtEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản nợ nào'**
  String get debtEmpty;

  /// No description provided for @debtEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chép tiền cho vay hoặc đi vay để không bao giờ bị quên.'**
  String get debtEmptySubtitle;

  /// No description provided for @debtRepaymentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận thanh toán'**
  String get debtRepaymentTitle;

  /// No description provided for @debtRepaymentCollectTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi nợ từ {name}'**
  String debtRepaymentCollectTitle(String name);

  /// No description provided for @debtRepaymentPayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trả nợ cho {name}'**
  String debtRepaymentPayTitle(String name);

  /// No description provided for @debtRepaymentAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền thanh toán'**
  String get debtRepaymentAmount;

  /// No description provided for @debtRepaymentWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví nhận / trả tiền'**
  String get debtRepaymentWallet;

  /// No description provided for @debtRepaymentFull.
  ///
  /// In vi, this message translates to:
  /// **'Trả hết toàn bộ'**
  String get debtRepaymentFull;

  /// No description provided for @debtRepaymentSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận thanh toán {amount}'**
  String debtRepaymentSuccess(String amount);

  /// No description provided for @debtUpdatedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật khoản nợ'**
  String get debtUpdatedSuccess;

  /// No description provided for @debtAddedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận khoản nợ mới'**
  String get debtAddedSuccess;

  /// No description provided for @debtPersonName.
  ///
  /// In vi, this message translates to:
  /// **'Người vay / cho vay'**
  String get debtPersonName;

  /// No description provided for @debtPersonNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Anh Tuấn, Chị Lan...'**
  String get debtPersonNameHint;

  /// No description provided for @debtPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại (tùy chọn)'**
  String get debtPhoneNumber;

  /// No description provided for @debtTypeLent.
  ///
  /// In vi, this message translates to:
  /// **'Tôi cho vay (Người khác nợ tôi)'**
  String get debtTypeLent;

  /// No description provided for @debtTypeBorrowed.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đi vay (Tôi nợ người khác)'**
  String get debtTypeBorrowed;

  /// No description provided for @debtAmountRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số tiền hợp lệ lớn hơn 0'**
  String get debtAmountRequired;

  /// No description provided for @debtPersonRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên người vay / cho vay'**
  String get debtPersonRequired;

  /// No description provided for @savingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Heo Đất & Tiết Kiệm'**
  String get savingsTitle;

  /// No description provided for @savingsNewGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu mới'**
  String get savingsNewGoal;

  /// No description provided for @savingsEditGoal.
  ///
  /// In vi, this message translates to:
  /// **'Sửa mục tiêu'**
  String get savingsEditGoal;

  /// No description provided for @savingsDeleteGoal.
  ///
  /// In vi, this message translates to:
  /// **'Xóa mục tiêu'**
  String get savingsDeleteGoal;

  /// No description provided for @savingsDeleteConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa mục tiêu \"{title}\"'**
  String savingsDeleteConfirmTitle(String title);

  /// No description provided for @savingsDeleteConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác này sẽ xóa mục tiêu tích lũy. Lịch sử giao dịch tiền trong ví vẫn được giữ nguyên.'**
  String get savingsDeleteConfirmBody;

  /// No description provided for @savingsTotalSaved.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền đã gom'**
  String get savingsTotalSaved;

  /// No description provided for @savingsTotalTarget.
  ///
  /// In vi, this message translates to:
  /// **'Tổng mục tiêu'**
  String get savingsTotalTarget;

  /// No description provided for @savingsSummaryProgress.
  ///
  /// In vi, this message translates to:
  /// **'TỔNG TIẾN ĐỘ TÍCH LŨY'**
  String get savingsSummaryProgress;

  /// No description provided for @savingsActiveCount.
  ///
  /// In vi, this message translates to:
  /// **'{active} đang chạy • {completed} hoàn thành'**
  String savingsActiveCount(int active, int completed);

  /// No description provided for @savingsDaysRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày'**
  String savingsDaysRemaining(int days);

  /// No description provided for @savingsDailyNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Cần {amount}/ngày'**
  String savingsDailyNeeded(String amount);

  /// No description provided for @savingsDeposit.
  ///
  /// In vi, this message translates to:
  /// **'Nạp tích lũy'**
  String get savingsDeposit;

  /// No description provided for @savingsWithdraw.
  ///
  /// In vi, this message translates to:
  /// **'Rút tiền về ví'**
  String get savingsWithdraw;

  /// No description provided for @savingsGoalCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành!'**
  String get savingsGoalCompleted;

  /// No description provided for @savingsGoalTarget.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu: {amount}'**
  String savingsGoalTarget(String amount);

  /// No description provided for @savingsGoalRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn thiếu: {amount}'**
  String savingsGoalRemaining(String amount);

  /// No description provided for @savingsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mục tiêu tiết kiệm'**
  String get savingsEmpty;

  /// No description provided for @savingsEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập quỹ khẩn cấp, mua sắm hoặc du lịch để theo dõi tiến độ tích lũy mỗi ngày.'**
  String get savingsEmptySubtitle;

  /// No description provided for @savingsCreateFirst.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mục tiêu đầu tiên'**
  String get savingsCreateFirst;

  /// No description provided for @savingsGoalName.
  ///
  /// In vi, this message translates to:
  /// **'Tên mục tiêu'**
  String get savingsGoalName;

  /// No description provided for @savingsGoalNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Quỹ khẩn cấp, Mua xe, Du lịch...'**
  String get savingsGoalNameHint;

  /// No description provided for @savingsTargetAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền cần đạt được'**
  String get savingsTargetAmount;

  /// No description provided for @savingsDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hạn hoàn thành (Deadline)'**
  String get savingsDeadline;

  /// No description provided for @savingsNoDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Không đặt thời hạn'**
  String get savingsNoDeadline;

  /// No description provided for @savingsLinkedWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví liên kết (tùy chọn)'**
  String get savingsLinkedWallet;

  /// No description provided for @savingsNoLinkedWallet.
  ///
  /// In vi, this message translates to:
  /// **'Không chỉ định ví'**
  String get savingsNoLinkedWallet;

  /// No description provided for @savingsGoalIcon.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng mục tiêu'**
  String get savingsGoalIcon;

  /// No description provided for @savingsGoalColor.
  ///
  /// In vi, this message translates to:
  /// **'Màu sắc chủ đề'**
  String get savingsGoalColor;

  /// No description provided for @savingsDepositSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã tích lũy thêm {amount} vào {title}!'**
  String savingsDepositSuccess(String amount, String title);

  /// No description provided for @savingsWithdrawSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã rút {amount} từ {title}'**
  String savingsWithdrawSuccess(String amount, String title);

  /// No description provided for @savingsAmountRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số tiền mục tiêu hợp lệ'**
  String get savingsAmountRequired;

  /// No description provided for @savingsNoWalletAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ví nào khả dụng'**
  String get savingsNoWalletAvailable;

  /// No description provided for @savingsTargetRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên mục tiêu'**
  String get savingsTargetRequired;

  /// No description provided for @recurringTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hóa Đơn & Định Kỳ'**
  String get recurringTitle;

  /// No description provided for @recurringNew.
  ///
  /// In vi, this message translates to:
  /// **'Thêm gói mới'**
  String get recurringNew;

  /// No description provided for @recurringEdit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa'**
  String get recurringEdit;

  /// No description provided for @recurringDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa gói'**
  String get recurringDelete;

  /// No description provided for @recurringDeleteConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa gói định kỳ'**
  String get recurringDeleteConfirmTitle;

  /// No description provided for @recurringDeleteConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa \"{title}\"? Các giao dịch đã ghi trong quá khứ sẽ không bị ảnh hưởng.'**
  String recurringDeleteConfirmBody(String title);

  /// No description provided for @recurringEstimatedMonthly.
  ///
  /// In vi, this message translates to:
  /// **'ƯỚC TÍNH CHI PHÍ HÀNG THÁNG'**
  String get recurringEstimatedMonthly;

  /// No description provided for @recurringActiveCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} gói đang chạy'**
  String recurringActiveCount(int count);

  /// No description provided for @recurringDueBills.
  ///
  /// In vi, this message translates to:
  /// **'HÓA ĐƠN ĐẾN HẠN CẦN THANH TOÁN'**
  String get recurringDueBills;

  /// No description provided for @recurringActiveSection.
  ///
  /// In vi, this message translates to:
  /// **'CÁC GÓI ĐỊNH KỲ ĐANG THEO DÕI'**
  String get recurringActiveSection;

  /// No description provided for @recurringPausedSection.
  ///
  /// In vi, this message translates to:
  /// **'GÓI ĐANG TẠM DỪNG'**
  String get recurringPausedSection;

  /// No description provided for @recurringNextDue.
  ///
  /// In vi, this message translates to:
  /// **'Đến hạn: {date}'**
  String recurringNextDue(String date);

  /// No description provided for @recurringIntervalDaily.
  ///
  /// In vi, this message translates to:
  /// **'Hàng ngày'**
  String get recurringIntervalDaily;

  /// No description provided for @recurringIntervalWeekly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng tuần'**
  String get recurringIntervalWeekly;

  /// No description provided for @recurringIntervalBiweekly.
  ///
  /// In vi, this message translates to:
  /// **'2 tuần một lần'**
  String get recurringIntervalBiweekly;

  /// No description provided for @recurringIntervalMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng tháng'**
  String get recurringIntervalMonthly;

  /// No description provided for @recurringIntervalYearly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng năm'**
  String get recurringIntervalYearly;

  /// No description provided for @recurringMarkPaid.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận đã thanh toán'**
  String get recurringMarkPaid;

  /// No description provided for @recurringMarkReceived.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận đã nhận tiền'**
  String get recurringMarkReceived;

  /// No description provided for @recurringPayNow.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán ngay'**
  String get recurringPayNow;

  /// No description provided for @recurringReceiveNow.
  ///
  /// In vi, this message translates to:
  /// **'Nhận tiền ngay'**
  String get recurringReceiveNow;

  /// No description provided for @recurringDueTodayExpense.
  ///
  /// In vi, this message translates to:
  /// **'Hạn thanh toán hôm nay'**
  String get recurringDueTodayExpense;

  /// No description provided for @recurringDueTodayIncome.
  ///
  /// In vi, this message translates to:
  /// **'Đến ngày nhận hôm nay'**
  String get recurringDueTodayIncome;

  /// No description provided for @recurringDueIncomes.
  ///
  /// In vi, this message translates to:
  /// **'KỲ THU NHẬP ĐẾN NGÀY NHẬN'**
  String get recurringDueIncomes;

  /// No description provided for @recurringDueBillsSection.
  ///
  /// In vi, this message translates to:
  /// **'HÓA ĐƠN ĐẾN HẠN CẦN THANH TOÁN'**
  String get recurringDueBillsSection;

  /// No description provided for @recurringMonthlyNetCashflow.
  ///
  /// In vi, this message translates to:
  /// **'DÒNG TIỀN ĐỊNH KỲ / THÁNG'**
  String get recurringMonthlyNetCashflow;

  /// No description provided for @recurringEstimatedMonthlyIncome.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến thu'**
  String get recurringEstimatedMonthlyIncome;

  /// No description provided for @recurringEstimatedMonthlyExpense.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến chi (Hóa đơn)'**
  String get recurringEstimatedMonthlyExpense;

  /// No description provided for @recurringTabAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get recurringTabAll;

  /// No description provided for @recurringTabBills.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn & Chi trả'**
  String get recurringTabBills;

  /// No description provided for @recurringTabIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập định kỳ'**
  String get recurringTabIncome;

  /// No description provided for @recurringReceiveWalletLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ví nhận tiền'**
  String get recurringReceiveWalletLabel;

  /// No description provided for @recurringCategoryIncomeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục thu nhập'**
  String get recurringCategoryIncomeLabel;

  /// No description provided for @recurringAutoExecuteIncomeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tự cộng tiền vào ví và tạo giao dịch thu nhập mà không cần xác nhận thủ công'**
  String get recurringAutoExecuteIncomeSubtitle;

  /// No description provided for @recurringNextIncomeDue.
  ///
  /// In vi, this message translates to:
  /// **'Ngày nhận: {date}'**
  String recurringNextIncomeDue(String date);

  /// No description provided for @recurringIncomeRecordedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận nhận tiền: {title}'**
  String recurringIncomeRecordedSuccess(String title);

  /// No description provided for @recurringExpenseRecordedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận thanh toán: {title}'**
  String recurringExpenseRecordedSuccess(String title);

  /// No description provided for @recurringPause.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get recurringPause;

  /// No description provided for @recurringResume.
  ///
  /// In vi, this message translates to:
  /// **'Kích hoạt lại'**
  String get recurringResume;

  /// No description provided for @recurringAutoExecute.
  ///
  /// In vi, this message translates to:
  /// **'Tự động ghi sổ khi đến hạn'**
  String get recurringAutoExecute;

  /// No description provided for @recurringAutoExecuteSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tự trừ tiền trong ví và tạo giao dịch mà không cần xác nhận thủ công'**
  String get recurringAutoExecuteSubtitle;

  /// No description provided for @recurringEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hóa đơn định kỳ nào'**
  String get recurringEmpty;

  /// No description provided for @recurringEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi tiền thuê nhà, internet, Netflix, Spotify hoặc lương định kỳ hàng tháng.'**
  String get recurringEmptySubtitle;

  /// No description provided for @recurringRecordedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận giao dịch: {title}'**
  String recurringRecordedSuccess(String title);

  /// No description provided for @recurringWalletRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn ví thanh toán'**
  String get recurringWalletRequired;

  /// No description provided for @recurringFrequency.
  ///
  /// In vi, this message translates to:
  /// **'Tần suất lặp lại'**
  String get recurringFrequency;

  /// No description provided for @recurringStartDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu / Đến hạn'**
  String get recurringStartDate;

  /// No description provided for @ledgersTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản Lý Sổ Thu Chi'**
  String get ledgersTitle;

  /// No description provided for @ledgerNew.
  ///
  /// In vi, this message translates to:
  /// **'Thêm sổ mới'**
  String get ledgerNew;

  /// No description provided for @ledgerEdit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa'**
  String get ledgerEdit;

  /// No description provided for @ledgerDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa sổ'**
  String get ledgerDelete;

  /// No description provided for @ledgerDeleteConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa sổ \"{name}\"'**
  String ledgerDeleteConfirmTitle(String name);

  /// No description provided for @ledgerDeleteConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác này sẽ xóa sổ thu chi này khỏi thiết bị.'**
  String get ledgerDeleteConfirmBody;

  /// No description provided for @ledgerPersonal.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get ledgerPersonal;

  /// No description provided for @ledgerFamily.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get ledgerFamily;

  /// No description provided for @ledgerBusiness.
  ///
  /// In vi, this message translates to:
  /// **'Kinh doanh / Dự án'**
  String get ledgerBusiness;

  /// No description provided for @ledgerCustom.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chỉnh'**
  String get ledgerCustom;

  /// No description provided for @ledgerActiveBadge.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get ledgerActiveBadge;

  /// No description provided for @ledgerSelectActive.
  ///
  /// In vi, this message translates to:
  /// **'Chọn làm sổ hiện tại'**
  String get ledgerSelectActive;

  /// No description provided for @ledgerSwitcherTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển Sổ Thu Chi'**
  String get ledgerSwitcherTitle;

  /// No description provided for @ledgerSwitcherSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển đổi linh hoạt giữa chi tiêu cá nhân, gia đình và công việc'**
  String get ledgerSwitcherSubtitle;

  /// No description provided for @ledgerName.
  ///
  /// In vi, this message translates to:
  /// **'Tên sổ'**
  String get ledgerName;

  /// No description provided for @ledgerNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Sổ cá nhân, Gia đình, Dự án freelance...'**
  String get ledgerNameHint;

  /// No description provided for @ledgerType.
  ///
  /// In vi, this message translates to:
  /// **'Phân loại sổ'**
  String get ledgerType;

  /// No description provided for @ledgerIcon.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng'**
  String get ledgerIcon;

  /// No description provided for @ledgerColor.
  ///
  /// In vi, this message translates to:
  /// **'Màu sắc chủ đề'**
  String get ledgerColor;

  /// No description provided for @ledgerNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên sổ'**
  String get ledgerNameRequired;

  /// No description provided for @txTimeAndDetails.
  ///
  /// In vi, this message translates to:
  /// **'THỜI GIAN & CHI TIẾT'**
  String get txTimeAndDetails;

  /// No description provided for @txSourceWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví chuyển'**
  String get txSourceWallet;

  /// No description provided for @txDestWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví nhận'**
  String get txDestWallet;

  /// No description provided for @txSelectWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví'**
  String get txSelectWallet;

  /// No description provided for @txSwapWallets.
  ///
  /// In vi, this message translates to:
  /// **'Đổi chiều chuyển'**
  String get txSwapWallets;

  /// No description provided for @txToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get txToday;

  /// No description provided for @txChangeDate.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi'**
  String get txChangeDate;

  /// No description provided for @txRestoreDefaultCategories.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục mẫu'**
  String get txRestoreDefaultCategories;

  /// No description provided for @txEmptyCategoriesMsg.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng khôi phục danh mục mẫu hoặc tạo danh mục mới để phân loại giao dịch.'**
  String get txEmptyCategoriesMsg;

  /// No description provided for @txCategoryOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get txCategoryOther;

  /// No description provided for @txCategoryAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get txCategoryAdd;

  /// No description provided for @txCategorySearchPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm danh mục...'**
  String get txCategorySearchPlaceholder;

  /// No description provided for @txCategoryNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy danh mục'**
  String get txCategoryNotFound;

  /// No description provided for @txCategoryCreateNew.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mới'**
  String get txCategoryCreateNew;

  /// No description provided for @txUpdateTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật giao dịch'**
  String get txUpdateTransaction;

  /// No description provided for @txDeleteLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get txDeleteLabel;

  /// No description provided for @homeDueBillsBanner.
  ///
  /// In vi, this message translates to:
  /// **'Có {count} hóa đơn định kỳ đến hạn cần thanh toán!'**
  String homeDueBillsBanner(int count);

  /// No description provided for @homeSavingsStripTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu tiết kiệm'**
  String get homeSavingsStripTitle;

  /// No description provided for @homeDebtsStripTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sổ ghi nợ gần đây'**
  String get homeDebtsStripTitle;

  /// No description provided for @homeActionTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get homeActionTransaction;

  /// No description provided for @homeActionWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví tiền'**
  String get homeActionWallet;

  /// No description provided for @homeActionSavings.
  ///
  /// In vi, this message translates to:
  /// **'Tiết kiệm'**
  String get homeActionSavings;

  /// No description provided for @homeActionRecurring.
  ///
  /// In vi, this message translates to:
  /// **'Định kỳ'**
  String get homeActionRecurring;

  /// No description provided for @homeActionDebts.
  ///
  /// In vi, this message translates to:
  /// **'Sổ Ghi Nợ'**
  String get homeActionDebts;

  /// No description provided for @homeActionCategories.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get homeActionCategories;

  /// No description provided for @settingsDataSection.
  ///
  /// In vi, this message translates to:
  /// **'DỮ LIỆU & QUẢN LÝ'**
  String get settingsDataSection;

  /// No description provided for @settingsDebtsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý tiền cho vay & đi vay'**
  String get settingsDebtsSubtitle;

  /// No description provided for @settingsRecurringSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi định kỳ, hóa đơn lặp lại'**
  String get settingsRecurringSubtitle;

  /// No description provided for @settingsSavingsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu tài chính, tích lũy mua sắm'**
  String get settingsSavingsSubtitle;

  /// No description provided for @settingsLedgersSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đa sổ cá nhân, gia đình, công việc'**
  String get settingsLedgersSubtitle;

  /// No description provided for @settingsDemoTag.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử offline'**
  String get settingsDemoTag;

  /// No description provided for @settingsGoogleTag.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng bộ Google'**
  String get settingsGoogleTag;

  /// No description provided for @settingsAppIcon.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng ứng dụng'**
  String get settingsAppIcon;

  /// No description provided for @settingsAppIconSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chỉnh phong cách icon hiển thị'**
  String get settingsAppIconSubtitle;

  /// No description provided for @settingsThemeDefault.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định (Ngọc Bích)'**
  String get settingsThemeDefault;

  /// No description provided for @settingsThemeClassic.
  ///
  /// In vi, this message translates to:
  /// **'iOS Cổ Điển (Xanh Dương)'**
  String get settingsThemeClassic;

  /// No description provided for @settingsThemeMinimal.
  ///
  /// In vi, this message translates to:
  /// **'Tối Giản (Đen Tuyền)'**
  String get settingsThemeMinimal;

  /// No description provided for @settingsThemeSunset.
  ///
  /// In vi, this message translates to:
  /// **'Hoàng Hôn (Cam Đào)'**
  String get settingsThemeSunset;

  /// No description provided for @settingsWalletsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} ví'**
  String settingsWalletsCount(int count);

  /// No description provided for @settingsCategoriesCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục'**
  String settingsCategoriesCount(int count);

  /// No description provided for @settingsDebtsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} nợ'**
  String settingsDebtsCount(int count);

  /// No description provided for @reportsFinancialHealth.
  ///
  /// In vi, this message translates to:
  /// **'Sức Khỏe Tài Chính'**
  String get reportsFinancialHealth;

  /// No description provided for @reportsSpendingHeatmap.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ Chi tiêu theo Ngày'**
  String get reportsSpendingHeatmap;

  /// No description provided for @reportsMonthTotalExpense.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi trong tháng'**
  String get reportsMonthTotalExpense;

  /// No description provided for @reportsDailyAverage.
  ///
  /// In vi, this message translates to:
  /// **'Trung bình: {amount}/ngày'**
  String reportsDailyAverage(String amount);

  /// No description provided for @reportsMaxDay.
  ///
  /// In vi, this message translates to:
  /// **'Chi nhiều nhất: {amount}'**
  String reportsMaxDay(String amount);

  /// No description provided for @reportsSelectedDay.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết ngày {date}'**
  String reportsSelectedDay(String date);

  /// No description provided for @reportsNoExpenseOnDay.
  ///
  /// In vi, this message translates to:
  /// **'Không có khoản chi nào trong ngày này'**
  String get reportsNoExpenseOnDay;

  /// No description provided for @categoryCreateNew.
  ///
  /// In vi, this message translates to:
  /// **'Tạo danh mục mới'**
  String get categoryCreateNew;

  /// No description provided for @categoryIconAndColor.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng & màu sắc'**
  String get categoryIconAndColor;

  /// No description provided for @categoryChooseIcon.
  ///
  /// In vi, this message translates to:
  /// **'Chọn biểu tượng'**
  String get categoryChooseIcon;

  /// No description provided for @categoryChooseColor.
  ///
  /// In vi, this message translates to:
  /// **'Chọn màu sắc'**
  String get categoryChooseColor;

  /// No description provided for @savingsProgress.
  ///
  /// In vi, this message translates to:
  /// **'tiến độ'**
  String get savingsProgress;

  /// No description provided for @savingsTarget.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu'**
  String get savingsTarget;

  /// No description provided for @savingsRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn thiếu'**
  String get savingsRemaining;

  /// No description provided for @savingsDepositAction.
  ///
  /// In vi, this message translates to:
  /// **'Nạp tích lũy'**
  String get savingsDepositAction;

  /// No description provided for @savingsWithdrawAction.
  ///
  /// In vi, this message translates to:
  /// **'Rút tiền'**
  String get savingsWithdrawAction;

  /// No description provided for @savingsMotivationNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú động lực'**
  String get savingsMotivationNote;

  /// No description provided for @savingsQuickRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Phần còn thiếu'**
  String get savingsQuickRemaining;

  /// No description provided for @savingsQuickAll.
  ///
  /// In vi, this message translates to:
  /// **'Rút toàn bộ'**
  String get savingsQuickAll;

  /// No description provided for @savingsWalletSource.
  ///
  /// In vi, this message translates to:
  /// **'Ví trích tiền nạp'**
  String get savingsWalletSource;

  /// No description provided for @savingsWalletDest.
  ///
  /// In vi, this message translates to:
  /// **'Ví nhận tiền'**
  String get savingsWalletDest;

  /// No description provided for @savingsConfirmDeposit.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận tích lũy'**
  String get savingsConfirmDeposit;

  /// No description provided for @savingsConfirmWithdraw.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận rút tiền'**
  String get savingsConfirmWithdraw;

  /// No description provided for @savingsEditGoalTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa mục tiêu tiết kiệm'**
  String get savingsEditGoalTitle;

  /// No description provided for @savingsNewGoalTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mục tiêu tiết kiệm mới'**
  String get savingsNewGoalTitle;

  /// No description provided for @recurringIntervalQuarterly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng quý'**
  String get recurringIntervalQuarterly;

  /// No description provided for @recurringFrequencyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tần suất lặp lại'**
  String get recurringFrequencyLabel;

  /// No description provided for @recurringStartDateLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu'**
  String get recurringStartDateLabel;

  /// No description provided for @recurringNextDueDateLabel.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ hạn tiếp theo'**
  String get recurringNextDueDateLabel;

  /// No description provided for @recurringTitleLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên hóa đơn / dịch vụ'**
  String get recurringTitleLabel;

  /// No description provided for @recurringTitleRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên hóa đơn'**
  String get recurringTitleRequired;

  /// No description provided for @recurringAmountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get recurringAmountLabel;

  /// No description provided for @recurringAmountRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số tiền hợp lệ'**
  String get recurringAmountRequired;

  /// No description provided for @recurringWalletLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ví thanh toán'**
  String get recurringWalletLabel;

  /// No description provided for @recurringCategoryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục chi tiêu'**
  String get recurringCategoryLabel;

  /// No description provided for @recurringConfirmCreate.
  ///
  /// In vi, this message translates to:
  /// **'Thêm gói định kỳ'**
  String get recurringConfirmCreate;

  /// No description provided for @recurringConfirmUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật gói định kỳ'**
  String get recurringConfirmUpdate;

  /// No description provided for @recurringEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa gói định kỳ'**
  String get recurringEditTitle;

  /// No description provided for @recurringNewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm hóa đơn định kỳ'**
  String get recurringNewTitle;

  /// No description provided for @ledgerEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa sổ thu chi'**
  String get ledgerEditTitle;

  /// No description provided for @ledgerNewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm sổ thu chi mới'**
  String get ledgerNewTitle;

  /// No description provided for @ledgerDescLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả (Tùy chọn)'**
  String get ledgerDescLabel;

  /// No description provided for @ledgerDescHint.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả chi tiết sổ'**
  String get ledgerDescHint;

  /// No description provided for @ledgerConfirmCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo sổ mới'**
  String get ledgerConfirmCreate;

  /// No description provided for @ledgerConfirmUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật sổ'**
  String get ledgerConfirmUpdate;

  /// No description provided for @ledgerSharedWith.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ với: {count} thành viên'**
  String ledgerSharedWith(int count);

  /// No description provided for @transactionTimeDetails.
  ///
  /// In vi, this message translates to:
  /// **'THỜI GIAN & CHI TIẾT'**
  String get transactionTimeDetails;

  /// No description provided for @transactionSelectSourceWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví nguồn'**
  String get transactionSelectSourceWallet;

  /// No description provided for @transactionSelectDestWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví đích'**
  String get transactionSelectDestWallet;

  /// No description provided for @transactionOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get transactionOther;

  /// No description provided for @transactionAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get transactionAdd;

  /// No description provided for @transactionCreateNew.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mới'**
  String get transactionCreateNew;

  /// No description provided for @settingsDataAndManagement.
  ///
  /// In vi, this message translates to:
  /// **'DỮ LIỆU & QUẢN LÝ'**
  String get settingsDataAndManagement;

  /// No description provided for @settingsAccountGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản Google'**
  String get settingsAccountGoogle;

  /// No description provided for @settingsAccountGuest.
  ///
  /// In vi, this message translates to:
  /// **'Khách (Offline)'**
  String get settingsAccountGuest;

  /// No description provided for @selectWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví'**
  String get selectWallet;

  /// No description provided for @swapWallets.
  ///
  /// In vi, this message translates to:
  /// **'Đổi chiều chuyển'**
  String get swapWallets;

  /// No description provided for @changeDate.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi'**
  String get changeDate;

  /// No description provided for @noCategories.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh mục nào'**
  String get noCategories;

  /// No description provided for @noCategoriesFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy danh mục'**
  String get noCategoriesFound;

  /// No description provided for @searchCategories.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm danh mục...'**
  String get searchCategories;

  /// No description provided for @restoreDefaultCategories.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục mẫu'**
  String get restoreDefaultCategories;

  /// No description provided for @noCategoriesDescription.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng khôi phục danh mục mẫu hoặc tạo danh mục mới để phân loại giao dịch.'**
  String get noCategoriesDescription;

  /// No description provided for @clear.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get clear;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @updateTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật giao dịch'**
  String get updateTransaction;

  /// No description provided for @reportsShareTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ báo cáo'**
  String get reportsShareTooltip;

  /// No description provided for @heatmapTapHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào ngày để xem số tiền đã chi tiêu chi tiết'**
  String get heatmapTapHint;

  /// No description provided for @heatmapNoSpending.
  ///
  /// In vi, this message translates to:
  /// **'Không có chi tiêu'**
  String get heatmapNoSpending;

  /// No description provided for @heatmapMonthlySummary.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan Chi tiêu Tháng'**
  String get heatmapMonthlySummary;

  /// No description provided for @heatmapNone.
  ///
  /// In vi, this message translates to:
  /// **'Không có'**
  String get heatmapNone;

  /// No description provided for @heatmapLess.
  ///
  /// In vi, this message translates to:
  /// **'Ít'**
  String get heatmapLess;

  /// No description provided for @heatmapMore.
  ///
  /// In vi, this message translates to:
  /// **'Nhiều'**
  String get heatmapMore;

  /// No description provided for @healthSavingsRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ tích lũy'**
  String get healthSavingsRate;

  /// No description provided for @healthSpendingPace.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp độ chi tiêu'**
  String get healthSpendingPace;

  /// No description provided for @healthTopCategory.
  ///
  /// In vi, this message translates to:
  /// **'Hạng mục chi lớn nhất'**
  String get healthTopCategory;

  /// No description provided for @healthInsufficientData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đủ dữ liệu'**
  String get healthInsufficientData;

  /// No description provided for @healthRatingExcellent.
  ///
  /// In vi, this message translates to:
  /// **'Rất Tốt'**
  String get healthRatingExcellent;

  /// No description provided for @healthRatingGood.
  ///
  /// In vi, this message translates to:
  /// **'Khá Ổn Định'**
  String get healthRatingGood;

  /// No description provided for @healthRatingAverage.
  ///
  /// In vi, this message translates to:
  /// **'Trung Bình'**
  String get healthRatingAverage;

  /// No description provided for @healthRatingNeedsAttention.
  ///
  /// In vi, this message translates to:
  /// **'Cần Cân Đối'**
  String get healthRatingNeedsAttention;

  /// No description provided for @debtsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sổ Ghi Nợ'**
  String get debtsTitle;

  /// No description provided for @accentColor.
  ///
  /// In vi, this message translates to:
  /// **'Màu ứng dụng'**
  String get accentColor;

  /// No description provided for @searchTransactionsTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm giao dịch'**
  String get searchTransactionsTooltip;

  /// No description provided for @type.
  ///
  /// In vi, this message translates to:
  /// **'Loại'**
  String get type;

  /// No description provided for @transactionType.
  ///
  /// In vi, this message translates to:
  /// **'Loại giao dịch'**
  String get transactionType;

  /// No description provided for @debtSummaryLent.
  ///
  /// In vi, this message translates to:
  /// **'Người nợ tôi'**
  String get debtSummaryLent;

  /// No description provided for @debtSummaryBorrowed.
  ///
  /// In vi, this message translates to:
  /// **'Tôi nợ người ta'**
  String get debtSummaryBorrowed;

  /// No description provided for @debtNewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận nợ mới'**
  String get debtNewTitle;

  /// No description provided for @debtEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa khoản nợ'**
  String get debtEditTitle;

  /// No description provided for @debtPersonLentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Người vay (Ai nợ bạn?) *'**
  String get debtPersonLentLabel;

  /// No description provided for @debtPersonBorrowedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Người cho vay (Bạn nợ ai?) *'**
  String get debtPersonBorrowedLabel;

  /// No description provided for @debtAmountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền nợ ({currency}) *'**
  String debtAmountLabel(String currency);

  /// No description provided for @savingsDepositSheetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tích lũy vào heo đất'**
  String get savingsDepositSheetTitle;

  /// No description provided for @savingsWithdrawSheetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rút tiền tiết kiệm'**
  String get savingsWithdrawSheetTitle;

  /// No description provided for @debtSubmitNew.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận nợ'**
  String get debtSubmitNew;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @loadingCategories.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh mục...'**
  String get loadingCategories;

  /// No description provided for @greetingMorning.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi sáng'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi chiều'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi tối'**
  String get greetingEvening;

  /// No description provided for @smartPaceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp độ chi tiêu thông minh'**
  String get smartPaceTitle;

  /// No description provided for @smartPaceSafeToSpend.
  ///
  /// In vi, this message translates to:
  /// **'Mức chi an toàn hôm nay'**
  String get smartPaceSafeToSpend;

  /// No description provided for @smartPaceDaysLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày trong tháng'**
  String smartPaceDaysLeft(int days);

  /// No description provided for @smartPaceOnTrack.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu rất cân đối'**
  String get smartPaceOnTrack;

  /// No description provided for @smartPaceOverPace.
  ///
  /// In vi, this message translates to:
  /// **'Vượt nhịp độ an toàn'**
  String get smartPaceOverPace;

  /// No description provided for @homeActionTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển ví'**
  String get homeActionTransfer;

  /// No description provided for @homeActionAiAssistant.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý AI'**
  String get homeActionAiAssistant;

  /// No description provided for @homeActionExploreMore.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get homeActionExploreMore;

  /// No description provided for @toolsAndFeatures.
  ///
  /// In vi, this message translates to:
  /// **'Công cụ & Tiện ích'**
  String get toolsAndFeatures;

  /// No description provided for @reportsVsLastMonth.
  ///
  /// In vi, this message translates to:
  /// **'So với tháng trước'**
  String get reportsVsLastMonth;

  /// No description provided for @reportsSpendingIncreased.
  ///
  /// In vi, this message translates to:
  /// **'Tăng {percent}%'**
  String reportsSpendingIncreased(String percent);

  /// No description provided for @reportsSpendingDecreased.
  ///
  /// In vi, this message translates to:
  /// **'Giảm {percent}%'**
  String reportsSpendingDecreased(String percent);

  /// No description provided for @budgetRemainingDays.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày'**
  String budgetRemainingDays(int days);

  /// No description provided for @budgetDailyRecommended.
  ///
  /// In vi, this message translates to:
  /// **'Chi tối đa {amount}/ngày'**
  String budgetDailyRecommended(String amount);

  /// No description provided for @cashflowRatio.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ dòng tiền'**
  String get cashflowRatio;

  /// No description provided for @incomeRatio.
  ///
  /// In vi, this message translates to:
  /// **'{percent}% Thu'**
  String incomeRatio(int percent);

  /// No description provided for @expenseRatio.
  ///
  /// In vi, this message translates to:
  /// **'{percent}% Chi'**
  String expenseRatio(int percent);

  /// No description provided for @filterDateAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterDateAll;

  /// No description provided for @filterDateThisMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng này'**
  String get filterDateThisMonth;

  /// No description provided for @filterDateLastMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng trước'**
  String get filterDateLastMonth;

  /// No description provided for @filterDateLast30Days.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày qua'**
  String get filterDateLast30Days;

  /// No description provided for @filterDateThisYear.
  ///
  /// In vi, this message translates to:
  /// **'Năm nay'**
  String get filterDateThisYear;

  /// No description provided for @filterActiveCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} bộ lọc đang áp dụng'**
  String filterActiveCount(int count);

  /// No description provided for @filterAllCategories.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả danh mục'**
  String get filterAllCategories;

  /// No description provided for @filterAllWallets.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả ví'**
  String get filterAllWallets;

  /// No description provided for @filterTransactionType.
  ///
  /// In vi, this message translates to:
  /// **'Loại giao dịch'**
  String get filterTransactionType;

  /// No description provided for @filterApply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng bộ lọc'**
  String get filterApply;

  /// No description provided for @transactionCountTotal.
  ///
  /// In vi, this message translates to:
  /// **'{count} giao dịch'**
  String transactionCountTotal(int count);

  /// No description provided for @filterReset.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại'**
  String get filterReset;

  /// No description provided for @filterSelectedCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} đang chọn'**
  String filterSelectedCount(int count);

  /// No description provided for @filterCustomDate.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng ngày tuỳ chọn'**
  String get filterCustomDate;

  /// No description provided for @quickFilterTooltipAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả loại giao dịch'**
  String get quickFilterTooltipAll;

  /// No description provided for @quickFilterTooltipExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lọc chi tiêu'**
  String get quickFilterTooltipExpense;

  /// No description provided for @quickFilterTooltipIncome.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lọc thu nhập'**
  String get quickFilterTooltipIncome;

  /// No description provided for @quickFilterTooltipTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lọc chuyển khoản'**
  String get quickFilterTooltipTransfer;
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
