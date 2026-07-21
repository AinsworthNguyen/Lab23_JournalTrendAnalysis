import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../blocs/journals_cubit.dart';
import '../../../../core/widgets/horizontal_bar_chart.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalsCubit>(
      create: (context) => getIt<JournalsCubit>()..loadJournals(),
      child: const JournalScreenContent(),
    );
  }
}

class JournalScreenContent extends StatelessWidget {
  const JournalScreenContent({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'journal.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<JournalsCubit, JournalsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage!,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<JournalsCubit>().loadJournals();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.journals.isEmpty) {
              return Center(
                child: Text(
                  'No journals found.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              );
            }

            final displayList = state.filteredJournals;
            final chartLabels = displayList.take(5).map((j) => j.displayName).toList();
            final chartValues = displayList.take(5).map((j) => j.worksCount.toDouble()).toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<JournalsCubit>().loadJournals();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search & Filter Header
                    TextField(
                      onChanged: (q) => context.read<JournalsCubit>().searchSources(q),
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm Hội nghị (NeurIPS, CVPR...) hoặc Tạp chí...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Filter Chips: All / Journals / Conferences
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(context, 'all', 'Tất cả', state.selectedTypeFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'journal', 'Tạp chí (Journals)', state.selectedTypeFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'conference', 'Hội nghị (Conferences)', state.selectedTypeFilter),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Contribution Chart
                    if (chartLabels.isNotEmpty) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: HorizontalBarChart(
                            labels: chartLabels,
                            values: chartValues,
                            title: 'keywords.journal_ranking'.tr(),
                            barColor: theme.colorScheme.primary,
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0),
                      const SizedBox(height: 20.0),
                    ],

                    // Ranked Venues Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'keywords.top_journals'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${displayList.length} kết quả',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (displayList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text('Không tìm thấy hội nghị hoặc tạp chí phù hợp', style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),

                    // Rankings List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final journal = displayList[index];
                        final rank = index + 1;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14.0),
                            onTap: () {
                              context.push('/journal/detail/${journal.id}');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Rank Badge
                                  Container(
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: rank <= 3
                                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '#$rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: rank <= 3 ? theme.colorScheme.primary : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                journal.displayName,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Type Badge (Conference vs Journal)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: journal.isConference
                                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                                    : theme.colorScheme.primary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: journal.isConference
                                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                                      : theme.colorScheme.primary.withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    journal.isConference ? Icons.event : Icons.menu_book,
                                                    size: 11,
                                                    color: journal.isConference
                                                        ? const Color(0xFFF59E0B)
                                                        : theme.colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    journal.isConference ? 'Hội nghị' : 'Tạp chí',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: journal.isConference
                                                          ? const Color(0xFFF59E0B)
                                                          : theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          journal.publisher ?? (journal.isConference ? 'Academic Conference' : 'Independent Publisher'),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8.0),
                                        Wrap(
                                          spacing: 16.0,
                                          runSpacing: 4.0,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.article_outlined, size: 14.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                                const SizedBox(width: 4.0),
                                                Text(
                                                  'Works: ${NumberFormat.decimalPattern().format(journal.worksCount)}',
                                                  style: theme.textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.format_quote, size: 14.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                                const SizedBox(width: 4.0),
                                                Text(
                                                  'Citations: ${NumberFormat.decimalPattern().format(journal.citedByCount)}',
                                                  style: theme.textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Actions (Link / Navigate)
                                  if (journal.homepageUrl != null && journal.homepageUrl!.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.language),
                                      tooltip: 'Visit homepage',
                                      onPressed: () => _launchUrl(context, journal.homepageUrl!),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String value, String label, String current) {
    final isSelected = current == value;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.read<JournalsCubit>().setTypeFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
