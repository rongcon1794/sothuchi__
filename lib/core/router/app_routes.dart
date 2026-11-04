/// Centralized route paths and names for `go_router`.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String transactionNew = '/transactions/new';
  static const String budgets = '/budgets';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static const String accounts = '/accounts';
  static const String categories = '/categories';
  static const String debts = '/debts';
  static const String recurring = '/recurring';
  static const String savings = '/savings';
  static const String privacy = '/settings/privacy';
  static const String about = '/settings/about';

  static String transactionEdit(String id) => '/transactions/$id/edit';
}

