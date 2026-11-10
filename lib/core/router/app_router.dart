import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/widgets/app_shell_scaffold.dart';
import 'package:so_thu_chi/core/widgets/offline_sync_banner.dart';
import 'package:so_thu_chi/features/accounts/presentation/screens/account_detail_screen.dart';
import 'package:so_thu_chi/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/initial_setup_screen.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/login_screen.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/splash_screen.dart';
import 'package:so_thu_chi/features/budgets/presentation/screens/budget_detail_screen.dart';
import 'package:so_thu_chi/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:so_thu_chi/features/categories/presentation/screens/category_detail_screen.dart';
import 'package:so_thu_chi/features/categories/presentation/screens/categories_screen.dart';
import 'package:so_thu_chi/features/debts/presentation/screens/debt_detail_screen.dart';
import 'package:so_thu_chi/features/debts/presentation/screens/debts_screen.dart';
import 'package:so_thu_chi/features/ledger/presentation/screens/ledgers_management_screen.dart';
import 'package:so_thu_chi/features/recurring/presentation/screens/recurring_detail_screen.dart';
import 'package:so_thu_chi/features/recurring/presentation/screens/recurring_transactions_screen.dart';
import 'package:so_thu_chi/features/reports/presentation/screens/reports_screen.dart';
import 'package:so_thu_chi/features/savings/presentation/screens/savings_goal_detail_screen.dart';
import 'package:so_thu_chi/features/savings/presentation/screens/savings_goals_screen.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/screens/about_screen.dart';
import 'package:so_thu_chi/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:so_thu_chi/features/settings/presentation/screens/settings_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/home_dashboard_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transactions_screen.dart';

/// Auth session state exposed to the router redirect guard without coupling
/// the router to Firebase SDK classes.
final routerAuthStateProvider = Provider<AsyncValue<AppUser?>>((ref) {
  return ref.watch(authStateStreamProvider);
});

/// Top banner slot injected into the shell (Offline/Sync indicator by default).
final shellTopBannerProvider = Provider<Widget?>((ref) {
  return const OfflineSyncBanner();
});

/// Screen builders overridden progressively across milestones while keeping
/// `go_router` navigation and guards cleanly decoupled.
class AppScreenRegistry {
  const AppScreenRegistry({
    required this.splashBuilder,
    required this.onboardingBuilder,
    required this.loginBuilder,
    required this.initialSetupBuilder,
    required this.homeBuilder,
    required this.transactionsBuilder,
    required this.transactionDetailBuilder,
    required this.transactionFormBuilder,
    required this.budgetsBuilder,
    required this.reportsBuilder,
    required this.settingsBuilder,
    required this.accountsBuilder,
    required this.accountDetailBuilder,
    required this.categoriesBuilder,
    required this.categoryDetailBuilder,
    required this.budgetDetailBuilder,
    required this.debtsBuilder,
    required this.debtDetailBuilder,
    required this.recurringBuilder,
    required this.recurringDetailBuilder,
    required this.savingsBuilder,
    required this.savingsDetailBuilder,
    required this.ledgersBuilder,
    required this.privacyBuilder,
    required this.aboutBuilder,
  });

  final WidgetBuilder splashBuilder;
  final WidgetBuilder onboardingBuilder;
  final WidgetBuilder loginBuilder;
  final WidgetBuilder initialSetupBuilder;
  final WidgetBuilder homeBuilder;
  final WidgetBuilder transactionsBuilder;
  final Widget Function(BuildContext context, GoRouterState state)
  transactionDetailBuilder;
  final Widget Function(BuildContext context, GoRouterState state)
  transactionFormBuilder;
  final WidgetBuilder budgetsBuilder;
  final Widget Function(BuildContext context, GoRouterState state)
  budgetDetailBuilder;
  final WidgetBuilder reportsBuilder;
  final WidgetBuilder settingsBuilder;
  final WidgetBuilder accountsBuilder;
  final Widget Function(BuildContext context, GoRouterState state)
  accountDetailBuilder;
  final WidgetBuilder categoriesBuilder;
  final Widget Function(BuildContext context, GoRouterState state)
  categoryDetailBuilder;
  final WidgetBuilder debtsBuilder;
  final Widget Function(BuildContext context, GoRouterState state)
  debtDetailBuilder;
  final WidgetBuilder recurringBuilder;
  final Widget Function(BuildContext context, GoRouterState state)
  recurringDetailBuilder;
  final WidgetBuilder savingsBuilder;
  final Widget Function(BuildContext context, GoRouterState state)
  savingsDetailBuilder;
  final WidgetBuilder ledgersBuilder;
  final WidgetBuilder privacyBuilder;
  final WidgetBuilder aboutBuilder;

  factory AppScreenRegistry.placeholder() {
    return AppScreenRegistry(
      splashBuilder: (_) => const SplashScreen(),
      onboardingBuilder: (_) => const OnboardingScreen(),
      loginBuilder: (_) => const LoginScreen(),
      initialSetupBuilder: (_) => const InitialSetupScreen(),
      homeBuilder: (_) => const HomeDashboardScreen(),
      transactionsBuilder: (_) => const TransactionsScreen(),
      transactionDetailBuilder: (_, state) =>
          TransactionDetailScreen(transactionId: state.pathParameters['id'] ?? ''),
      transactionFormBuilder: (_, state) {
        final draft = state.extra is TransactionDraft
            ? state.extra! as TransactionDraft
            : null;
        return TransactionFormScreen(
          editTransactionId: state.pathParameters['id'],
          initialDraft: draft,
        );
      },
      budgetsBuilder: (_) => const BudgetsScreen(),
      budgetDetailBuilder: (_, state) =>
          BudgetDetailScreen(budgetId: state.pathParameters['id'] ?? ''),
      reportsBuilder: (_) => const ReportsScreen(),
      settingsBuilder: (_) => const SettingsScreen(),
      accountsBuilder: (_) => const AccountsScreen(),
      accountDetailBuilder: (_, state) =>
          AccountDetailScreen(accountId: state.pathParameters['id'] ?? ''),
      categoriesBuilder: (_) => const CategoriesScreen(),
      categoryDetailBuilder: (_, state) =>
          CategoryDetailScreen(categoryId: state.pathParameters['id'] ?? ''),
      debtsBuilder: (_) => const DebtsScreen(),
      debtDetailBuilder: (_, state) =>
          DebtDetailScreen(debtId: state.pathParameters['id'] ?? ''),
      recurringBuilder: (_) => const RecurringTransactionsScreen(),
      recurringDetailBuilder: (_, state) =>
          RecurringDetailScreen(recurringId: state.pathParameters['id'] ?? ''),
      savingsBuilder: (_) => const SavingsGoalsScreen(),
      savingsDetailBuilder: (_, state) =>
          SavingsGoalDetailScreen(goalId: state.pathParameters['id'] ?? ''),
      ledgersBuilder: (_) => const LedgersManagementScreen(),
      privacyBuilder: (_) => const PrivacyPolicyScreen(),
      aboutBuilder: (_) => const AboutScreen(),
    );
  }
}

final appScreenRegistryProvider = Provider<AppScreenRegistry>((ref) {
  return AppScreenRegistry.placeholder();
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref
      ..listen<AsyncValue<AppUser?>>(
        routerAuthStateProvider,
        (_, _) => notifyListeners(),
      )
      ..listen(
        settingsControllerProvider.select(
          (s) => (
            s.isLoading,
            s.value?.onboardingCompleted,
            s.value?.initialSetupCompleted,
          ),
        ),
        (_, _) => notifyListeners(),
      );
  }
}

/// Creates a platform-adaptive route transition:
/// - iOS & macOS: [CupertinoPage] enabling native edge swipe-to-back gesture detector & parallax.
/// - Android & other platforms: [MaterialPage] supporting predictive back and standard transitions.
Page<dynamic> adaptivePage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return CupertinoPage<void>(
      key: state.pageKey,
      name: state.name,
      child: child,
    );
  }
  return MaterialPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);
  final screens = ref.watch(appScreenRegistryProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final settingsAsync = ref.read(settingsControllerProvider);
      final authAsync = ref.read(routerAuthStateProvider);
      final location = state.matchedLocation;

      if (settingsAsync.isLoading || authAsync.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final onboardingDone =
          settingsAsync.value?.onboardingCompleted ?? false;
      final user = authAsync.value;

      if (!onboardingDone) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      if (user == null) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }

      final initialSetupDone =
          settingsAsync.value?.initialSetupCompleted ?? false;
      if (!initialSetupDone) {
        return location == AppRoutes.initialSetup
            ? null
            : AppRoutes.initialSetup;
      }

      if (location == AppRoutes.splash ||
          location == AppRoutes.onboarding ||
          location == AppRoutes.login ||
          location == AppRoutes.initialSetup) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, _) => screens.splashBuilder(context),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => screens.onboardingBuilder(context),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => screens.loginBuilder(context),
      ),
      GoRoute(
        path: AppRoutes.initialSetup,
        builder: (context, _) => screens.initialSetupBuilder(context),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Consumer(
            builder: (context, ref, _) {
              final banner = ref.watch(shellTopBannerProvider);
              return AppShellScaffold(
                navigationShell: navigationShell,
                topBanner: banner,
              );
            },
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, _) => screens.homeBuilder(context),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, _) => screens.transactionsBuilder(context),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgets,
                builder: (context, _) => screens.budgetsBuilder(context),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, _) => screens.reportsBuilder(context),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, _) => screens.settingsBuilder(context),
                routes: [
                  GoRoute(
                    path: 'privacy',
                    pageBuilder: (context, state) => adaptivePage(
                      context: context,
                      state: state,
                      child: screens.privacyBuilder(context),
                    ),
                  ),
                  GoRoute(
                    path: 'about',
                    pageBuilder: (context, state) => adaptivePage(
                      context: context,
                      state: state,
                      child: screens.aboutBuilder(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.transactionNew,
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.transactionFormBuilder(context, state),
        ),
      ),
      GoRoute(
        path: '/transactions/:id',
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.transactionDetailBuilder(context, state),
        ),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.transactionFormBuilder(context, state),
        ),
      ),
      GoRoute(
        path: AppRoutes.accounts,
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.accountsBuilder(context),
        ),
      ),
      GoRoute(
        path: '/accounts/:id',
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.accountDetailBuilder(context, state),
        ),
      ),
      GoRoute(
        path: AppRoutes.categories,
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.categoriesBuilder(context),
        ),
      ),
      GoRoute(
        path: '/categories/:id',
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.categoryDetailBuilder(context, state),
        ),
      ),
      GoRoute(
        path: '/budgets/:id',
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.budgetDetailBuilder(context, state),
        ),
      ),
      GoRoute(
        path: AppRoutes.debts,
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.debtsBuilder(context),
        ),
      ),
      GoRoute(
        path: '/debts/:id',
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.debtDetailBuilder(context, state),
        ),
      ),
      GoRoute(
        path: AppRoutes.recurring,
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.recurringBuilder(context),
        ),
      ),
      GoRoute(
        path: '/recurring/:id',
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.recurringDetailBuilder(context, state),
        ),
      ),
      GoRoute(
        path: AppRoutes.savings,
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.savingsBuilder(context),
        ),
      ),
      GoRoute(
        path: '/savings/:id',
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.savingsDetailBuilder(context, state),
        ),
      ),
      GoRoute(
        path: AppRoutes.ledgers,
        pageBuilder: (context, state) => adaptivePage(
          context: context,
          state: state,
          child: screens.ledgersBuilder(context),
        ),
      ),
    ],
  );
});

