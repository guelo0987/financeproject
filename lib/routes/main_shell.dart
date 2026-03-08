import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/menudo_bottom_nav.dart';
import '../features/quick_log/presentation/register_transaction_sheet.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/wallet')) return 3;
    return 0; // Dashboard / Home
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/calendar');
      case 2:
        context.go('/budgets');
      case 3:
        context.go('/wallet');
    }
  }

  void _openQuickLog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RegisterTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: child,
      // We use bottomNavigationBar property instead of a Stack so flutter handles insets
      bottomNavigationBar: MenudoBottomNav(
        currentIndex: selectedIndex,
        onTabTap: (idx) => _onItemTapped(context, idx),
        onFabTap: () => _openQuickLog(context),
      ),
    );
  }
}
