import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/firebase/firebase_user_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../blocs/admin_analytics_cubit.dart';

const Color _adminAccent = Color(0xFF38BDF8); // Electric Cyan (Xanh Cyan hiện đại)

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminAnalyticsCubit>()..loadSummary(),
      child: const _AdminAnalyticsView(),
    );
  }
}

class _AdminAnalyticsView extends StatelessWidget {
  const _AdminAnalyticsView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: _adminAccent,
        onRefresh: () async => context.read<AdminAnalyticsCubit>().loadSummary(),
        child: BlocBuilder<AdminAnalyticsCubit, AdminAnalyticsState>(
          builder: (context, state) {
            if (state is AdminAnalyticsLoading) return _buildLoadingState();
            if (state is AdminAnalyticsError)   return _buildErrorState(context, state.message);
            if (state is! AdminAnalyticsLoaded)  return _buildLoadingState();
            return _buildContent(context, state.summary);
          },
        ),
      ),
    );
  }

  // ─── Loading ──────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _skeleton(height: 32, width: 200),
        const SizedBox(height: 24),
        _skeleton(height: 260),
        const SizedBox(height: 16),
        _skeleton(height: 260),
      ],
    );
  }

  Widget _skeleton({double height = 120, double? width}) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.highlight, size: 64),
            const SizedBox(height: 16),
            Text('Failed to load analytics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<AdminAnalyticsCubit>().loadSummary(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _adminAccent, foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Content ──────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, AppAnalyticsSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('System Analytics', style: Theme.of(context).textTheme.displaySmall),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _adminAccent),
              tooltip: 'Refresh analytics',
              onPressed: () {
                context.read<AdminAnalyticsCubit>().loadSummary();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing analytics...'),
                    duration: Duration(milliseconds: 800),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Aggregated metrics from Firebase',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Chart 1: User stats bar chart
        _buildChartCard(
          context,
          title: 'User Overview',
          subtitle: 'User counts by activity status',
          chart: _buildUserStatsBarChart(context, summary),
          height: 200,
        ),
        const SizedBox(height: 16),

        // Chart 2: Activity stats bar chart
        _buildChartCard(
          context,
          title: 'System Activity',
          subtitle: 'Page views & PDF report exports',
          chart: _buildActivityBarChart(context, summary),
          height: 200,
        ),
        const SizedBox(height: 16),

        // Top publications list
        if (summary.topPublications.isNotEmpty) ...[
          _buildTopPublicationsList(context, summary.topPublications),
          const SizedBox(height: 16),
        ],

        // Last updated
        if (summary.lastUpdated != null)
          Center(
            child: Text(
              'Last updated: ${_formatDateTime(summary.lastUpdated!)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Chart Wrapper ────────────────────────────────────────────────────────

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget chart,
    double height = 220,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 20),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }

  // ─── User Stats Bar Chart ─────────────────────────────────────────────────

  Widget _buildUserStatsBarChart(BuildContext context, AppAnalyticsSummary summary) {
    final groups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: summary.totalUsers.toDouble(), color: AppColors.primary, width: 40, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)))]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: summary.activeUsersThisWeek.toDouble(), color: AppColors.secondary, width: 40, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)))]),
    ];
    final maxY = [summary.totalUsers, summary.activeUsersThisWeek].reduce((a, b) => a > b ? a : b).toDouble();
    final labels = ['Total Users', 'Active\nThis Week'];

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY * 1.3,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: Color(0x1A334155), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(_formatCount(v.toInt()), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  labels[v.toInt()],
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              _formatCount(rod.toY.toInt()),
              const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Activity Bar Chart ───────────────────────────────────────────────────

  Widget _buildActivityBarChart(BuildContext context, AppAnalyticsSummary summary) {
    final groups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: summary.totalViews.toDouble(), color: const Color(0xFFF59E0B), width: 40, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)))]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: summary.totalPdfExports.toDouble(), color: AppColors.highlight, width: 40, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)))]),
    ];
    final maxY = [summary.totalViews, summary.totalPdfExports].reduce((a, b) => a > b ? a : b).toDouble();
    final labels = ['Views', 'PDF Exports'];

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY * 1.3,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: Color(0x1A334155), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(_formatCount(v.toInt()), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(labels[v.toInt()], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10), textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              _formatCount(rod.toY.toInt()),
              const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Top Publications List ────────────────────────────────────────────────

  Widget _buildTopPublicationsList(BuildContext context, List<Map<String, dynamic>> pubs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Most Viewed Publications', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Ranked by total user view count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...pubs.take(5).toList().asMap().entries.map((e) {
            final i = e.key;
            final pub = e.value;
            return _buildPubRankItem(context, rank: i + 1, title: pub['title'] as String? ?? 'No title available', views: pub['viewCount'] as int? ?? 0);
          }),
        ],
      ),
    );
  }

  Widget _buildPubRankItem(BuildContext context, {required int rank, required String title, required int views}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3 ? _adminAccent.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? _adminAccent : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: '$views views',
            child: Text(
              _formatCount(views),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _adminAccent,
                fontWeight: FontWeight.w600,
              ),
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
