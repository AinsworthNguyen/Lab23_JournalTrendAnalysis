import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

const Color _adminAccent = Color(0xFFF59E0B);

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _AdminTab(path: '/admin/dashboard', icon: Icons.dashboard_outlined,     activeIcon: Icons.dashboard,              label: 'Dashboard'),
    _AdminTab(path: '/admin/users',     icon: Icons.group_outlined,          activeIcon: Icons.group,                  label: 'Users'),
    _AdminTab(path: '/admin/analytics', icon: Icons.bar_chart_outlined,      activeIcon: Icons.bar_chart,              label: 'Analytics'),
    _AdminTab(path: '/admin/config',    icon: Icons.settings_outlined,       activeIcon: Icons.settings,               label: 'Config'),
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    // Sync index from current route
    final location = GoRouterState.of(context).matchedLocation;
    final routeIndex = _tabs.indexWhere((t) => location.startsWith(t.path));
    if (routeIndex >= 0 && routeIndex != _currentIndex) {
      _currentIndex = routeIndex;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _AdminAppBar(),
      body: widget.child,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTap,
        tabs: _tabs,
      ),
    );
  }
}

// ─── Admin AppBar ─────────────────────────────────────────────────────────────

class _AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AdminAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 0,
      leading: const SizedBox.shrink(),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _adminAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _adminAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, color: _adminAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  'ADMIN',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _adminAccent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Journal Trend Admin',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.textSecondary),
          label: Text(
            'Về ứng dụng',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─── Admin Bottom Nav ─────────────────────────────────────────────────────────

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_AdminTab> tabs;

  const _AdminBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: _adminAccent.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: _adminAccent,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: tabs.map((tab) => BottomNavigationBarItem(
            icon: Icon(tab.icon),
            activeIcon: Icon(tab.activeIcon),
            label: tab.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _AdminTab {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _AdminTab({required this.path, required this.icon, required this.activeIcon, required this.label});
}
