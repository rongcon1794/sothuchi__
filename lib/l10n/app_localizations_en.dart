// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'So Thu Chi';

  @override
  String get appTagline => 'Smart & clean personal finance tracker';

  @override
  String get navOverview => 'Overview';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get onboarding1Title => 'Log expenses in 3 seconds';

  @override
  String get onboarding1Subtitle =>
      'Track every income, expense, and wallet transfer with exact integer precision and crystal-clear formatting.';

  @override
  String get onboarding2Title => 'Multi-wallet & proactive budgets';

  @override
  String get onboarding2Subtitle =>
      'Manage cash, bank accounts, and e-wallets with early threshold warnings before overspending.';

  @override
  String get onboarding3Title => 'Offline-ready, instant cloud sync';

  @override
  String get onboarding3Subtitle =>
      'Record transactions without internet. Your data stays private and syncs automatically once back online.';

  @override
  String get signInTitle => 'Welcome to So Thu Chi';

  @override
  String get signInSubtitle =>
      'Sign in with your Google account to securely sync your financial data across devices.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get tryOfflineDemo => 'Try Offline Demo Mode (Firebase unconfigured)';

  @override
  String get firebaseUnconfiguredBanner =>
      'Firebase configuration was not detected on this device. View the setup guide or explore all features in local offline mode.';

  @override
  String get viewSetupGuide => 'View Setup Guide';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out of your account?';

  @override
  String get signOutConfirmBody =>
      'You can sign back in anytime to resume cloud synchronization.';

  @override
  String get deleteAccount => 'Delete account & all data';

  @override
  String get deleteAccountConfirmTitle => 'Permanently delete account?';

  @override
  String get deleteAccountConfirmBody =>
      'All your wallets, categories, transactions, budgets, and profile data will be permanently erased and cannot be undone.';

  @override
  String get deleteAccountAction => 'Delete permanently';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get undo => 'Undo';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get totalBalance => 'Total Net Balance';

  @override
  String get showBalance => 'Show balance';

  @override
  String get hideBalance => 'Hide balance';

  @override
  String get thisMonthSummary => 'This Month';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get transfer => 'Transfer';

  @override
  String get netBalance => 'Net Cashflow';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View all';

  @override
  String get quickAddTransaction => 'Add transaction';

  @override
  String get walletsTitle => 'Wallets & Accounts';

  @override
  String get manageWallets => 'Manage wallets';

  @override
  String get addWallet => 'Add wallet';

  @override
  String get editWallet => 'Edit wallet';

  @override
  String get walletName => 'Wallet name';

  @override
  String get walletNameHint => 'e.g., Cash, Vietcombank, MoMo...';

  @override
  String get walletType => 'Account type';

  @override
  String get walletTypeCash => 'Cash';

  @override
  String get walletTypeBank => 'Bank Account';

  @override
  String get walletTypeEwallet => 'E-Wallet';

  @override
  String get walletTypeCard => 'Credit / Debit Card';

  @override
  String get initialBalance => 'Initial balance';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get archiveWallet => 'Archive wallet';

  @override
  String get unarchiveWallet => 'Unarchive wallet';

  @override
  String get archivedWallets => 'Archived wallets';

  @override
  String get activeWallets => 'Active wallets';

  @override
  String get transferBetweenWallets => 'Transfer between wallets';

  @override
  String get fromWallet => 'From source wallet';

  @override
  String get toWallet => 'To destination wallet';

  @override
  String get emptyWalletsTitle => 'No wallets yet';

  @override
  String get emptyWalletsSubtitle =>
      'Create your first wallet to start tracking your daily cashflow.';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryNameHint => 'e.g., Coffee, Fuel, Rent...';

  @override
  String get defaultCategoryBadge => 'Default';

  @override
  String get selectIcon => 'Select icon';

  @override
  String get selectColor => 'Select color';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get amount => 'Amount';

  @override
  String get amountRequiredError => 'Please enter an amount greater than 0';

  @override
  String get selectCategory => 'Select category';

  @override
  String get categoryRequiredError => 'Please choose a category';

  @override
  String get walletRequiredError => 'Please choose a wallet';

  @override
  String get sameWalletTransferError =>
      'Source and destination wallets must differ';

  @override
  String get date => 'Date';

  @override
  String get note => 'Note';

  @override
  String get noteHint => 'Add a short note (e.g., Lunch with team)...';

  @override
  String get tags => 'Tags (comma-separated)';

  @override
  String get tagsHint => 'e.g., work, family';

  @override
  String get searchTransactionsHint => 'Search notes or tags...';

  @override
  String get filterTransactions => 'Filter transactions';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get dateRange => 'Date range';

  @override
  String get selectDateRange => 'Choose date range';

  @override
  String get emptyTransactionsTitle => 'No transactions yet';

  @override
  String get emptyTransactionsSubtitle =>
      'Tap + to record your first income or expense.';

  @override
  String get noMatchingTransactionsTitle => 'No matching transactions';

  @override
  String get noMatchingTransactionsSubtitle =>
      'Try adjusting your search keywords or clearing active filters.';

  @override
  String get budgetsTitle => 'Monthly Budgets';

  @override
  String get addBudget => 'Create budget';

  @override
  String get editBudget => 'Edit budget';

  @override
  String get overallMonthlyBudget => 'Overall monthly budget';

  @override
  String get categoryBudget => 'Category budget';

  @override
  String get budgetScope => 'Budget scope';

  @override
  String get budgetLimit => 'Monthly limit';

  @override
  String alertThresholdLabel(int percent) {
    return 'Alert at threshold ($percent%)';
  }

  @override
  String budgetSpentOf(String spent, String limit) {
    return 'Spent $spent of $limit';
  }

  @override
  String budgetRemaining(String amount) {
    return '$amount remaining';
  }

  @override
  String budgetExceededBy(String amount) {
    return 'Over budget by $amount';
  }

  @override
  String budgetWarningBanner(String name, int percent) {
    return 'Alert: $name reached $percent% of monthly limit!';
  }

  @override
  String get emptyBudgetsTitle => 'No budgets configured';

  @override
  String get emptyBudgetsSubtitle =>
      'Set monthly spending limits to get alerted before you overspend.';

  @override
  String get reportsTitle => 'Reports & Analytics';

  @override
  String get expenseByCategory => 'Expenses by Category';

  @override
  String get incomeVsExpenseTrend => 'Income vs Expense Trend (6 months)';

  @override
  String get savingsRate => 'Savings rate';

  @override
  String get noReportDataTitle => 'No report data for this month';

  @override
  String get noReportDataSubtitle =>
      'Record income and expenses to unlock visual charts and insights.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance & Display';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get defaultCurrency => 'Default currency';

  @override
  String get securitySection => 'Security & Data';

  @override
  String get biometricLock => 'Biometric app lock';

  @override
  String get biometricLockSubtitle =>
      'Require fingerprint / Face ID when opening the app';

  @override
  String get biometricNotAvailable =>
      'Biometric authentication is not available or enrolled on this device.';

  @override
  String get biometricPromptReason => 'Authenticate to unlock So Thu Chi';

  @override
  String get appLockedTitle => 'So Thu Chi is Locked';

  @override
  String get appLockedSubtitle =>
      'Verify your identity to access your personal financial data.';

  @override
  String get unlockNow => 'Unlock now';

  @override
  String get exportCsv => 'Export transactions to CSV';

  @override
  String get exportCsvSubtitle =>
      'Save or share your transaction ledger for Excel / Google Sheets';

  @override
  String exportCsvSuccess(int count) {
    return 'Exported CSV ($count transactions)';
  }

  @override
  String get aboutSection => 'About & Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get aboutApp => 'About So Thu Chi';

  @override
  String get accountSection => 'Account';

  @override
  String get offlineIndicator =>
      'Offline — Changes will sync automatically when online';

  @override
  String get syncingIndicator => 'Syncing changes to cloud...';

  @override
  String get syncedIndicator => 'Synced';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'No internet connection. Please check your network.';

  @override
  String get errorAuthCancelled => 'Google Sign-In was cancelled.';

  @override
  String get errorAuthFailed =>
      'Sign-in failed. Please verify your Google/Firebase configuration and try again.';

  @override
  String get errorPermissionDenied =>
      'You do not have permission to perform this action.';

  @override
  String get errorValidation => 'Invalid input. Please review your entries.';

  @override
  String get catFood => 'Food & Dining';

  @override
  String get catTransport => 'Transportation';

  @override
  String get catHousing => 'Housing';

  @override
  String get catBills => 'Bills & Utilities';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catHealth => 'Healthcare';

  @override
  String get catEducation => 'Education';

  @override
  String get catSalary => 'Salary';

  @override
  String get catBonus => 'Bonus';

  @override
  String get catInvestment => 'Investments & Interest';

  @override
  String get catOtherExpense => 'Other Expense';

  @override
  String get catOtherIncome => 'Other Income';

  @override
  String get defaultCashWalletName => 'Cash';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get balanceHidden => 'Balance hidden';

  @override
  String get differentCurrencyTransferError =>
      'Transfers require both wallets to use the same currency';

  @override
  String get moreOptions => 'More options';
}
