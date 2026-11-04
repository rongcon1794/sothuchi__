import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/widgets/app_shell_scaffold.dart';
import 'package:so_thu_chi/core/widgets/offline_sync_banner.dart';
import 'package:so_thu_chi/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/login_screen.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/splash_screen.dart';
import 'package:so_thu_chi/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:so_thu_chi/features/categories/presentation/screens/categories_screen.dart';
import 'package:so_thu_chi/features/debts/presentation/screens/debts_screen.dart';
import 'package:so_thu_chi/features/recurring/presentation/screens/recurring_transactions_screen.dart';
import 'package:so_thu_chi/features/reports/presentation/screens/reports_screen.dart';
import 'package:so_thu_chi/features/savings/presentation/screens/savings_goals_screen.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/screens/about_screen.dart';
import 'package:so_thu_chi/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:so_thu_chi/features/settings/presentation/screens/settings_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/home_dashboard_screen.dart';
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
    required this.homeBuilder,
    required this.transactionsBuilder,
    required this.transactionFormBuilder,
    required this.budgetsBuilder,
    required this.reportsBuilder,
    required this.settingsBuilder,
    required this.accountsBuilder,
    required this.categoriesBuilder,
    required this.debtsBuilder,
    required this.recurringBuilder,
    required this.savingsBuilder,
    required this.privacyBuilder,
    required this.aboutBuilder,
  });

  final WidgetBuilder splashBuilder;
  final WidgetBuilder onboardingBuilder;
  final WidgetBuilder loginBuilder;
  final WidgetBuilder homeBuilder;
  final WidgetBuilder transactionsBuilder;
  final Widget Function(BuildContext context, GoRouterState state)
  transactionFormBuilder;
  final WidgetBuilder budgetsBuilder;
  final WidgetBuilder reportsBuilder;
  final WidgetBuilder settingsBuilder;
  final WidgetBuilder accountsBuilder;
  final WidgetBuilder categoriesBuilder;
  final WidgetBuilder debtsBuilder;
  final WidgetBuilder recurringBuilder;
  final WidgetBuilder savingsBuilder;
  final WidgetBuilder privacyBuilder;
  final WidgetBuilder aboutBuilder;

  factory AppScreenRegistry.placeholder() {
    return AppScreenRegistry(
      splashBuilder: (_) => const SplashScreen(),
      onboardingBuilder: (_) => const OnboardingScreen(),
      loginBuilder: (_) => const LoginScreen(),
      homeBuilder: (_) => const HomeDashboardScreen(),
      transactionsBuilder: (_) => const TransactionsScreen(),
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
      reportsBuilder: (_) => const ReportsScreen(),
      settingsBuilder: (_) => const SettingsScreen(),
      accountsBuilder: (_) => const AccountsScreen(),
      categoriesBuilder: (_) => const CategoriesScreen(),
      debtsBuilder: (_) => const DebtsScreen(),
      recurringBuilder: (_) => const RecurringTransactionsScreen(),
      savingsBuilder: (_) => const SavingsGoalsScreen(),
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
        settingsControllerProvider,
        (_, _) => notifyListeners(),
      );
  }
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

      if (location == AppRoutes.splash ||
          location == AppRoutes.onboarding ||
          location == AppRoutes.login) {
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
                    builder: (context, _) => screens.privacyBuilder(context),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, _) => screens.aboutBuilder(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.transactionNew,
        builder: screens.transactionFormBuilder,
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: screens.transactionFormBuilder,
      ),
      GoRoute(
        path: AppRoutes.accounts,
        builder: (context, _) => screens.accountsBuilder(context),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, _) => screens.categoriesBuilder(context),
      ),
      GoRoute(
        path: AppRoutes.debts,
        builder: (context, _) => screens.debtsBuilder(context),
      ),
      GoRoute(
        path: AppRoutes.recurring,
        builder: (context, _) => screens.recurringBuilder(context),
      ),
      GoRoute(
        path: AppRoutes.savings,
        builder: (context, _) => screens.savingsBuilder(context),
      ),
    ],
  );
});

