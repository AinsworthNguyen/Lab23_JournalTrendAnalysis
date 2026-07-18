import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../../personalization/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/usecases/get_journal_ranking_usecase.dart';
import '../blocs/journals_cubit.dart';
import '../../../../core/widgets/horizontal_bar_chart.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalsCubit>(
      create: (context) => JournalsCubit(
        getJournalRanking: getIt<GetJournalRankingUseCase>(),
        getUserPreferences: getIt<GetUserPreferencesUseCase>(),
      )..loadJournals(),
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

            // Prep data for contribution chart
            final chartLabels = state.journals.take(5).map((j) => j.displayName).toList();
            final chartValues = state.journals.take(5).map((j) => j.worksCount.toDouble()).toList();

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

                    // Ranked Journals Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                      child: Text(
                        'keywords.top_journals'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Rankings List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.journals.length,
                      itemBuilder: (context, index) {
                        final journal = state.journals[index];
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
                                        Text(
                                          journal.displayName,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          journal.publisher ?? 'Independent Publisher',
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
}
