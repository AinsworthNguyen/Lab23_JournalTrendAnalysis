import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../blocs/admin_users_cubit.dart';

const Color _adminAccent = Color(0xFFFB923C); // Soft Orange (Cam nhạt)

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminUsersCubit>()..startWatching(),
      child: const _AdminUsersView(),
    );
  }
}

class _AdminUsersView extends StatelessWidget {
  const _AdminUsersView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          _buildSearchAndFilter(context),
          const Divider(color: AppColors.border, height: 1),
          Expanded(child: _buildUserList(context)),
        ],
      ),
    );
  }

  // ─── Header with Stats ────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quản lý người dùng', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          BlocBuilder<AdminUsersCubit, AdminUsersState>(
            builder: (context, state) {
              if (state is! AdminUsersLoaded) return const SizedBox.shrink();
              return Row(
                children: [
                  _buildStatChip(context, state.totalCount.toString(), 'Tổng', AppColors.textSecondary),
                  const SizedBox(width: 8),
                  _buildStatChip(context, state.activeCount.toString(), 'Hoạt động', AppColors.secondary),
                  const SizedBox(width: 8),
                  _buildStatChip(context, state.blockedCount.toString(), 'Bị khóa', AppColors.highlight),
                  const SizedBox(width: 8),
                  _buildStatChip(context, state.adminCount.toString(), 'Admin', _adminAccent),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            count,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search & Filter ──────────────────────────────────────────────────────

  Widget _buildSearchAndFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (q) => context.read<AdminUsersCubit>().search(q),
            style: const TextStyle(color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc email...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _adminAccent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          BlocBuilder<AdminUsersCubit, AdminUsersState>(
            builder: (context, state) {
              final current = state is AdminUsersLoaded ? state.filterStatus : 'all';
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, 'all',     'Tất cả',         current),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'active',  'Đang hoạt động', current),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'blocked', 'Bị khóa',        current),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'admin',   'Admin',           current),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String value, String label, String current) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => context.read<AdminUsersCubit>().setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _adminAccent.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _adminAccent : AppColors.border.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? _adminAccent : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ─── User List ────────────────────────────────────────────────────────────

  Widget _buildUserList(BuildContext context) {
    return BlocBuilder<AdminUsersCubit, AdminUsersState>(
      builder: (context, state) {
        if (state is AdminUsersLoading) {
          return const Center(child: CircularProgressIndicator(color: _adminAccent, strokeWidth: 2));
        }
        if (state is AdminUsersError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.highlight, size: 48),
                const SizedBox(height: 12),
                Text('Không tải được danh sách', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }
        if (state is! AdminUsersLoaded) return const SizedBox.shrink();
        final users = state.filteredUsers;
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_search, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text('Không tìm thấy người dùng', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Thử thay đổi từ khóa hoặc bộ lọc', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: users.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildUserCard(context, users[index]),
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, dynamic user) {
    final isBlocked = user.isBlocked as bool;
    final isAdmin = user.isAdmin as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked
              ? AppColors.highlight.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _adminAccent.withValues(alpha: 0.15),
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                child: user.photoUrl.isEmpty
                    ? Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                        style: TextStyle(color: _adminAccent, fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              if (isAdmin)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _adminAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.star, size: 10, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatusBadge(context, isBlocked: isBlocked, isAdmin: isAdmin),
                  ],
                ),
              ],
            ),
          ),
          // Actions menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (action) => _handleUserAction(context, action, user),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'view',
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Xem chi tiết', style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
              PopupMenuItem(
                value: isBlocked ? 'unblock' : 'block',
                child: Row(children: [
                  Icon(
                    isBlocked ? Icons.lock_open : Icons.lock_outline,
                    size: 18,
                    color: isBlocked ? AppColors.secondary : AppColors.highlight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBlocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isBlocked ? AppColors.secondary : AppColors.highlight,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, {required bool isBlocked, required bool isAdmin}) {
    if (isBlocked) {
      return _badge(context, 'Bị khóa', AppColors.highlight);
    }
    if (isAdmin) {
      return _badge(context, 'Admin', _adminAccent);
    }
    return _badge(context, 'Hoạt động', AppColors.secondary);
  }

  Widget _badge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  void _handleUserAction(BuildContext context, String action, dynamic user) {
    if (action == 'view') {
      _showUserDetailSheet(context, user);
    } else if (action == 'block') {
      _showBlockConfirmDialog(context, user);
    } else if (action == 'unblock') {
      _showUnblockConfirmDialog(context, user);
    }
  }

  void _showUserDetailSheet(BuildContext context, dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2),
              )),
            ),
            const SizedBox(height: 20),
            Text('Chi tiết người dùng', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _detailRow(context, 'Họ tên', user.fullName),
            _detailRow(context, 'Email', user.email),
            _detailRow(context, 'Role', user.role),
            _detailRow(context, 'Trạng thái', user.isBlocked ? 'Bị khóa' : 'Hoạt động'),
            _detailRow(context, 'Lượt xem', user.viewCount.toString()),
            _detailRow(context, 'Xuất PDF', user.pdfExportCount.toString()),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmDialog(BuildContext context, dynamic user) {
    final cubit = context.read<AdminUsersCubit>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.lock_outline, color: AppColors.highlight, size: 22),
          const SizedBox(width: 8),
          Text('Khóa tài khoản', style: Theme.of(context).textTheme.titleMedium),
        ]),
        content: Text(
          'Bạn có chắc muốn khóa tài khoản của "${user.fullName}"?\n\nNgười dùng sẽ bị đăng xuất và không thể đăng nhập lại.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.highlight, foregroundColor: Colors.white),
            onPressed: () {
              cubit.blockUser(user.uid as String);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã khóa tài khoản ${user.fullName}'),
                  backgroundColor: AppColors.highlight,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Khóa tài khoản'),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirmDialog(BuildContext context, dynamic user) {
    final cubit = context.read<AdminUsersCubit>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.lock_open, color: AppColors.secondary, size: 22),
          const SizedBox(width: 8),
          Text('Mở khóa tài khoản', style: Theme.of(context).textTheme.titleMedium),
        ]),
        content: Text(
          'Bạn có chắc muốn mở khóa tài khoản của "${user.fullName}"?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
            onPressed: () {
              cubit.unblockUser(user.uid as String);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã mở khóa tài khoản ${user.fullName}'),
                  backgroundColor: AppColors.secondary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Mở khóa'),
          ),
        ],
      ),
    );
  }
}
