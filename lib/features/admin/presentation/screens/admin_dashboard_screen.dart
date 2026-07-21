import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/firebase/firebase_user_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../blocs/admin_analytics_cubit.dart';

const Color _adminAccent = Color(0xFFFB923C); // Soft Orange (Cam nhạt)
const Color _adminSurface = Color(0xFF24180B);
const Color _adminBorder = Color(0xFF5C330A);

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminAnalyticsCubit>()..loadSummary(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: _adminAccent,
        onRefresh: () async {
          context.read<AdminAnalyticsCubit>().loadSummary();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGreetingHeader(context),
            const SizedBox(height: 24),
            _buildStatsGrid(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildRecentInfo(context),
          ],
        ),
      ),
    );
  }

  // ─── Greeting Header ───────────────────────────────────────────────────────

  Widget _buildGreetingHeader(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Chào buổi sáng' : hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _adminSurface,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _adminAccent.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _adminAccent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SYSTEM ONLINE',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              BlocBuilder<AdminAnalyticsCubit, AdminAnalyticsState>(
                builder: (context, state) {
                  String statusText = 'Đang đồng bộ...';
                  if (state is AdminAnalyticsLoaded) {
                    statusText = state.summary.lastUpdated != null
                        ? 'Cập nhật ${_formatTime(state.summary.lastUpdated!)}'
                        : 'Mới nhất';
                  } else if (state is AdminAnalyticsError) {
                    statusText = 'Ngoại tuyến';
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _adminAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _adminAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _adminAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _adminAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _adminAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.space_dashboard_rounded, color: _adminAccent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, Administrator',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Admin Control Center',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFFED7AA),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stats Grid 2×2 ───────────────────────────────────────────────────────

  Widget _buildStatsGrid(BuildContext context) {
    return BlocBuilder<AdminAnalyticsCubit, AdminAnalyticsState>(
      builder: (context, state) {
        if (state is AdminAnalyticsLoading) {
          return _buildStatsGridSkeleton();
        }
        if (state is AdminAnalyticsError) {
          return _buildErrorCard(context, state.message, () {
            context.read<AdminAnalyticsCubit>().loadSummary();
          });
        }
        final summary = state is AdminAnalyticsLoaded ? state.summary : const AppAnalyticsSummary();
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildStatCard(context, icon: Icons.people, label: 'Tổng người dùng',       value: _formatCount(summary.totalUsers),          trend: null),
            _buildStatCard(context, icon: Icons.person_pin, label: 'Hoạt động tuần này', value: _formatCount(summary.activeUsersThisWeek),  trend: null),
            _buildStatCard(context, icon: Icons.visibility, label: 'Lượt xem bài báo',   value: _formatCount(summary.totalViews),           trend: null),
            _buildStatCard(context, icon: Icons.picture_as_pdf, label: 'Lượt xuất PDF',  value: _formatCount(summary.totalPdfExports),      trend: null),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _adminBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _adminAccent, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: _adminAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGridSkeleton() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: List.generate(4, (_) => Container(
        decoration: BoxDecoration(
          color: _adminSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _adminBorder),
        ),
      )),
    );
  }

  // ─── Quick Actions ────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thao tác nhanh', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.group,
                label: 'Quản lý Users',
                onTap: () => context.go('/admin/users'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.settings,
                label: 'Cấu hình hệ thống',
                onTap: () => context.go('/admin/config'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _adminAccent, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Recent Info ──────────────────────────────────────────────────────────

  Widget _buildRecentInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Lưu ý hệ thống',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context, 'Thống kê được tính từ Firestore', Icons.cloud),
          _buildInfoRow(context, 'Remote Config có hiệu lực sau ~5 phút', Icons.timer),
          _buildInfoRow(context, 'Hành động khóa user là tức thì', Icons.lock),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _adminAccent.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error Card ───────────────────────────────────────────────────────────

  Widget _buildErrorCard(BuildContext context, String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.highlight.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.highlight, size: 36),
          const SizedBox(height: 12),
          Text('Không tải được dữ liệu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _adminAccent,
              foregroundColor: const Color(0xFF0B0F19),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
