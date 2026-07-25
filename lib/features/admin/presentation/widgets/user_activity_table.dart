import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_activity_log.dart';

class UserActivityTable extends StatefulWidget {
  final List<UserActivityLog> logs;

  const UserActivityTable({super.key, required this.logs});

  @override
  State<UserActivityTable> createState() => _UserActivityTableState();
}

class _UserActivityTableState extends State<UserActivityTable> {
  String _searchQuery = '';
  ActivityType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    final filteredLogs = widget.logs.where((log) {
      final matchesSearch = log.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.userEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.details.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.actionTitle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == null || log.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls Row (Search + Filter Chips)
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search user activity logs by name, email, action...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.border : AppColors.borderLight,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            DropdownButton<ActivityType?>(
              value: _selectedType,
              hint: const Text('Filter by Action'),
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12.0),
              onChanged: (type) => setState(() => _selectedType = type),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Actions')),
                DropdownMenuItem(value: ActivityType.login, child: Text('Sign In')),
                DropdownMenuItem(value: ActivityType.search, child: Text('Topic Search')),
                DropdownMenuItem(value: ActivityType.exportPdf, child: Text('PDF Export')),
                DropdownMenuItem(value: ActivityType.viewPublication, child: Text('View Article')),
                DropdownMenuItem(value: ActivityType.updatePreference, child: Text('Update Interest')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Activity Log Table Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: isDark ? AppColors.border : AppColors.borderLight,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24.0,
                headingRowHeight: 48.0,
                columns: const [
                  DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('User / Email', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Activity Details', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Platform', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredLogs.map((log) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        formatter.format(log.timestamp),
                        style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                      )),
                      DataCell(Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                          Text(log.userEmail, style: const TextStyle(fontSize: 11.0, color: Colors.grey)),
                        ],
                      )),
                      DataCell(_buildActionBadge(log.type, log.actionTitle)),
                      DataCell(Text(log.details, style: const TextStyle(fontSize: 13.0))),
                      DataCell(Text(log.platform, style: const TextStyle(fontSize: 12.0))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: log.status == 'SUCCESS'
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          log.status,
                          style: TextStyle(
                            color: log.status == 'SUCCESS' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                          ),
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBadge(ActivityType type, String title) {
    Color bg;
    Color fg;
    IconData icon;

    switch (type) {
      case ActivityType.login:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue;
        icon = Icons.login;
        break;
      case ActivityType.search:
        bg = Colors.indigo.withValues(alpha: 0.15);
        fg = Colors.indigo;
        icon = Icons.search;
        break;
      case ActivityType.exportPdf:
        bg = Colors.pink.withValues(alpha: 0.15);
        fg = Colors.pink;
        icon = Icons.picture_as_pdf;
        break;
      case ActivityType.viewPublication:
        bg = Colors.teal.withValues(alpha: 0.15);
        fg = Colors.teal;
        icon = Icons.article;
        break;
      case ActivityType.updatePreference:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber;
        icon = Icons.tune;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: fg),
          const SizedBox(width: 6.0),
          Text(
            title,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11.0),
          ),
        ],
      ),
    );
  }
}
