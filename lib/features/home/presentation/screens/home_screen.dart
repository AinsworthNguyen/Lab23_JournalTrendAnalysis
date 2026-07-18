import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../injection_container.dart';
import '../blocs/dashboard_bloc.dart';
import '../blocs/dashboard_event.dart';
import '../blocs/dashboard_state.dart';
import '../blocs/search_cubit.dart';
import '../../../../core/firebase/firebase_analytics_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(
          create: (context) => getIt<DashboardBloc>()..add(LoadDashboard()),
        ),
        BlocProvider<SearchCubit>(
          create: (context) => getIt<SearchCubit>()..loadSearchHistory(),
        ),
      ],
      child: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;
  String? _currentConceptId;
  int _visiblePapersCount = 5;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    context.read<SearchCubit>().search(query);
  }

  void _onFocusChanged() {
    setState(() {
      _isSearching = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is DashboardLoaded) {
            if (_currentConceptId != state.conceptId) {
              _currentConceptId = state.conceptId;
              setState(() {
                _visiblePapersCount = 5;
              });
            }
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is DashboardLoaded) {
            final formattedTime = state.lastSync != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(state.lastSync!)
                : 'dashboard.never_updated'.tr();

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12.0),
                        // Header Profile Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'dashboard.welcome'.tr(namedArgs: {'name': state.name}),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'dashboard.sub_header'.tr(namedArgs: {'interest': state.interest}),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'dashboard.last_updated'.tr(namedArgs: {'time': formattedTime}),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Refresh / Sync button
                            IconButton.filledTonal(
                              onPressed: state.isSyncing
                                  ? null
                                  : () {
                                      context.read<DashboardBloc>().add(SyncDashboard());
                                    },
                              icon: state.isSyncing
                                  ? const SizedBox(
                                      width: 18.0,
                                      height: 18.0,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.sync),
                              tooltip: 'dashboard.btn_refresh'.tr(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24.0),

                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'dashboard.search_hint'.tr(),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _searchFocusNode.unfocus();
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (value) {
                              final searchState = context.read<SearchCubit>().state;
                              if (searchState is SearchSuggestionsLoaded && searchState.results.isNotEmpty) {
                                final firstItem = searchState.results.first;
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                                getIt<IFirebaseAnalyticsService>().logSearchTopic(firstItem['name']!);
                                context.read<DashboardBloc>().add(
                                      SelectConceptEvent(
                                        conceptId: firstItem['id']!,
                                        conceptName: firstItem['name']!,
                                      ),
                                    );
                                context.read<SearchCubit>().selectQuery(firstItem['name']!);
                              } else {
                                _searchFocusNode.unfocus();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: () async {
                            context.read<DashboardBloc>().add(SyncDashboard());
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                          if (!_isSearching) ...[
                            // Bento Grid Dashboard Metrics (All 6 cards)
                            GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 16.0,
                                mainAxisExtent: 150.0,
                              ),
                              children: [
                                _buildMetricCard(
                                  context,
                                  title: 'dashboard.metrics.total_publications'.tr(),
                                  value: NumberFormat.decimalPattern().format(state.totalPublications),
                                  icon: Icons.article_outlined,
                                  color: Colors.blue,
                                ),
                                _buildMetricCard(
                                  context,
                                  title: 'dashboard.metrics.avg_citations'.tr(),
                                  value: state.avgCitations.toStringAsFixed(1),
                                  icon: Icons.analytics_outlined,
                                  color: Colors.green,
                                ),
                                _buildMetricCard(
                                  context,
                                  title: 'dashboard.metrics.active_year'.tr(),
                                  value: state.activeYear.toString(),
                                  icon: Icons.calendar_today_outlined,
                                  color: Colors.purple,
                                ),
                                _buildMetricCard(
                                  context,
                                  title: 'dashboard.metrics.top_author'.tr(),
                                  value: state.topAuthor.isNotEmpty ? state.topAuthor : 'N/A',
                                  icon: Icons.person_outline,
                                  color: Colors.teal,
                                ),
                                _buildMetricCard(
                                  context,
                                  title: 'dashboard.metrics.top_journal'.tr(),
                                  value: state.topJournal.isNotEmpty ? state.topJournal : 'N/A',
                                  icon: Icons.book_outlined,
                                  color: Colors.orange,
                                ),
                                _buildMetricCard(
                                  context,
                                  title: 'dashboard.metrics.most_influential'.tr(),
                                  value: state.mostInfluentialPaper.isNotEmpty ? state.mostInfluentialPaper : 'N/A',
                                  icon: Icons.format_quote,
                                  color: Colors.amber,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            const SizedBox(height: 24.0),
                            // Recent Interest Papers Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'dashboard.recent_interest_papers'.tr(namedArgs: {'interest': state.interest}),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                if (state.papers.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                                    child: Text(
                                      'No publications found.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                else ...[
                                    Column(
                                      children: state.papers.take(_visiblePapersCount).toList().asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final paper = entry.value;
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12.0),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16.0),
                                            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08)),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(16.0),
                                            onTap: () {
                                              context.push('/journal/publication/${paper.id}');
                                            },
                                          child: Padding(
                                            padding: const EdgeInsets.all(14.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    // Open Access Badge
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                      decoration: BoxDecoration(
                                                        color: paper.isOpenAccess
                                                            ? Colors.green.withValues(alpha: 0.12)
                                                            : Colors.grey.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(6.0),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            paper.isOpenAccess ? Icons.lock_open : Icons.lock,
                                                            size: 11.0,
                                                            color: paper.isOpenAccess ? Colors.green : Colors.grey,
                                                          ),
                                                          const SizedBox(width: 4.0),
                                                          Text(
                                                            paper.isOpenAccess
                                                                ? 'journal.open_access'.tr()
                                                                : 'journal.closed_access'.tr(),
                                                            style: TextStyle(
                                                              fontSize: 9.0,
                                                              fontWeight: FontWeight.bold,
                                                              color: paper.isOpenAccess ? Colors.green : Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    // Citation Count
                                                    Icon(Icons.format_quote, size: 13.0, color: theme.colorScheme.primary),
                                                    const SizedBox(width: 4.0),
                                                    Text(
                                                      NumberFormat.decimalPattern().format(paper.citationCount),
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10.0),
                                                Text(
                                                  paper.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 8.0),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        paper.journalName ?? 'No journal info',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8.0),
                                                    Text(
                                                      paper.publicationYear.toString(),
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                                    }).toList(),
                                  ),
                                  if (state.papers.length > _visiblePapersCount)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _visiblePapersCount += 5;
                                          });
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('More'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 80.0), // Padding bottom
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Search Suggestions Overlay
                  if (_isSearching)
                    Positioned.fill(
                      child: Container(
                        color: theme.scaffoldBackgroundColor,
                        child: BlocBuilder<SearchCubit, SearchState>(
                          builder: (context, searchState) {
                            if (searchState is SearchLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (searchState is SearchSuggestionsLoaded) {
                              return ListView.builder(
                                itemCount: searchState.results.length,
                                itemBuilder: (context, index) {
                                  final item = searchState.results[index];
                                  return ListTile(
                                    leading: const Icon(Icons.science_outlined),
                                    title: Text(item['name'] ?? ''),
                                    onTap: () {
                                      _searchController.clear();
                                      _searchFocusNode.unfocus();
                                      getIt<IFirebaseAnalyticsService>().logSearchTopic(item['name']!);
                                      context.read<DashboardBloc>().add(
                                            SelectConceptEvent(
                                              conceptId: item['id']!,
                                              conceptName: item['name']!,
                                            ),
                                          );
                                      context.read<SearchCubit>().selectQuery(item['name']!);
                                    },
                                  );
                                },
                              );
                            }

                            if (searchState is SearchHistoryLoaded) {
                              if (searchState.history.isEmpty) {
                                return Center(
                                  child: Text(
                                    "${'dashboard.recent_searches'.tr()} is empty",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'dashboard.recent_searches'.tr(),
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            context.read<SearchCubit>().clearHistory();
                                          },
                                          child: const Text('Clear'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: searchState.history.length,
                                      itemBuilder: (context, index) {
                                        final query = searchState.history[index];
                                        return ListTile(
                                          leading: const Icon(Icons.history),
                                          title: Text(query),
                                          onTap: () {
                                            _searchController.text = query;
                                            getIt<IFirebaseAnalyticsService>().logSearchTopic(query);
                                            context.read<SearchCubit>().search(query);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26.0),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }}
