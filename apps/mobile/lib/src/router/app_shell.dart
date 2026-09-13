import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import '../widgets/neo_toast.dart';

/// Root shell with persistent, motionless bottom navigation bar and double-back exit protection.
class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  DateTime? _lastBackPressTime;

  void _onTabChanged(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If on a secondary tab (Search, Gallery, Settings), back navigates to Home tab
        if (widget.navigationShell.currentIndex != 0) {
          _onTabChanged(0);
          return;
        }

        // On Home tab: double back within 2 seconds to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          showNeoToast(
            context,
            'Press back again to exit Pomniter',
            icon: Icons.exit_to_app,
            duration: const Duration(seconds: 2),
          );
          return;
        }

        // Exit application cleanly
        SystemNavigator.pop();
      },
      child: NeoScaffold(
        currentIndex: widget.navigationShell.currentIndex,
        onTabChanged: _onTabChanged,
        body: widget.navigationShell,
      ),
    );
  }
}
