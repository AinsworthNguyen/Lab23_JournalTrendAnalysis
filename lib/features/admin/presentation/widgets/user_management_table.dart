import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_account_model.dart';

class UserManagementTable extends StatefulWidget {
  final List<UserAccountModel> users;

  const UserManagementTable({super.key, required this.users});

  @override
  State<UserManagementTable> createState() => _UserManagementTableState();
}

class _UserManagementTableState extends State<UserManagementTable> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    final filteredUsers = widget.users.where((user) {
      return user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.interestConcept.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.role.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls Row
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search accounts by name, email, role, or interest concept...',
            prefixIcon: const Icon(Icons.person_search),
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
        const SizedBox(height: 16.0),

        // User Accounts Data Table Card
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
                  DataColumn(label: Text('User Profile', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Research Interest Concept', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Searches', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Bookmarks', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Joined Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredUsers.map((user) {
                  final isAdmin = user.role == 'ADMIN';
                  return DataRow(
                    cells: [
                      DataCell(Row(
                        children: [
                          CircleAvatar(
                            radius: 16.0,
                            backgroundColor: isAdmin ? Colors.amber : theme.colorScheme.primary,
                            child: Text(
                              user.displayName.isNotEmpty ? user.displayName[0] : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                              Text(user.email, style: const TextStyle(fontSize: 11.0, color: Colors.grey)),
                            ],
                          ),
                        ],
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.amber.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.0),
                          border: isAdmin ? Border.all(color: Colors.amber, width: 1.0) : null,
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(
                            color: isAdmin ? Colors.amber : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                          ),
                        ),
                      )),
                      DataCell(Text(user.interestConcept, style: const TextStyle(fontSize: 13.0))),
                      DataCell(Text('${user.totalSearches}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('${user.totalBookmarks}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(formatter.format(user.joinedDate), style: const TextStyle(fontSize: 12.0, color: Colors.grey))),
                      DataCell(Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8.0,
                            color: user.isActive ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            user.isActive ? 'Active' : 'Offline',
                            style: TextStyle(
                              color: user.isActive ? Colors.green : Colors.grey,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
}
