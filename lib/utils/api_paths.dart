abstract final class ApiPaths {
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';

  static const budgets = '/budgets';
  static const categories = '/categories';
  static const categoryParents = '/categories/parents';
  static const spaces = '/spaces';
  static const transactions = '/transactions';
  static const wallets = '/wallets';
  static const recurringTransactions = '/recurring';

  static String budgetById(int budgetId) => '$budgets/$budgetId';

  static String budgetSpending(int budgetId) => '$budgets/$budgetId/spending';

  static String activateBudget(int budgetId) => '$budgets/$budgetId/activate';

  static String categoryById(int categoryId) => '$categories/$categoryId';

  static String spaceById(int spaceId) => '$spaces/$spaceId';

  static String inviteToSpace(int spaceId) => '${spaceById(spaceId)}/invite';

  static String spaceMembers(int spaceId) => '${spaceById(spaceId)}/members';

  static String spaceMemberById(int spaceId, int userId) =>
      '${spaceMembers(spaceId)}/$userId';

  static String spaceInvitations(int spaceId) =>
      '${spaceById(spaceId)}/invitations';

  static String spaceInvitationById(int spaceId, int invitationId) =>
      '${spaceInvitations(spaceId)}/$invitationId';

  static String transactionById(int transactionId) =>
      '$transactions/$transactionId';

  static String walletById(int walletId) => '$wallets/$walletId';

  static String setDefaultWallet(int walletId) =>
      '${walletById(walletId)}/set-default';

  static String walletTransactions(int walletId) =>
      '$wallets/$walletId/transactions';

  static String recurringById(int recurringId) =>
      '$recurringTransactions/$recurringId';

  static String toggleRecurring(int recurringId) =>
      '$recurringTransactions/$recurringId/toggle';
}
