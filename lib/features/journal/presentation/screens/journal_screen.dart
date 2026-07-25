import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
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

class JournalScreenContent extends StatefulWidget {
  const JournalScreenContent({super.key});

  @override
  State<JournalScreenContent> createState() => _JournalScreenContentState();
}

class _JournalScreenContentState extends State<JournalScreenContent> {
  late final TextEditingController _searchController;

  List<String> _getRecentSearches() {
    try {
      final box = Hive.box('search_history');
      final list = box.get('journal_history') as List<dynamic>?;
      return list?.cast<String>() ?? [];
    } catch (_) {
      return [];
    }
  }

  void _saveSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    try {
      final box = Hive.box('search_history');
      final current = _getRecentSearches();
      current.remove(q);
      current.insert(0, q);
      if (current.length > 5) {
        current.removeLast();
      }
      box.put('journal_history', current);
      setState(() {});
    } catch (_) {}
  }

  void _clearHistory() {
    try {
      final box = Hive.box('search_history');
      box.delete('journal_history');
      setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  String _getChartTitle(String filter) {
    switch (filter) {
      case 'journal':
        return 'keywords.journal_ranking'.tr();
      case 'conference':
        return 'keywords.conference_ranking'.tr();
      case 'all':
      default:
        return 'keywords.publication_ranking'.tr();
    }
  }

  String _getSectionTitle(String filter) {
    switch (filter) {
      case 'journal':
        return 'keywords.top_journals'.tr();
      case 'conference':
        return 'keywords.top_conferences'.tr();
      case 'all':
      default:
        return 'keywords.top_publications'.tr();
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
            if (state.isLoading && state.journals.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null && state.journals.isEmpty) {
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
                      controller: _searchController,
                      onChanged: (q) {
                        setState(() {});
                        context.read<JournalsCubit>().searchSources(q);
                      },
                      onSubmitted: (q) {
                        _saveSearch(q);
                      },
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search (IEEE, ACM, Nature, CVPR, NeurIPS...)',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: state.isSearching
                            ? UnconstrainedBox(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : (_searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                      context.read<JournalsCubit>().searchSources('');
                                    },
                                  )
                                : null),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    
                    // Recent Searches (History)
                    Builder(
                      builder: (context) {
                        final history = _getRecentSearches();
                        if (history.isEmpty || _searchController.text.isNotEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.history, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Recent Searches',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: _clearHistory,
                                    child: Text(
                                      'Clear All',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: history.map((q) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ActionChip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(q, style: const TextStyle(fontSize: 11)),
                                        onPressed: () {
                                          _searchController.text = q;
                                          setState(() {});
                                          context.read<JournalsCubit>().searchSources(q);
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    // Auto-completion search suggestions helper
                    Builder(
                      builder: (context) {
                        final queryText = _searchController.text.toLowerCase().trim();
                        if (queryText.isEmpty) return const SizedBox.shrink();

                        const suggestionsList = [
                          {'acronym': 'NeurIPS', 'name': 'Neural Info Processing'},
                          {'acronym': 'CVPR', 'name': 'Computer Vision'},
                          {'acronym': 'ICML', 'name': 'Machine Learning'},
                          {'acronym': 'ICLR', 'name': 'Learning Representations'},
                          {'acronym': 'Nature', 'name': 'Nature Journal'},
                          {'acronym': 'IEEE', 'name': 'IEEE Transactions'},
                        ];

                        final matchedSuggestions = suggestionsList.where((item) {
                          final acronymLower = item['acronym']!.toLowerCase();
                          final nameLower = item['name']!.toLowerCase();
                          return acronymLower.startsWith(queryText) || nameLower.contains(queryText);
                        }).toList();

                        if (matchedSuggestions.isEmpty) return const SizedBox.shrink();

                        // Do not show suggestions if the query matches the exact acronym
                        if (matchedSuggestions.length == 1 && matchedSuggestions.first['acronym']!.toLowerCase() == queryText) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: matchedSuggestions.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    avatar: Icon(Icons.auto_awesome, size: 12, color: theme.colorScheme.primary),
                                    label: Text(
                                      '${item['acronym']} (${item['name']})',
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                    ),
                                    onPressed: () {
                                      _searchController.text = item['acronym']!;
                                      _saveSearch(item['acronym']!);
                                      setState(() {});
                                      context.read<JournalsCubit>().searchSources(item['acronym']!);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12.0),

                    // Filter Chips: All / Journals / Conferences
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(context, 'all', 'All', state.selectedTypeFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'journal', 'Journals', state.selectedTypeFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'conference', 'Conferences', state.selectedTypeFilter),
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
                            title: _getChartTitle(state.selectedTypeFilter),
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
                            _getSectionTitle(state.selectedTypeFilter),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${displayList.length} results',
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
                              Text('No matching conferences or journals found', style: theme.textTheme.bodyMedium),
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
                                                    journal.isConference ? 'Conference' : 'Journal',
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
