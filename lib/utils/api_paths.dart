abstract final class ApiPaths {
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';

  static const budgets = '/budgets';
  static const categories = '/categories';
  static const transactions = '/transactions';
  static const wallets = '/wallets';
  static const recurringTransactions = '/recurring';

  static String budgetById(int budgetId) => '$budgets/$budgetId';

  static String budgetSpending(int budgetId) => '$budgets/$budgetId/spending';

  static String activateBudget(int budgetId) => '$budgets/$budgetId/activate';

  static String categoryById(int categoryId) => '$categories/$categoryId';

  static String transactionById(int transactionId) =>
      '$transactions/$transactionId';

  static String walletById(int walletId) => '$wallets/$walletId';

  static String walletTransactions(int walletId) =>
      '$wallets/$walletId/transactions';

  static String recurringById(int recurringId) =>
      '$recurringTransactions/$recurringId';

  static String toggleRecurring(int recurringId) =>
      '$recurringTransactions/$recurringId/toggle';
}
