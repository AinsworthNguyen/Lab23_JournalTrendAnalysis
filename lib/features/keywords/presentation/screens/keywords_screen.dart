import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../personalization/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/entities/keyword.dart';
import '../../domain/usecases/get_emerging_keywords_usecase.dart';
import '../../domain/usecases/get_top_keywords_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/widgets/horizontal_bar_chart.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Keyword> _topKeywords = [];
  List<Keyword> _emergingKeywords = [];
  List<Keyword> _filteredTopKeywords = [];
  List<Keyword> _filteredEmergingKeywords = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefResult = await getIt<GetUserPreferencesUseCase>().call(const NoParams());
      prefResult.fold(
        (failure) => setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        }),
        (prefs) async {
          final results = await Future.wait([
            getIt<GetTopKeywordsUseCase>().call(prefs.interestConceptId),
            getIt<GetEmergingKeywordsUseCase>().call(prefs.interestConceptId),
          ]);

          if (mounted) {
            results[0].fold((f) => null, (data) => _topKeywords = data);
            results[1].fold((f) => null, (data) => _emergingKeywords = data);

            _filteredTopKeywords = List.from(_topKeywords);
            _filteredEmergingKeywords = List.from(_emergingKeywords);

            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTopKeywords = List.from(_topKeywords);
        _filteredEmergingKeywords = List.from(_emergingKeywords);
      } else {
        _filteredTopKeywords = _topKeywords.where((kw) {
          return kw.displayName.toLowerCase().contains(query);
        }).toList();
        _filteredEmergingKeywords = _emergingKeywords.where((kw) {
          return kw.displayName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'keywords.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Prep chart data for top keywords (top 5 only)
            final top5List = _filteredTopKeywords.take(5).toList();
            final topChartLabels = top5List.map((k) => k.displayName).toList();
            final topChartValues = top5List.map((k) => k.worksCount.toDouble()).toList();

            // Prep chart data for emerging keywords (top 5 only)
            final emerging5List = _filteredEmergingKeywords.take(5).toList();
            final emergingChartLabels = emerging5List.map((k) => k.displayName).toList();
            final emergingChartValues = emerging5List.map((k) => k.worksCount.toDouble()).toList();

            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search research topics (e.g. AI, Physics, Data)...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),

                    // Suggested Quick Search Chips when search is empty
                    if (_searchController.text.isEmpty) ...[
                      const SizedBox(height: 10.0),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Text(
                              'Try searching:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            ...['Physics', 'Geology', 'Data Science', 'Python', 'AI', 'Computing'].map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  avatar: Icon(Icons.auto_awesome, size: 12, color: theme.colorScheme.primary),
                                  label: Text(tag, style: const TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    _searchController.text = tag;
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20.0),

                    // SECTION 1: TOP RESEARCH TOPICS
                    if (top5List.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.leaderboard_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'keywords.top_keywords'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      // Top Keywords Chart
                      if (topChartLabels.isNotEmpty) ...[
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: HorizontalBarChart(
                              labels: topChartLabels,
                              values: topChartValues,
                              title: 'Top 5 Topics Overview',
                              barColor: theme.colorScheme.secondary,
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 12.0),
                      ],

                      // Top Keywords List (Top 5 only)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: top5List.length,
                        itemBuilder: (context, index) {
                          final kw = top5List[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              title: Text(
                                kw.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text('Research Topic'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${NumberFormat.compact().format(kw.worksCount)} works',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 16),
                                ],
                              ),
                              onTap: () {
                                context.push(
                                  '/keywords/detail/${kw.id}?name=${Uri.encodeComponent(kw.displayName)}',
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24.0),
                    ],

                    // SECTION 2: EMERGING RESEARCH TOPICS
                    if (emerging5List.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'keywords.emerging_keywords'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      // Emerging Keywords Chart
                      if (emergingChartLabels.isNotEmpty) ...[
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: HorizontalBarChart(
                              labels: emergingChartLabels,
                              values: emergingChartValues,
                              title: 'Top 5 Emerging Topics Growth',
                              barColor: Colors.teal,
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 12.0),
                      ],

                      // Emerging Keywords List (Top 5 only)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: emerging5List.length,
                        itemBuilder: (context, index) {
                          final kw = emerging5List[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.green.withValues(alpha: 0.15),
                                child: const Icon(Icons.trending_up, color: Colors.green, size: 14),
                              ),
                              title: Text(
                                kw.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text('Emerging Topic'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${NumberFormat.compact().format(kw.worksCount)} works',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 16),
                                ],
                              ),
                              onTap: () {
                                context.push(
                                  '/keywords/detail/${kw.id}?name=${Uri.encodeComponent(kw.displayName)}',
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
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
