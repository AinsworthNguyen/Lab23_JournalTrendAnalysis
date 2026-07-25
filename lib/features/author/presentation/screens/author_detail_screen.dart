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
import '../../../keywords/domain/entities/trend.dart';
import '../../../keywords/domain/usecases/get_author_details_usecase.dart';
import '../../../journal/domain/entities/paper.dart';
import '../../../journal/data/models/paper_model.dart';

class AuthorDetailScreen extends StatefulWidget {
  final String authorId;
  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Author? _author;

  List<PublicationTrend> _pubTrends = [];
  List<CitationTrend> _citTrends = [];

  List<Paper> _topPapers = [];
  List<Paper> _recentPapers = [];
  List<Paper>? _searchedPapers;

  late final TabController _tabController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  String _selectedFilter = 'all'; // 'all', 'oa', 'closed'
  bool _showPublicationsChart = true;

  Timer? _searchDebounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        if (_tabController.index == 0) {
          _searchController.clear();
          _searchedPapers = null;
        }
        setState(() {});
      }
    });
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      _searchedPapers = null;
    });

    try {
      // 1. Fetch Author Details & Real Yearly Counts from OpenAlex Author object
      final detailsResult = await getIt<GetAuthorDetailsUseCase>().call(widget.authorId);
      
      Author? authorDetail;
      detailsResult.fold(
        (failure) => throw failure.message,
        (author) => authorDetail = author,
      );

      if (authorDetail != null) {
        getIt<IFirebaseAnalyticsService>().logViewKeyword(authorDetail!.displayName);
      }

      // 2. Fetch Author Object directly for counts_by_year
      List<PublicationTrend> pubTrends = [];
      List<CitationTrend> citTrends = [];
      try {
        final authorResponse = await getIt<ApiClient>().get('/authors/${widget.authorId}');
        final rawCounts = authorResponse['counts_by_year'] as List<dynamic>? ?? [];
        for (var item in rawCounts) {
          final y = item['year'] as int? ?? 0;
          final w = item['works_count'] as int? ?? 0;
          final c = item['cited_by_count'] as int? ?? 0;
          if (y >= 2020 && y <= 2025) {
            pubTrends.add(PublicationTrend(year: y, count: w));
            citTrends.add(CitationTrend(year: y, count: c));
          }
        }
        pubTrends.sort((a, b) => a.year.compareTo(b.year));
        citTrends.sort((a, b) => a.year.compareTo(b.year));
      } catch (e) {
        debugPrint('Failed to fetch counts_by_year for author: $e');
      }

      // 3. Fetch Top Publications (by citations) & Publications (by year)
      final worksResults = await Future.wait([
        getIt<ApiClient>().get('/works', queryParameters: {
          'filter': 'authorships.author.id:${widget.authorId},primary_location.source.type:journal|conference,publication_year:<2026',
          'sort': 'cited_by_count:desc',
          'per_page': 20,
        }),
        getIt<ApiClient>().get('/works', queryParameters: {
          'filter': 'authorships.author.id:${widget.authorId},primary_location.source.type:journal|conference,publication_year:<2026',
          'sort': 'publication_year:desc',
          'per_page': 20,
        }),
      ]);

      final topJsonList = (worksResults[0] as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];
      final topPapers = topJsonList
          .map((json) => PaperModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final recentJsonList = (worksResults[1] as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];
      final recentPapers = recentJsonList
          .map((json) => PaperModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Fallback trend calculation if counts_by_year was empty
      if (pubTrends.isEmpty || citTrends.isEmpty) {
        Map<int, int> pubMap = {};
        Map<int, int> citMap = {};
        final sourcePapers = topPapers.isNotEmpty ? topPapers : recentPapers;
        for (var p in sourcePapers) {
          final y = p.publicationYear;
          if (y >= 2020 && y <= 2025) {
            pubMap[y] = (pubMap[y] ?? 0) + 1;
            citMap[y] = (citMap[y] ?? 0) + p.citationCount;
          }
        }
        pubTrends = pubMap.entries.map((e) => PublicationTrend(year: e.key, count: e.value)).toList()..sort((a, b) => a.year.compareTo(b.year));
        citTrends = citMap.entries.map((e) => CitationTrend(year: e.key, count: e.value)).toList()..sort((a, b) => a.year.compareTo(b.year));
      }

      if (mounted) {
        setState(() {
          _author = authorDetail;
          _pubTrends = pubTrends;
          _citTrends = citTrends;
          _topPapers = topPapers;
          _recentPapers = recentPapers;
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
      setState(() {
        _isSearching = false;
        _searchedPapers = null;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final sortParam = _tabController.index == 0 ? 'cited_by_count:desc' : 'publication_year:desc';
        final response = await getIt<ApiClient>().get('/works', queryParameters: {
          'filter': 'authorships.author.id:${widget.authorId},primary_location.source.type:journal|conference,publication_year:<2026',
          'search': trimmed,
          'sort': sortParam,
          'per_page': 20,
        });
        final results = response['results'] as List<dynamic>? ?? [];
        final searched = results
            .map((json) => PaperModel.fromJson(json as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _searchedPapers = searched;
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

    // Prepare chart spots from real API counts_by_year
    List<FlSpot> spots = [];
    double minY = 0;
    double maxY = 10;
    double minX = 2021;
    double maxX = 2025;

    if (_showPublicationsChart) {
      if (_pubTrends.length >= 2) {
        spots = _pubTrends.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
        minY = 0;
        final maxCount = _pubTrends.map((t) => t.count).reduce((a, b) => a > b ? a : b).toDouble();
        maxY = maxCount > 0 ? maxCount * 1.15 : 10;
        minX = _pubTrends.first.year.toDouble();
        maxX = _pubTrends.last.year.toDouble();
      }
    } else {
      if (_citTrends.length >= 2) {
        spots = _citTrends.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
        minY = 0;
        final maxCount = _citTrends.map((t) => t.count).reduce((a, b) => a > b ? a : b).toDouble();
        maxY = maxCount > 0 ? maxCount * 1.15 : 10;
        minX = _citTrends.first.year.toDouble();
        maxX = _citTrends.last.year.toDouble();
      }
    }

    final isTopTab = _tabController.index == 0;
    final sectionTitle = isTopTab ? 'Top Publications' : 'Publications';

    // Select active paper set based on tab index (Top vs Publications)
    final basePapers = isTopTab ? _topPapers : (_searchedPapers ?? _recentPapers);

    // Apply Open Access filter
    final filteredPapers = basePapers.where((paper) {
      if (_selectedFilter == 'oa') return paper.isOpenAccess;
      if (_selectedFilter == 'closed') return !paper.isOpenAccess;
      return true;
    }).toList();

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
            const SizedBox(height: 16.0),

            // 3. Author Activity & Citation Trend Chart Card (Real OpenAlex Data!)
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
                    if (spots.isEmpty)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('Insufficient historical trend data available.'),
                        ),
                      )
                    else
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
                            minX: minX,
                            maxX: maxX,
                            minY: minY,
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

            const SizedBox(height: 20.0),

            // 4. TabBar Navigation Header for Publications
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Top Publications'),
                  Tab(text: 'Publications'),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // 5. Search Bar (Only shown on "Publications" tab!)
            if (!isTopTab) ...[
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) _saveSearch(val.trim());
                },
                decoration: InputDecoration(
                  hintText: 'Search publications by title or topic...',
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
            ],

            // 6. Filter Chips: All / Open Access / Subscription
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
                    label: const Text('Open Access'),
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

            // 7. Section Title with Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sectionTitle,
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

            // 8. Publications List
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
                            Icon(isTopTab ? Icons.star_rounded : Icons.format_quote, size: 14.0, color: isTopTab ? Colors.amber : theme.colorScheme.primary),
                            const SizedBox(width: 4.0),
                            Text(
                              '${paper.citationCount}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isTopTab ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        context.push('/journal/publication/${paper.id}');
                      },
                    ),
                  ).animate(delay: (100 + index * 30).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
                },
              ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}
