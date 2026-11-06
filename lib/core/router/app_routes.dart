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
  static const String ledgers = '/ledgers';
  static const String privacy = '/settings/privacy';
  static const String about = '/settings/about';

  static String transactionDetail(String id) => '/transactions/$id';
  static String transactionEdit(String id) => '/transactions/$id/edit';
  static String accountDetail(String id) => '/accounts/$id';
  static String categoryDetail(String id) => '/categories/$id';
  static String budgetDetail(String id) => '/budgets/$id';
  static String savingsDetail(String id) => '/savings/$id';
  static String debtDetail(String id) => '/debts/$id';
  static String recurringDetail(String id) => '/recurring/$id';
}

