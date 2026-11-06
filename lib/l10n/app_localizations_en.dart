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
  String get dangerZoneSection => 'DANGER ZONE';

  @override
  String get deleteDataAndAccountSubtitle =>
      'Permanently erase all data, transactions, and account';

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
  String get suggestedNotes => 'Suggested notes';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'e.g., work, family';

  @override
  String get frequentTags => 'Frequent tags';

  @override
  String get addTag => 'Add tag';

  @override
  String get addTagHint => 'Type a tag name and tap Add or Enter...';

  @override
  String get zeroSuggestions => 'Zero suggestions';

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

  @override
  String get debtBookTitle => 'Debt Book';

  @override
  String get debtNew => 'New Debt';

  @override
  String get debtEdit => 'Edit Debt';

  @override
  String get debtDelete => 'Delete Debt';

  @override
  String get debtDeleteConfirmTitle => 'Confirm Deletion';

  @override
  String debtDeleteConfirmBody(String name) {
    return 'Are you sure you want to delete the debt for $name?';
  }

  @override
  String get debtLent => 'Lent';

  @override
  String get debtBorrowed => 'Borrowed';

  @override
  String get debtLentSubtitle => 'To Collect';

  @override
  String get debtBorrowedSubtitle => 'To Repay';

  @override
  String get debtTotalLent => 'Total Lent';

  @override
  String get debtTotalBorrowed => 'Total Borrowed';

  @override
  String get debtFilterAll => 'All';

  @override
  String get debtFilterUnsettled => 'Unsettled';

  @override
  String get debtFilterSettled => 'Settled';

  @override
  String get debtFilterLent => 'Lent';

  @override
  String get debtFilterBorrowed => 'Borrowed';

  @override
  String get debtRemaining => 'Remaining';

  @override
  String debtDueDate(String date) {
    return 'Due: $date';
  }

  @override
  String get debtRepay => 'Repay';

  @override
  String get debtCollect => 'Collect';

  @override
  String get debtEmpty => 'No debt records yet';

  @override
  String get debtEmptySubtitle =>
      'Track money lent or borrowed to keep clear records.';

  @override
  String get debtRepaymentTitle => 'Record Payment';

  @override
  String debtRepaymentCollectTitle(String name) {
    return 'Collect debt from $name';
  }

  @override
  String debtRepaymentPayTitle(String name) {
    return 'Repay debt to $name';
  }

  @override
  String get debtRepaymentAmount => 'Payment Amount';

  @override
  String get debtRepaymentWallet => 'Wallet';

  @override
  String get debtRepaymentFull => 'Pay Full Amount';

  @override
  String debtRepaymentSuccess(String amount) {
    return 'Recorded payment of $amount';
  }

  @override
  String get debtUpdatedSuccess => 'Debt updated successfully';

  @override
  String get debtAddedSuccess => 'New debt recorded successfully';

  @override
  String get debtPersonName => 'Person Name';

  @override
  String get debtPersonNameHint => 'e.g., John, Sarah...';

  @override
  String get debtPhoneNumber => 'Phone number (optional)';

  @override
  String get debtTypeLent => 'I lent (Others owe me)';

  @override
  String get debtTypeBorrowed => 'I borrowed (I owe others)';

  @override
  String get debtAmountRequired => 'Please enter a valid amount greater than 0';

  @override
  String get debtPersonRequired => 'Please enter person name';

  @override
  String get savingsTitle => 'Savings & Goals';

  @override
  String get savingsNewGoal => 'New Goal';

  @override
  String get savingsEditGoal => 'Edit Goal';

  @override
  String get savingsDeleteGoal => 'Delete Goal';

  @override
  String savingsDeleteConfirmTitle(String title) {
    return 'Delete goal \"$title\"';
  }

  @override
  String get savingsDeleteConfirmBody =>
      'This will delete the savings goal. Wallet transaction history remains unchanged.';

  @override
  String get savingsTotalSaved => 'Total Saved';

  @override
  String get savingsTotalTarget => 'Total Target';

  @override
  String get savingsSummaryProgress => 'TOTAL SAVINGS PROGRESS';

  @override
  String savingsActiveCount(int active, int completed) {
    return '$active active • $completed completed';
  }

  @override
  String savingsDaysRemaining(int days) {
    return '$days days left';
  }

  @override
  String savingsDailyNeeded(String amount) {
    return 'Need $amount/day';
  }

  @override
  String get savingsDeposit => 'Deposit';

  @override
  String get savingsWithdraw => 'Withdraw';

  @override
  String get savingsGoalCompleted => 'Completed!';

  @override
  String savingsGoalTarget(String amount) {
    return 'Target: $amount';
  }

  @override
  String savingsGoalRemaining(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get savingsEmpty => 'No savings goals yet';

  @override
  String get savingsEmptySubtitle =>
      'Set up emergency, travel, or purchase funds to track daily savings.';

  @override
  String get savingsCreateFirst => 'Create first goal';

  @override
  String get savingsGoalName => 'Goal Name';

  @override
  String get savingsGoalNameHint =>
      'e.g., Emergency Fund, New Car, Vacation...';

  @override
  String get savingsTargetAmount => 'Target Amount';

  @override
  String get savingsDeadline => 'Target Deadline';

  @override
  String get savingsNoDeadline => 'No deadline set';

  @override
  String get savingsLinkedWallet => 'Linked Wallet (optional)';

  @override
  String get savingsNoLinkedWallet => 'No specific wallet';

  @override
  String get savingsGoalIcon => 'Goal Icon';

  @override
  String get savingsGoalColor => 'Theme Color';

  @override
  String savingsDepositSuccess(String amount, String title) {
    return 'Added $amount to $title!';
  }

  @override
  String savingsWithdrawSuccess(String amount, String title) {
    return 'Withdrew $amount from $title';
  }

  @override
  String get savingsAmountRequired => 'Please enter a valid target amount';

  @override
  String get savingsNoWalletAvailable => 'No wallets available';

  @override
  String get savingsTargetRequired => 'Please enter a goal name';

  @override
  String get recurringTitle => 'Bills & Subscriptions';

  @override
  String get recurringNew => 'Add Subscription';

  @override
  String get recurringEdit => 'Edit';

  @override
  String get recurringDelete => 'Delete';

  @override
  String get recurringDeleteConfirmTitle => 'Delete recurring bill';

  @override
  String recurringDeleteConfirmBody(String title) {
    return 'Are you sure you want to delete \"$title\"? Past recorded transactions will not be affected.';
  }

  @override
  String get recurringEstimatedMonthly => 'ESTIMATED MONTHLY COST';

  @override
  String recurringActiveCount(int count) {
    return '$count active subscriptions';
  }

  @override
  String get recurringDueBills => 'BILLS DUE FOR PAYMENT';

  @override
  String get recurringActiveSection => 'ACTIVE RECURRING SUBSCRIPTIONS';

  @override
  String get recurringPausedSection => 'PAUSED SUBSCRIPTIONS';

  @override
  String recurringNextDue(String date) {
    return 'Due: $date';
  }

  @override
  String get recurringIntervalDaily => 'Daily';

  @override
  String get recurringIntervalWeekly => 'Weekly';

  @override
  String get recurringIntervalBiweekly => 'Bi-weekly';

  @override
  String get recurringIntervalMonthly => 'Monthly';

  @override
  String get recurringIntervalYearly => 'Yearly';

  @override
  String get recurringMarkPaid => 'Mark as Paid';

  @override
  String get recurringPause => 'Pause';

  @override
  String get recurringResume => 'Resume';

  @override
  String get recurringAutoExecute => 'Auto-record on due date';

  @override
  String get recurringAutoExecuteSubtitle =>
      'Automatically deduct wallet and create transaction without manual confirmation';

  @override
  String get recurringEmpty => 'No recurring bills yet';

  @override
  String get recurringEmptySubtitle =>
      'Track rent, utilities, Netflix, Spotify, or recurring salary.';

  @override
  String recurringRecordedSuccess(String title) {
    return 'Recorded transaction: $title';
  }

  @override
  String get recurringWalletRequired => 'Please choose a payment wallet';

  @override
  String get recurringFrequency => 'Repeat Interval';

  @override
  String get recurringStartDate => 'Start / Due Date';

  @override
  String get ledgersTitle => 'Manage Ledgers';

  @override
  String get ledgerNew => 'New Ledger';

  @override
  String get ledgerEdit => 'Edit';

  @override
  String get ledgerDelete => 'Delete Ledger';

  @override
  String ledgerDeleteConfirmTitle(String name) {
    return 'Delete ledger \"$name\"';
  }

  @override
  String get ledgerDeleteConfirmBody =>
      'This will delete this ledger from your device.';

  @override
  String get ledgerPersonal => 'Personal';

  @override
  String get ledgerFamily => 'Family';

  @override
  String get ledgerBusiness => 'Business / Project';

  @override
  String get ledgerCustom => 'Custom';

  @override
  String get ledgerActiveBadge => 'Active';

  @override
  String get ledgerSelectActive => 'Set as Active Ledger';

  @override
  String get ledgerSwitcherTitle => 'Select Ledger';

  @override
  String get ledgerSwitcherSubtitle =>
      'Switch seamlessly between personal, family, and work finances';

  @override
  String get ledgerName => 'Ledger Name';

  @override
  String get ledgerNameHint => 'e.g., Personal, Family, Freelance Project...';

  @override
  String get ledgerType => 'Ledger Type';

  @override
  String get ledgerIcon => 'Icon';

  @override
  String get ledgerColor => 'Theme Color';

  @override
  String get ledgerNameRequired => 'Please enter ledger name';

  @override
  String get txTimeAndDetails => 'TIME & DETAILS';

  @override
  String get txSourceWallet => 'Source Wallet';

  @override
  String get txDestWallet => 'Destination Wallet';

  @override
  String get txSelectWallet => 'Select Wallet';

  @override
  String get txSwapWallets => 'Swap Wallets';

  @override
  String get txToday => 'Today';

  @override
  String get txChangeDate => 'Change';

  @override
  String get txRestoreDefaultCategories => 'Restore Defaults';

  @override
  String get txEmptyCategoriesMsg =>
      'Please restore default categories or create a new one to categorize transactions.';

  @override
  String get txCategoryOther => 'Other';

  @override
  String get txCategoryAdd => 'Add';

  @override
  String get txCategorySearchPlaceholder => 'Search categories...';

  @override
  String get txCategoryNotFound => 'No categories found';

  @override
  String get txCategoryCreateNew => 'Create New';

  @override
  String get txUpdateTransaction => 'Update Transaction';

  @override
  String get txDeleteLabel => 'Delete';

  @override
  String homeDueBillsBanner(int count) {
    return '$count recurring bills are due for payment!';
  }

  @override
  String get homeSavingsStripTitle => 'Savings Goals';

  @override
  String get homeDebtsStripTitle => 'Recent Debts';

  @override
  String get homeActionTransaction => 'Transaction';

  @override
  String get homeActionWallet => 'Wallets';

  @override
  String get homeActionSavings => 'Savings';

  @override
  String get homeActionRecurring => 'Recurring';

  @override
  String get homeActionDebts => 'Debts';

  @override
  String get homeActionCategories => 'Categories';

  @override
  String get settingsDataSection => 'DATA & MANAGEMENT';

  @override
  String get settingsDebtsSubtitle => 'Manage money lent & borrowed';

  @override
  String get settingsRecurringSubtitle => 'Recurring expenses & bills';

  @override
  String get settingsSavingsSubtitle => 'Financial goals & savings';

  @override
  String get settingsLedgersSubtitle => 'Personal, family & work ledgers';

  @override
  String get settingsDemoTag => 'Offline Demo';

  @override
  String get settingsGoogleTag => 'Google Synced';

  @override
  String get settingsAppIcon => 'App Icon';

  @override
  String get settingsAppIconSubtitle => 'Customize app icon style';

  @override
  String get settingsThemeDefault => 'Default (Emerald Jade)';

  @override
  String get settingsThemeClassic => 'Classic iOS (Ocean Blue)';

  @override
  String get settingsThemeMinimal => 'Minimalist (Pure Dark)';

  @override
  String get settingsThemeSunset => 'Sunset (Coral Glow)';

  @override
  String settingsWalletsCount(int count) {
    return '$count wallets';
  }

  @override
  String settingsCategoriesCount(int count) {
    return '$count categories';
  }

  @override
  String settingsDebtsCount(int count) {
    return '$count debts';
  }

  @override
  String get reportsFinancialHealth => 'Financial Health';

  @override
  String get reportsSpendingHeatmap => 'Daily Spending Heatmap';

  @override
  String get reportsMonthTotalExpense => 'Monthly Total Expense';

  @override
  String reportsDailyAverage(String amount) {
    return 'Average: $amount/day';
  }

  @override
  String reportsMaxDay(String amount) {
    return 'Peak Day: $amount';
  }

  @override
  String reportsSelectedDay(String date) {
    return 'Details for $date';
  }

  @override
  String get reportsNoExpenseOnDay => 'No expenses recorded on this day';

  @override
  String get categoryCreateNew => 'Create New Category';

  @override
  String get categoryIconAndColor => 'Icon & Color';

  @override
  String get categoryChooseIcon => 'Choose Icon';

  @override
  String get categoryChooseColor => 'Choose Color';

  @override
  String get savingsProgress => 'progress';

  @override
  String get savingsTarget => 'Target';

  @override
  String get savingsRemaining => 'Remaining';

  @override
  String get savingsDepositAction => 'Deposit';

  @override
  String get savingsWithdrawAction => 'Withdraw';

  @override
  String get savingsMotivationNote => 'Motivation note';

  @override
  String get savingsQuickRemaining => 'Remaining part';

  @override
  String get savingsQuickAll => 'Withdraw all';

  @override
  String get savingsWalletSource => 'Source wallet';

  @override
  String get savingsWalletDest => 'Destination wallet';

  @override
  String get savingsConfirmDeposit => 'Confirm deposit';

  @override
  String get savingsConfirmWithdraw => 'Confirm withdrawal';

  @override
  String get savingsEditGoalTitle => 'Edit Savings Goal';

  @override
  String get savingsNewGoalTitle => 'New Savings Goal';

  @override
  String get recurringIntervalQuarterly => 'Quarterly';

  @override
  String get recurringFrequencyLabel => 'Repeat frequency';

  @override
  String get recurringStartDateLabel => 'Start date';

  @override
  String get recurringNextDueDateLabel => 'Next due date';

  @override
  String get recurringTitleLabel => 'Bill / Subscription name';

  @override
  String get recurringTitleRequired => 'Please enter bill title';

  @override
  String get recurringAmountLabel => 'Amount';

  @override
  String get recurringAmountRequired => 'Please enter a valid amount';

  @override
  String get recurringWalletLabel => 'Payment wallet';

  @override
  String get recurringCategoryLabel => 'Expense category';

  @override
  String get recurringConfirmCreate => 'Add recurring plan';

  @override
  String get recurringConfirmUpdate => 'Update recurring plan';

  @override
  String get recurringEditTitle => 'Edit Recurring Plan';

  @override
  String get recurringNewTitle => 'New Recurring Bill';

  @override
  String get ledgerEditTitle => 'Edit Ledger';

  @override
  String get ledgerNewTitle => 'New Ledger Book';

  @override
  String get ledgerDescLabel => 'Description (Optional)';

  @override
  String get ledgerDescHint => 'Detailed ledger description';

  @override
  String get ledgerConfirmCreate => 'Create ledger';

  @override
  String get ledgerConfirmUpdate => 'Update ledger';

  @override
  String ledgerSharedWith(int count) {
    return 'Shared with: $count members';
  }

  @override
  String get transactionTimeDetails => 'TIME & DETAILS';

  @override
  String get transactionSelectSourceWallet => 'Select source wallet';

  @override
  String get transactionSelectDestWallet => 'Select destination wallet';

  @override
  String get transactionOther => 'Other';

  @override
  String get transactionAdd => 'Add';

  @override
  String get transactionCreateNew => 'Create new';

  @override
  String get settingsDataAndManagement => 'DATA & MANAGEMENT';

  @override
  String get settingsAccountGoogle => 'Google Account';

  @override
  String get settingsAccountGuest => 'Guest (Offline)';

  @override
  String get selectWallet => 'Select wallet';

  @override
  String get swapWallets => 'Swap wallets';

  @override
  String get changeDate => 'Change';

  @override
  String get noCategories => 'No categories available';

  @override
  String get noCategoriesFound => 'No categories found';

  @override
  String get searchCategories => 'Search categories...';

  @override
  String get restoreDefaultCategories => 'Restore defaults';

  @override
  String get noCategoriesDescription =>
      'Please restore default categories or create a new category to classify transactions.';

  @override
  String get clear => 'Clear';

  @override
  String get back => 'Back';

  @override
  String get updateTransaction => 'Update transaction';

  @override
  String get reportsShareTooltip => 'Share report';

  @override
  String get heatmapTapHint => 'Tap a day to view detailed daily spending';

  @override
  String get heatmapNoSpending => 'No spending';

  @override
  String get heatmapMonthlySummary => 'Monthly Spending Overview';

  @override
  String get heatmapNone => 'None';

  @override
  String get heatmapLess => 'Less';

  @override
  String get heatmapMore => 'More';

  @override
  String get healthSavingsRate => 'Savings rate';

  @override
  String get healthSpendingPace => 'Spending pace';

  @override
  String get healthTopCategory => 'Top expense category';

  @override
  String get healthInsufficientData => 'Insufficient data';

  @override
  String get healthRatingExcellent => 'Excellent';

  @override
  String get healthRatingGood => 'Good';

  @override
  String get healthRatingAverage => 'Average';

  @override
  String get healthRatingNeedsAttention => 'Needs Attention';

  @override
  String get debtsTitle => 'Debt Book';

  @override
  String get accentColor => 'Theme Accent Color';

  @override
  String get searchTransactionsTooltip => 'Search transactions';

  @override
  String get type => 'Type';

  @override
  String get transactionType => 'Transaction Type';

  @override
  String get debtSummaryLent => 'Owed to me';

  @override
  String get debtSummaryBorrowed => 'I owe';

  @override
  String get debtNewTitle => 'Record New Debt';

  @override
  String get debtEditTitle => 'Edit Debt Record';

  @override
  String get debtPersonLentLabel => 'Borrower (Who owes you?) *';

  @override
  String get debtPersonBorrowedLabel => 'Lender (Who do you owe?) *';

  @override
  String debtAmountLabel(String currency) {
    return 'Debt Amount ($currency) *';
  }

  @override
  String get savingsDepositSheetTitle => 'Deposit to Piggy Bank';

  @override
  String get savingsWithdrawSheetTitle => 'Withdraw from Savings';

  @override
  String get debtSubmitNew => 'Record Debt';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingCategories => 'Loading categories...';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get smartPaceTitle => 'Smart Spending Pace';

  @override
  String get smartPaceSafeToSpend => 'Safe daily budget today';

  @override
  String smartPaceDaysLeft(int days) {
    return '$days days left this month';
  }

  @override
  String get smartPaceOnTrack => 'Spending is well balanced';

  @override
  String get smartPaceOverPace => 'Over safe spending pace';

  @override
  String get homeActionTransfer => 'Transfer';

  @override
  String get homeActionAiAssistant => 'AI Assistant';

  @override
  String get homeActionExploreMore => 'More';

  @override
  String get toolsAndFeatures => 'Tools & Utilities';

  @override
  String get reportsVsLastMonth => 'vs Last Month';

  @override
  String reportsSpendingIncreased(String percent) {
    return 'Up $percent%';
  }

  @override
  String reportsSpendingDecreased(String percent) {
    return 'Down $percent%';
  }

  @override
  String budgetRemainingDays(int days) {
    return '$days days left';
  }

  @override
  String budgetDailyRecommended(String amount) {
    return 'Safe max: $amount/day';
  }

  @override
  String get cashflowRatio => 'Cashflow Ratio';

  @override
  String incomeRatio(int percent) {
    return '$percent% In';
  }

  @override
  String expenseRatio(int percent) {
    return '$percent% Out';
  }

  @override
  String get filterDateAll => 'All time';

  @override
  String get filterDateThisMonth => 'This month';

  @override
  String get filterDateLastMonth => 'Last month';

  @override
  String get filterDateLast30Days => 'Last 30 days';

  @override
  String get filterDateThisYear => 'This year';

  @override
  String filterActiveCount(int count) {
    return '$count active filters';
  }

  @override
  String get filterAllCategories => 'All categories';

  @override
  String get filterAllWallets => 'All wallets';

  @override
  String get filterTransactionType => 'Transaction type';

  @override
  String get filterApply => 'Apply filter';
}
