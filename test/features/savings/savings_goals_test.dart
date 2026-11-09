import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/savings/data/repositories/firestore_savings_goal_repository.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/screens/savings_goals_screen.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_goal_form_sheet.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('SavingsGoal Domain Entity & Calculations', () {
    test('computes progress, remaining and daily/monthly savings correctly', () {
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 60)); // 60 days remaining

      final goal = SavingsGoal(
        id: 'goal_car',
        title: 'Mua xe máy mới',
        targetAmount: 30000000, // 30 triệu
        currentAmount: 12000000, // 12 triệu (40%)
        currency: 'VND',
        deadline: deadline,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.progress, 0.4);
      expect(goal.progressPercent, 40);
      expect(goal.isReached, isFalse);
      expect(goal.remainingAmount, 18000000);

      // 18,000,000 / 60 days = 300,000 VND / day
      expect(goal.recommendedDailySavings, 300000);

      // 18,000,000 / 2 months = 9,000,000 VND / month
      expect(goal.recommendedMonthlySavings, 9000000);
    });

    test('isReached returns true when current >= target', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'goal_trip',
        title: 'Du lịch Đà Lạt',
        targetAmount: 5000000,
        currentAmount: 5000000,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.progress, 1.0);
      expect(goal.progressPercent, 100);
      expect(goal.isReached, isTrue);
      expect(goal.remainingAmount, 0);
    });
  });

  group('InMemorySavingsGoalRepository Unit Tests', () {
    test('create, deposit, withdraw, and delete work with transaction store', () async {
      final accRepo = InMemoryAccountRepository();
      final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);
      final savingsRepo = InMemorySavingsGoalRepository(transactionRepository: txRepo);

      final wallet = ((await accRepo.createAccount(
        name: 'Ví tiền lương',
        type: AccountType.bank,
        initialBalance: 20000000,
        currency: 'VND',
        icon: 'bank',
        color: 0xFF007AFF,
      )) as dynamic).value as Account;

      // 1. Create Goal
      final createRes = await savingsRepo.createGoal(
        SavingsGoal(
          id: 'goal_emergency',
          title: 'Quỹ khẩn cấp',
          targetAmount: 10000000,
          currentAmount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(createRes.isSuccess, isTrue);

      // 2. Deposit 3,000,000 VND into Goal
      final depositRes = await savingsRepo.depositToGoal(
        goalId: 'goal_emergency',
        amount: 3000000,
        fromAccountId: wallet.id,
        note: 'Trích từ thưởng',
      );
      expect(depositRes.isSuccess, isTrue);

      // Goal currentAmount is updated
      var goals = await savingsRepo.watchSavingsGoals().first;
      expect(goals.first.currentAmount, 3000000);
      expect(goals.first.isCompleted, isFalse);

      // Wallet was debited
      var accounts = await accRepo.getAccounts();
      expect(accounts.first.balance, 20000000 - 3000000);

      // 3. Deposit remaining 7,000,000 VND -> marks as completed
      await savingsRepo.depositToGoal(
        goalId: 'goal_emergency',
        amount: 7000000,
        fromAccountId: wallet.id,
      );
      goals = await savingsRepo.watchSavingsGoals().first;
      expect(goals.first.currentAmount, 10000000);
      expect(goals.first.isCompleted, isTrue);

      // 4. Withdraw 1,000,000 VND back to wallet
      final withdrawRes = await savingsRepo.withdrawFromGoal(
        goalId: 'goal_emergency',
        amount: 1000000,
        toAccountId: wallet.id,
      );
      expect(withdrawRes.isSuccess, isTrue);
      goals = await savingsRepo.watchSavingsGoals().first;
      expect(goals.first.currentAmount, 9000000);
      expect(goals.first.isCompleted, isFalse); // Not completed anymore

      accounts = await accRepo.getAccounts();
      expect(accounts.first.balance, 20000000 - 10000000 + 1000000);

      // 5. Delete Goal
      final deleteRes = await savingsRepo.deleteGoal('goal_emergency');
      expect(deleteRes.isSuccess, isTrue);
      goals = await savingsRepo.watchSavingsGoals().first;
      expect(goals.isEmpty, isTrue);
    });
  });

  group('SavingsGoalsScreen Widget Tests', () {
    late InMemoryAccountRepository accRepo;
    late InMemoryCategoryRepository catRepo;
    late InMemoryTransactionRepository txRepo;
    late InMemorySavingsGoalRepository savingsRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'system',
        'locale_code': 'vi',
        'currency_code': 'VND',
        'onboarding_completed': true,
      });
      prefs = await SharedPreferences.getInstance();
      accRepo = InMemoryAccountRepository();
      catRepo = InMemoryCategoryRepository();
      txRepo = InMemoryTransactionRepository(accountRepo: accRepo);
      savingsRepo = InMemorySavingsGoalRepository(transactionRepository: txRepo);

      await catRepo.seedDefaultCategoriesIfNeeded();
      final wallet = ((await accRepo.createAccount(
        name: 'Ví chính',
        type: AccountType.cash,
        initialBalance: 50000000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF00A86B,
      )) as dynamic).value as Account;

      await savingsRepo.createGoal(
        SavingsGoal(
          id: 'goal_macbook',
          title: 'MacBook Pro M4',
          targetAmount: 40000000,
          currentAmount: 10000000,
          deadline: DateTime.now().add(const Duration(days: 90)),
          icon: 'laptop',
          color: 0xFF007AFF,
          linkedAccountId: wallet.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          accountRepositoryProvider.overrideWithValue(accRepo),
          categoryRepositoryProvider.overrideWithValue(catRepo),
          transactionRepositoryProvider.overrideWithValue(txRepo),
          savingsGoalRepositoryProvider.overrideWithValue(savingsRepo),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: const SavingsGoalsScreen(),
        ),
      );
    }

    testWidgets('renders goals, progress arc, and opens deposit modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('Heo Đất & Tiết Kiệm'), findsOneWidget);

      // Hero banner
      expect(find.text('TỔNG TIẾN ĐỘ TÍCH LŨY'), findsOneWidget);

      // Active goal
      expect(find.text('MacBook Pro M4'), findsOneWidget);
      expect(find.text('25%'), findsWidgets);

      // Quick deposit button
      expect(find.text('Nạp tích lũy'), findsOneWidget);
      await tester.tap(find.text('Nạp tích lũy'));
      await tester.pumpAndSettle();

      // Modal bottom sheet opened
      expect(find.text('Tích lũy vào heo đất'), findsOneWidget);
      expect(find.text('+500k'), findsOneWidget);

      // Tap preset +500k
      await tester.tap(find.text('+500k'));
      await tester.pump();

      // Submit deposit
      await tester.tap(find.text('Xác nhận tích lũy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Wallet debited and goal updated
      final accounts = await accRepo.getAccounts();
      expect(accounts.first.balance, 50000000 - 500000);
    });

    testWidgets('SavingsGoalFormSheet renders Apple HIG redesign, inspiration chips, and creates goal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap FAB to open SavingsGoalFormSheet
      final addFab = find.byTooltip('Mục tiêu mới');
      expect(addFab, findsOneWidget);
      await tester.tap(addFab);
      await tester.pumpAndSettle();

      // Verify header and redesigned Apple sections
      expect(find.text('Tạo mục tiêu tiết kiệm mới'), findsOneWidget);
      expect(find.text('GỢI Ý MỤC TIÊU THỊNH HÀNH'), findsOneWidget);
      expect(find.text('SỐ TIỀN CẦN ĐẠT ĐƯỢC'), findsWidgets);
      expect(find.text('HẠN HOÀN THÀNH (DEADLINE)'), findsWidgets);
      expect(find.text('VÍ LIÊN KẾT (TÙY CHỌN)'), findsOneWidget);
      expect(find.text('MÀU SẮC & BIỂU TƯỢNG NHẬN DIỆN'), findsOneWidget);

      // Verify inspiration chips exist
      expect(find.text('Quỹ khẩn cấp 6 tháng'), findsOneWidget);
      expect(find.text('Chuyến du lịch mơ ước'), findsOneWidget);

      // Tap inspiration chip
      await tester.tap(find.text('Chuyến du lịch mơ ước'));
      await tester.pumpAndSettle();

      // Verify title field is populated
      expect(find.text('Chuyến du lịch mơ ước'), findsWidgets);

      // Tap quick amount preset
      expect(find.text('5 triệu'), findsOneWidget);
      await tester.tap(find.text('5 triệu'));
      await tester.pumpAndSettle();

      // Verify formatted amount
      expect(find.text('5.000.000'), findsOneWidget);

      // Verify smart pace insight is calculated and displayed
      expect(find.text('NHỊP ĐỘ TÍCH LŨY THÔNG MINH'), findsOneWidget);

      // Submit creation
      await tester.tap(find.text('Mục tiêu mới').last);
      await tester.pumpAndSettle();

      // Verify new goal was created
      final goals = await savingsRepo.watchSavingsGoals().first;
      expect(goals.any((g) => g.title == 'Chuyến du lịch mơ ước' && g.targetAmount == 5000000), isTrue);
    });

    testWidgets('SavingsGoalFormSheet in edit mode pre-populates existing goal and updates properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final existingGoal = SavingsGoal(
        id: 'goal_macbook',
        title: 'MacBook Pro M4',
        targetAmount: 40000000,
        currentAmount: 10000000,
        deadline: DateTime.now().add(const Duration(days: 90)),
        icon: 'laptop',
        color: 0xFF007AFF,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            transactionRepositoryProvider.overrideWithValue(txRepo),
            savingsGoalRepositoryProvider.overrideWithValue(savingsRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SavingsGoalFormSheet.show(context, existing: existingGoal);
                    },
                    child: const Text('Mở sửa mục tiêu'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Edit Sheet
      await tester.tap(find.text('Mở sửa mục tiêu'));
      await tester.pumpAndSettle();

      // Verify edit sheet title & pre-populated values
      expect(find.text('Sửa mục tiêu tiết kiệm'), findsOneWidget);
      expect(find.text('MacBook Pro M4'), findsWidgets);
      expect(find.text('40.000.000'), findsOneWidget);

      // Verify inspiration chips are hidden in edit mode
      expect(find.text('GỢI Ý MỤC TIÊU THỊNH HÀNH'), findsNothing);

      // Tap preset 10 triệu
      expect(find.text('10 triệu'), findsWidgets);
      await tester.tap(find.text('10 triệu'));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Lưu').last);
      await tester.pumpAndSettle();

      // Verify updated in repo
      final goals = await savingsRepo.watchSavingsGoals().first;
      final updated = goals.firstWhere((g) => g.id == 'goal_macbook');
      expect(updated.targetAmount, 10000000);
    });
  });
}
