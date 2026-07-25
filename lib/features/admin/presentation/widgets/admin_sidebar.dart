import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navItems = [
      _SidebarItemData(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Overview',
      ),
      _SidebarItemData(
        icon: Icons.picture_as_pdf_outlined,
        activeIcon: Icons.picture_as_pdf,
        label: 'PDF Analytics Report',
      ),
      _SidebarItemData(
        icon: Icons.tune_outlined,
        activeIcon: Icons.tune,
        label: 'Remote Configs',
      ),
      _SidebarItemData(
        icon: Icons.notifications_none_outlined,
        activeIcon: Icons.notifications,
        label: 'FCM Notifications',
      ),
      _SidebarItemData(
        icon: Icons.bug_report_outlined,
        activeIcon: Icons.bug_report,
        label: 'Diagnostics & Storage',
      ),
      _SidebarItemData(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'User Activities & Accounts',
      ),
    ];

    return Container(
      width: 260.0,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.surfaceLight,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.border : AppColors.borderLight,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // Admin Brand Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Portal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Journal Trend Web',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0),
          const SizedBox(height: 16.0),

          // Navigation list
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      tileColor: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      leading: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : isDark
                                  ? AppColors.textMain
                                  : AppColors.textMainLight,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14.0,
                        ),
                      ),
                      onTap: () => onItemSelected(index),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 10.0,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'OpenAlex API: Active',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _SidebarItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
