import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/firebase/firebase_analytics_service.dart';
import '../../../keywords/domain/entities/author.dart';
import '../../../keywords/domain/usecases/get_author_details_usecase.dart';
import '../../../journal/domain/entities/paper.dart';
import '../../../journal/data/models/paper_model.dart';

class AuthorDetailScreen extends StatefulWidget {
  final String authorId;
  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Author? _author;
  List<Paper> _papers = [];

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  String _selectedFilter = 'all'; // 'all', 'oa', 'closed'
  bool _showPublicationsChart = true;

  Timer? _searchDebounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<String> _getRecentSearches() {
    try {
      final box = Hive.box('search_history');
      final list = box.get('author_history') as List<dynamic>?;
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
      if (current.length > 5) current.removeLast();
      box.put('author_history', current);
      setState(() {});
    } catch (_) {}
  }

  void _clearHistory() {
    try {
      final box = Hive.box('search_history');
      box.delete('author_history');
      setState(() {});
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch author details
      final detailsResult = await getIt<GetAuthorDetailsUseCase>().call(widget.authorId);
      
      Author? authorDetail;
      detailsResult.fold(
        (failure) => throw failure.message,
        (author) => authorDetail = author,
      );

      // Log analytics
      if (authorDetail != null) {
        getIt<IFirebaseAnalyticsService>().logViewKeyword(authorDetail!.displayName);
      }

      // 2. Fetch publications by this author
      List<Paper> authorPapers = [];
      try {
        final response = await getIt<ApiClient>().get('/works', queryParameters: {
          'filter': 'authorships.author.id:${widget.authorId},primary_location.source.type:journal|conference,publication_year:<2026',
          'sort': 'publication_year:desc',
          'per_page': 20,
        });
        final results = response['results'] as List<dynamic>? ?? [];
        authorPapers = results
            .map((json) => PaperModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Failed to load papers for author: $e');
      }

      if (mounted) {
        setState(() {
          _author = authorDetail;
          _papers = authorPapers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _loadData();
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final response = await getIt<ApiClient>().get('/works', queryParameters: {
          'filter': 'authorships.author.id:${widget.authorId},primary_location.source.type:journal|conference,publication_year:<2026',
          'search': trimmed,
          'sort': 'publication_year:desc',
          'per_page': 20,
        });
        final results = response['results'] as List<dynamic>? ?? [];
        final authorPapers = results
            .map((json) => PaperModel.fromJson(json as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _papers = authorPapers;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Author Detail', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
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

    if (_author == null) {
      return const Center(child: Text('Author details not found.'));
    }

    final author = _author!;
    final history = _getRecentSearches();

    // Filter papers based on Open Access selection
    final filteredPapers = _papers.where((paper) {
      if (_selectedFilter == 'oa') return paper.isOpenAccess;
      if (_selectedFilter == 'closed') return !paper.isOpenAccess;
      return true;
    }).toList();

    // Calculate trend data spots by year (2020-2025)
    Map<int, int> yearMap = {2021: 0, 2022: 0, 2023: 0, 2024: 0, 2025: 0};
    for (var p in _papers) {
      final y = p.publicationYear;
      if (yearMap.containsKey(y)) {
        final addVal = _showPublicationsChart ? 1 : p.citationCount;
        yearMap[y] = (yearMap[y] ?? 0) + addVal;
      }
    }

    final sortedYears = yearMap.keys.toList()..sort();
    final spots = sortedYears.map((y) => FlSpot(y.toDouble(), yearMap[y]!.toDouble())).toList();
    final maxVal = yearMap.values.isEmpty ? 10.0 : yearMap.values.reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = maxVal > 0 ? maxVal * 1.15 : 10.0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30.0,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        author.displayName.substring(0, author.displayName.isNotEmpty ? 1 : 0).toUpperCase(),
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            author.lastKnownInstitution ?? 'Independent Researcher',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 16.0),

            // 2. Statistics Grid (Works & Citations)
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.article_outlined, color: theme.colorScheme.primary, size: 24.0),
                          const SizedBox(height: 12.0),
                          Text(
                            NumberFormat.compact().format(author.worksCount),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Total Works',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote, color: Colors.green, size: 24.0),
                          const SizedBox(height: 12.0),
                          Text(
                            NumberFormat.compact().format(author.citedByCount),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Total Citations',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 20.0),

            // 3. Search Bar
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) _saveSearch(val.trim());
              },
              decoration: InputDecoration(
                hintText: 'Search publications by title or keyword...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _isSearching
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
                              _onSearchChanged('');
                            },
                          )
                        : null),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
            ),

            // Recent Searches Chips
            if (_searchFocusNode.hasFocus && history.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Recent Searches:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _clearHistory,
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: history.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ActionChip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.history, size: 12),
                        label: Text(item, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          _searchController.text = item;
                          _saveSearch(item);
                          _onSearchChanged(item);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16.0),

            // 4. Filter Chips: All / Open Access / Subscription
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedFilter == 'all',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = 'all');
                    },
                  ),
                  const SizedBox(width: 8.0),
                  ChoiceChip(
                    label: const Text('Open Access (OA)'),
                    selected: _selectedFilter == 'oa',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = 'oa');
                    },
                  ),
                  const SizedBox(width: 8.0),
                  ChoiceChip(
                    label: const Text('Subscription'),
                    selected: _selectedFilter == 'closed',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = 'closed');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // 5. Author Activity & Citation Trend Chart
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _showPublicationsChart ? 'Publication Trend' : 'Citation Trend',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(_showPublicationsChart ? Icons.star_border : Icons.article_outlined),
                          tooltip: _showPublicationsChart ? 'Show Citations' : 'Show Publications',
                          onPressed: () {
                            setState(() {
                              _showPublicationsChart = !_showPublicationsChart;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                              left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                            ),
                          ),
                          minX: 2021,
                          maxX: 2025,
                          minY: 0,
                          maxY: maxY,
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                interval: (maxY / 4) > 0 ? (maxY / 4) : 1,
                                getTitlesWidget: (value, meta) {
                                  if (value < 0) return const SizedBox.shrink();
                                  if (value >= 1000000) {
                                    return Text('${(value / 1000000).toStringAsFixed(1)}M', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9));
                                  } else if (value >= 1000) {
                                    return Text('${(value / 1000).toStringAsFixed(0)}k', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9));
                                  }
                                  return Text(value.toInt().toString(), style: theme.textTheme.bodySmall?.copyWith(fontSize: 9));
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1.0,
                                getTitlesWidget: (value, meta) {
                                  if (value % 1 != 0) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      value.toInt().toString(),
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              barWidth: 4,
                              color: theme.colorScheme.primary,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24.0),

            // 6. Recent Publications Title with Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Publications',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${filteredPapers.length} results',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),

            // 7. Publications List
            if (filteredPapers.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('No matching publications found.'),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredPapers.length,
                itemBuilder: (context, index) {
                  final paper = filteredPapers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      title: Text(
                        paper.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            if (paper.isOpenAccess) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: const Text(
                                  'OA',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                            ],
                            Icon(Icons.calendar_today_outlined, size: 12.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 4.0),
                            Text(
                              paper.publicationYear.toString(),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 16.0),
                            Icon(Icons.format_quote, size: 12.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 4.0),
                            Text(
                              '${paper.citationCount}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        context.push('/journal/publication/${paper.id}');
                      },
                    ),
                  ).animate(delay: (200 + index * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
                },
              ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}
