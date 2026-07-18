import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/trend.dart';
import '../../domain/usecases/get_citation_trends_usecase.dart';
import '../../domain/usecases/get_keyword_trends_usecase.dart';
import '../../domain/usecases/get_top_authors_usecase.dart';
import '../../../journal/domain/usecases/get_journal_ranking_usecase.dart';
import '../../../journal/domain/usecases/get_publications_usecase.dart';
import '../../../journal/domain/entities/journal.dart';
import '../../../journal/domain/entities/paper.dart';
import '../../../../core/firebase/firebase_analytics_service.dart';
import '../../../../core/widgets/horizontal_bar_chart.dart';

class KeywordDetailScreen extends StatefulWidget {
  final String keywordId;
  final String keywordName;

  const KeywordDetailScreen({
    super.key,
    required this.keywordId,
    required this.keywordName,
  });

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<Author> _topAuthors = [];
  List<PublicationTrend> _pubTrends = [];
  List<CitationTrend> _citTrends = [];
  List<Journal> _relatedJournals = [];
  List<Paper> _relatedPapers = [];

  bool _showPublicationsChart = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    getIt<IFirebaseAnalyticsService>().logViewKeyword(widget.keywordName);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        getIt<GetTopAuthorsUseCase>().call(widget.keywordId),
        getIt<GetKeywordTrendsUseCase>().call(widget.keywordId),
        getIt<GetCitationTrendsUseCase>().call(widget.keywordId),
        getIt<GetJournalRankingUseCase>().call(widget.keywordId),
        getIt<GetPublicationsUseCase>().call(GetPublicationsParams(conceptId: widget.keywordId, page: 1)),
      ]);

      if (mounted) {
        results[0].fold((f) => null, (data) {
          final list = List<Author>.from(data as List<Author>);
          list.sort((a, b) => b.worksCount.compareTo(a.worksCount));
          _topAuthors = list;
        });
        results[1].fold((f) => null, (data) => _pubTrends = data as List<PublicationTrend>);
        results[2].fold((f) => null, (data) => _citTrends = data as List<CitationTrend>);
        results[3].fold((f) => null, (data) {
          final list = List<Journal>.from(data as List<Journal>);
          list.sort((a, b) => b.worksCount.compareTo(a.worksCount));
          _relatedJournals = list;
        });
        results[4].fold((f) => null, (data) => _relatedPapers = data as List<Paper>);

        // Sort trends chronologically using modifiable copies of the lists
        _pubTrends = List<PublicationTrend>.from(_pubTrends)..sort((a, b) => a.year.compareTo(b.year));
        _citTrends = List<CitationTrend>.from(_citTrends)..sort((a, b) => a.year.compareTo(b.year));

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.keywordName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Evolution'),
            Tab(text: 'Authors'),
            Tab(text: 'Journals'),
          ],
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

            return TabBarView(
              controller: _tabController,
              children: [
                _buildTrendsTab(),
                _buildAuthorsTab(),
                _buildJournalsTab(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    final theme = Theme.of(context);
    final hasTrends = _showPublicationsChart ? _pubTrends.length >= 2 : _citTrends.length >= 2;

    List<FlSpot> spots = [];
    double minY = 0;
    double maxY = 10;
    double minX = 2010;
    double maxX = 2024;

    if (hasTrends) {
      if (_showPublicationsChart) {
        final filteredTrends = _pubTrends.where((t) => t.year >= 2021).toList();
        if (filteredTrends.length >= 2) {
          spots = filteredTrends.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
          minY = 0;
          maxY = filteredTrends.map((t) => t.count).reduce((a, b) => a > b ? a : b).toDouble() * 1.15;
          minX = filteredTrends.first.year.toDouble();
          maxX = filteredTrends.last.year.toDouble();
        } else {
          spots = _pubTrends.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
          minY = 0;
          maxY = _pubTrends.map((t) => t.count).reduce((a, b) => a > b ? a : b).toDouble() * 1.15;
          minX = _pubTrends.first.year.toDouble();
          maxX = _pubTrends.last.year.toDouble();
        }
      } else {
        final filteredTrends = _citTrends.where((t) => t.year >= 2021).toList();
        if (filteredTrends.length >= 2) {
          spots = filteredTrends.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
          minY = 0;
          maxY = filteredTrends.map((t) => t.count).reduce((a, b) => a > b ? a : b).toDouble() * 1.15;
          minX = filteredTrends.first.year.toDouble();
          maxX = filteredTrends.last.year.toDouble();
        } else {
          spots = _citTrends.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
          minY = 0;
          maxY = _citTrends.map((t) => t.count).reduce((a, b) => a > b ? a : b).toDouble() * 1.15;
          minX = _citTrends.first.year.toDouble();
          maxX = _citTrends.last.year.toDouble();
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trend Chart Card
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
                  if (!hasTrends)
                    const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text('Insufficient historical data to render trend line.'),
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
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      value.round().toString(),
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

          // Related Publications Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Text(
              'journal.title'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // Related Publications List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _relatedPapers.length,
            itemBuilder: (context, index) {
              final paper = _relatedPapers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  title: Text(
                    paper.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${paper.journalName ?? "Unknown Journal"} • ${paper.publicationYear}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.format_quote, size: 14.0, color: theme.colorScheme.primary),
                      const SizedBox(width: 4.0),
                      Text(paper.citationCount.toString()),
                    ],
                  ),
                  onTap: () {
                    context.push('/journal/publication/${paper.id}');
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorsTab() {
    final theme = Theme.of(context);

    if (_topAuthors.isEmpty) {
      return const Center(child: Text('No authors found.'));
    }

    final top5Authors = _topAuthors.take(5).toList();
    final labels = top5Authors.map((a) => a.displayName).toList();
    final values = top5Authors.map((a) => a.worksCount.toDouble()).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: HorizontalBarChart(
              title: 'Works by Top Authors',
              labels: labels,
              values: values,
              barColor: theme.colorScheme.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'All Top Authors',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...List.generate(_topAuthors.length, (index) {
          final author = _topAuthors[index];
          final rank = index + 1;

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  '#$rank',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ),
              title: Text(author.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                author.lastKnownInstitution ?? 'Independent Researcher',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${author.worksCount} Works',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${author.citedByCount} Citations',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              onTap: () {
                context.push('/keywords/author/${author.id}');
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJournalsTab() {
    final theme = Theme.of(context);

    if (_relatedJournals.isEmpty) {
      return const Center(child: Text('No related journals found.'));
    }

    final top5Journals = _relatedJournals.take(5).toList();
    final labels = top5Journals.map((j) => j.displayName).toList();
    final values = top5Journals.map((j) => j.worksCount.toDouble()).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: HorizontalBarChart(
              title: 'Works by Top Journals',
              labels: labels,
              values: values,
              barColor: Colors.deepPurple,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'All Top Journals',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...List.generate(_relatedJournals.length, (index) {
          final journal = _relatedJournals[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              title: Text(journal.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                journal.publisher ?? 'Independent Publisher',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${journal.worksCount} Works',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${journal.citedByCount} Citations',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              onTap: () {
                context.push('/journal/detail/${journal.id}');
              },
            ),
          );
        }),
      ],
    );
  }
}
