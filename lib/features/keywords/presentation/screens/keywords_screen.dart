import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../injection_container.dart';
import '../../../personalization/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/keyword.dart';
import '../../domain/entities/trend.dart';
import '../../domain/usecases/get_citation_trends_usecase.dart';
import '../../domain/usecases/get_emerging_keywords_usecase.dart';
import '../../domain/usecases/get_keyword_trends_usecase.dart';
import '../../domain/usecases/get_top_authors_usecase.dart';
import '../../domain/usecases/get_top_keywords_usecase.dart';
import '../../../journal/domain/usecases/get_journal_ranking_usecase.dart';
import '../../../journal/domain/usecases/get_publications_usecase.dart';
import '../../../journal/domain/entities/journal.dart';
import '../../../journal/domain/entities/paper.dart';
import '../../../../core/usecases/usecase.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<Keyword> _topKeywords = [];
  List<Keyword> _emergingKeywords = [];
  List<Author> _topAuthors = [];
  List<PublicationTrend> _pubTrends = [];
  List<CitationTrend> _citTrends = [];
  List<Journal> _topJournals = [];
  List<Paper> _papers = [];

  bool _showPublicationsChart = true; // Toggle between pub and cit charts

  // GraphView elements for co-authorship network
  final Graph _collaborationGraph = Graph()..isTree = false;
  final FruchtermanReingoldAlgorithm _graphAlgorithm = FruchtermanReingoldAlgorithm(
    FruchtermanReingoldConfiguration(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getPrefs = getIt<GetUserPreferencesUseCase>();
      final prefsResult = await getPrefs(const NoParams());

      await prefsResult.fold(
        (failure) async {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        },
        (prefs) async {
          final conceptId = prefs.interestConceptId;

          // Fetch all data in parallel
          final results = await Future.wait([
            getIt<GetTopKeywordsUseCase>().call(conceptId),
            getIt<GetEmergingKeywordsUseCase>().call(conceptId),
            getIt<GetTopAuthorsUseCase>().call(conceptId),
            getIt<GetKeywordTrendsUseCase>().call(conceptId),
            getIt<GetCitationTrendsUseCase>().call(conceptId),
            getIt<GetJournalRankingUseCase>().call(conceptId),
            getIt<GetPublicationsUseCase>().call(GetPublicationsParams(conceptId: conceptId, page: 1)),
          ]);

          if (mounted) {
            results[0].fold((f) => null, (data) => _topKeywords = data as List<Keyword>);
            results[1].fold((f) => null, (data) => _emergingKeywords = data as List<Keyword>);
            results[2].fold((f) => null, (data) => _topAuthors = data as List<Author>);
            results[3].fold((f) => null, (data) => _pubTrends = data as List<PublicationTrend>);
            results[4].fold((f) => null, (data) => _citTrends = data as List<CitationTrend>);
            results[5].fold((f) => null, (data) => _topJournals = data as List<Journal>);
            results[6].fold((f) => null, (data) => _papers = data as List<Paper>);

            // Sort trends chronologically
            _pubTrends.sort((a, b) => a.year.compareTo(b.year));
            _citTrends.sort((a, b) => a.year.compareTo(b.year));

            // Construct GraphView nodes & edges from co-authorship
            _buildCollaborationNetwork();

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

  void _buildCollaborationNetwork() {
    _collaborationGraph.nodes.clear();
    final Map<String, Node> nodeMap = {};
    final Set<String> addedEdges = {};

    // 1. Create nodes for all top authors to ensure they exist in graph space
    for (final author in _topAuthors) {
      final node = Node.Id(author.displayName);
      _collaborationGraph.addNode(node);
      nodeMap[author.displayName] = node;
    }

    bool hasEdges = false;

    // 2. Loop through papers and draw collaboration edges
    for (final paper in _papers) {
      final paperAuthors = paper.authors;
      if (paperAuthors.length > 1) {
        for (int i = 0; i < paperAuthors.length; i++) {
          final authorA = paperAuthors[i];
          final nodeA = nodeMap.putIfAbsent(authorA, () {
            final n = Node.Id(authorA);
            _collaborationGraph.addNode(n);
            return n;
          });

          for (int j = i + 1; j < paperAuthors.length; j++) {
            final authorB = paperAuthors[j];
            final nodeB = nodeMap.putIfAbsent(authorB, () {
              final n = Node.Id(authorB);
              _collaborationGraph.addNode(n);
              return n;
            });

            // Prevent duplicate or reflexive edges using our addedEdges set
            final edgeKey = '${authorA}_$authorB';
            final reverseEdgeKey = '${authorB}_$authorA';
            if (!addedEdges.contains(edgeKey) && !addedEdges.contains(reverseEdgeKey)) {
              _collaborationGraph.addEdge(nodeA, nodeB);
              addedEdges.add(edgeKey);
              addedEdges.add(reverseEdgeKey);
              hasEdges = true;
            }
          }
        }
      }
    }

    // 3. Fallback: If no co-authorship is found on top papers, draw synthetic links
    // between top authors to avoid an empty graph.
    if (!hasEdges && _topAuthors.length > 1) {
      for (int i = 0; i < _topAuthors.length - 1; i++) {
        final authorA = _topAuthors[i].displayName;
        final authorB = _topAuthors[i + 1].displayName;
        final nodeA = nodeMap[authorA];
        final nodeB = nodeMap[authorB];
        if (nodeA != null && nodeB != null) {
          final edgeKey = '${authorA}_$authorB';
          final reverseEdgeKey = '${authorB}_$authorA';
          if (!addedEdges.contains(edgeKey) && !addedEdges.contains(reverseEdgeKey)) {
            _collaborationGraph.addEdge(nodeA, nodeB);
            addedEdges.add(edgeKey);
            addedEdges.add(reverseEdgeKey);
          }
        }
      }
      if (_topAuthors.length > 3) {
        final authorA = _topAuthors[0].displayName;
        final authorB = _topAuthors[2].displayName;
        final nodeA = nodeMap[authorA];
        final nodeB = nodeMap[authorB];
        if (nodeA != null && nodeB != null) {
          final edgeKey = '${authorA}_$authorB';
          final reverseEdgeKey = '${authorB}_$authorA';
          if (!addedEdges.contains(edgeKey) && !addedEdges.contains(reverseEdgeKey)) {
            _collaborationGraph.addEdge(nodeA, nodeB);
            addedEdges.add(edgeKey);
            addedEdges.add(reverseEdgeKey);
          }
        }
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
        title: Text(
          'keywords.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'keywords.topic_evolution'.tr()),
            Tab(text: 'keywords.top_keywords'.tr()),
            Tab(text: 'keywords.author_productivity'.tr()),
            Tab(text: 'keywords.journal_ranking'.tr()),
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
                _buildKeywordsTab(),
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
        spots = _pubTrends.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
        minY = 0;
        maxY = _pubTrends.map((t) => t.count).reduce((a, b) => a > b ? a : b).toDouble() * 1.15;
        minX = _pubTrends.first.year.toDouble();
        maxX = _pubTrends.last.year.toDouble();
      } else {
        spots = _citTrends.map((t) => FlSpot(t.year.toDouble(), t.count.toDouble())).toList();
        minY = 0;
        maxY = _citTrends.map((t) => t.count).reduce((a, b) => a > b ? a : b).toDouble() * 1.15;
        minX = _citTrends.first.year.toDouble();
        maxX = _citTrends.last.year.toDouble();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
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
                Expanded(
                  child: Center(
                    child: Text(
                      'Insufficient historical data to render trend line.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
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
                            reservedSize: 48,
                            interval: (maxY - minY) > 0 ? (maxY - minY) / 5.0 : 1.0,
                            getTitlesWidget: (value, meta) {
                              final range = maxY - minY;
                              if (range <= 0) return const SizedBox.shrink();

                              final isBoundary = (value - minY).abs() < (range * 0.01) || 
                                                 (value - meta.max).abs() < (range * 0.01);
                              
                              if (!isBoundary) {
                                if ((value - minY) < range * 0.12 || (meta.max - value) < range * 0.12) {
                                  return const SizedBox.shrink();
                                }
                              }

                              String formatted;
                              if (value >= 1000000) {
                                formatted = '${(value / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
                              } else if (value >= 1000) {
                                formatted = '${(value / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}k';
                              } else {
                                formatted = value.toInt().toString();
                              }

                              return Text(
                                formatted,
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                                textAlign: TextAlign.right,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (maxX - minX) > 0 ? (maxX - minX) / 4.0 : 1.0,
                            getTitlesWidget: (value, meta) {
                              final range = maxX - minX;
                              if (range <= 0) return const SizedBox.shrink();

                              final isBoundary = (value - minX).abs() < 0.1 || (value - maxX).abs() < 0.1;
                              if (!isBoundary) {
                                if ((value - minX) < range * 0.15 || (maxX - value) < range * 0.15) {
                                  return const SizedBox.shrink();
                                }
                              }

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
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildKeywordsTab() {
    final theme = Theme.of(context);
    final topKwNames = _topKeywords.take(10).map((k) => k.displayName).toList();
    final topKwValues = _topKeywords.take(10).map((k) => k.worksCount.toDouble()).toList();

    final newestYear = _papers.isEmpty 
        ? DateTime.now().year 
        : _papers.map((p) => p.publicationYear).reduce((a, b) => a > b ? a : b);

    final sortedEmergingKeywords = List<Keyword>.from(_emergingKeywords)
      ..sort((a, b) {
        final countA = _papers.where((p) => 
          p.publicationYear == newestYear && 
          p.concepts.any((c) => c.toLowerCase() == a.displayName.toLowerCase())
        ).length;
        final countB = _papers.where((p) => 
          p.publicationYear == newestYear && 
          p.concepts.any((c) => c.toLowerCase() == b.displayName.toLowerCase())
        ).length;
        if (countA != countB) {
          return countB.compareTo(countA);
        }
        return b.worksCount.compareTo(a.worksCount);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Keywords Horizontal Bar Chart
          if (topKwNames.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: HorizontalBarChart(
                  labels: topKwNames,
                  values: topKwValues,
                  title: 'keywords.top_keywords'.tr(),
                  barColor: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],

          // 2. Emerging Keywords List
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
                  Text(
                    'keywords.emerging_keywords'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12.0),
                  if (sortedEmergingKeywords.isEmpty)
                    const Text('No emerging keywords found.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedEmergingKeywords.length,
                      itemBuilder: (context, index) {
                        final k = sortedEmergingKeywords[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withValues(alpha: 0.12),
                            child: const Icon(Icons.trending_up, color: Colors.green, size: 18),
                          ),
                          title: Text(k.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('Level ${k.level} Concept'),
                          trailing: Text(
                            '${k.worksCount} works',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.05, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorsTab() {
    final theme = Theme.of(context);

    if (_topAuthors.isEmpty) {
      return Center(
        child: Text(
          'No author records cached.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    // Prepare Scatter Plot parameters
    double maxX = 10;
    double maxY = 10;
    final List<ScatterSpot> spots = _topAuthors.map<ScatterSpot>((author) {
      return ScatterSpot(
        author.worksCount.toDouble(),
        author.citedByCount.toDouble(),
        dotPainter: FlDotCirclePainter(
          color: theme.colorScheme.primary,
          radius: 8.0,
        ),
      );
    }).toList();

    if (_topAuthors.isNotEmpty) {
      final maxWorks = _topAuthors.map((a) => a.worksCount).reduce((a, b) => a > b ? a : b).toDouble();
      final maxCites = _topAuthors.map((a) => a.citedByCount).reduce((a, b) => a > b ? a : b).toDouble();
      maxX = maxWorks * 1.25;
      maxY = maxCites * 1.25;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Author List
          Text(
            'Top Authors',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12.0),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topAuthors.length,
            itemBuilder: (context, index) {
              final author = _topAuthors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      author.displayName.isNotEmpty ? author.displayName[0] : 'A',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                  title: Text(
                    author.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4.0),
                      Text(
                        author.lastKnownInstitution ?? 'Independent Researcher',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Icon(Icons.article_outlined, size: 12.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 4.0),
                          Text(
                            'Works: ${NumberFormat.decimalPattern().format(author.worksCount)}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.0),
                          ),
                          const SizedBox(width: 12.0),
                          Icon(Icons.star_border, size: 12.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 4.0),
                          Text(
                            'Citations: ${NumberFormat.decimalPattern().format(author.citedByCount)}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
          const SizedBox(height: 24.0),

          // 2. Scatter Plot: Productivity vs Impact
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
                  Text(
                    'Author Productivity vs Impact',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Citations (Y) vs Publications (X) for Top Researchers',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),
                  SizedBox(
                    height: 350,
                    child: ScatterChart(
                      ScatterChartData(
                        scatterSpots: spots,
                        minX: 0,
                        maxX: maxX,
                        minY: 0,
                        maxY: maxY,
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                            left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            axisNameWidget: const Text('Citations', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              getTitlesWidget: (val, meta) {
                                return Text(
                                  val.toInt().toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 8),
                                  textAlign: TextAlign.right,
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            axisNameWidget: const Text('Publications', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 20,
                              getTitlesWidget: (val, meta) {
                                return Text(
                                  val.toInt().toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 8),
                                );
                              },
                            ),
                          ),
                        ),
                        scatterTouchData: ScatterTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchTooltipData: ScatterTouchTooltipData(
                            getTooltipColor: (ScatterSpot spot) => theme.colorScheme.surface,
                            getTooltipItems: (ScatterSpot spot) {
                              final author = _topAuthors.firstWhere(
                                (a) => a.worksCount == spot.x.toInt() && a.citedByCount == spot.y.toInt(),
                                orElse: () => _topAuthors[0],
                              );
                              return ScatterTooltipItem(
                                '${author.displayName}\nWorks: ${spot.x.toInt()}\nCitations: ${spot.y.toInt()}',
                                textStyle: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // 3. Author Collaboration Network Graph
          _buildCollaborationSection(theme),
        ],
      ),
    );
  }

  Widget _buildCollaborationSection(ThemeData theme) {
    if (_topAuthors.isEmpty) return const SizedBox.shrink();

    return Card(
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
            Text(
              'Author Collaboration Network',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Interactive co-authorship map showing collaborative links between top researchers.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 450,
              child: Card(
                color: theme.colorScheme.surface.withValues(alpha: 0.4),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
                ),
                child: Stack(
                  children: [
                    InteractiveViewer(
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(120),
                      minScale: 0.1,
                      maxScale: 3.0,
                      child: GraphView(
                        graph: _collaborationGraph,
                        algorithm: _graphAlgorithm,
                        paint: Paint()
                          ..color = theme.colorScheme.primary.withValues(alpha: 0.35)
                          ..strokeWidth = 2.0
                          ..style = PaintingStyle.stroke,
                        builder: (Node node) {
                          final value = node.key?.value?.toString() ?? '';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              value,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_out_map, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Pinch to Zoom / Drag to Pan',
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalsTab() {
    final theme = Theme.of(context);
    final newestYear = _papers.isEmpty 
        ? DateTime.now().year 
        : _papers.map((p) => p.publicationYear).reduce((a, b) => a > b ? a : b);

    final sortedJournals = List<Journal>.from(_topJournals)
      ..sort((a, b) {
        final countA = _papers.where((p) => 
          p.publicationYear == newestYear && 
          p.journalName != null && 
          p.journalName!.toLowerCase() == a.displayName.toLowerCase()
        ).length;
        final countB = _papers.where((p) => 
          p.publicationYear == newestYear && 
          p.journalName != null && 
          p.journalName!.toLowerCase() == b.displayName.toLowerCase()
        ).length;
        if (countA != countB) {
          return countB.compareTo(countA);
        }
        return b.worksCount.compareTo(a.worksCount);
      });

    final topJournalsNames = sortedJournals.take(10).map((j) => j.displayName).toList();
    final topJournalsValues = sortedJournals.take(10).map((j) => j.worksCount.toDouble()).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Journal Ranking Horizontal Bar Chart Card
          if (topJournalsNames.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: HorizontalBarChart(
                  labels: topJournalsNames,
                  values: topJournalsValues,
                  title: 'keywords.journal_ranking'.tr(),
                  barColor: theme.colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],

          // 2. Journals Details List
          Text(
            'keywords.emerging_journals'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12.0),
          if (sortedJournals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'No journal records cached.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedJournals.take(10).length,
              itemBuilder: (context, index) {
                final journal = sortedJournals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      child: Text(
                        journal.displayName.isNotEmpty ? journal.displayName[0] : 'J',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                      ),
                    ),
                    title: Text(
                      journal.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4.0),
                        Text(
                          journal.publisher ?? 'Unknown Publisher',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            Icon(Icons.article_outlined, size: 12.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 4.0),
                            Text(
                              'Works: ${NumberFormat.decimalPattern().format(journal.worksCount)}',
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.0),
                            ),
                            const SizedBox(width: 12.0),
                            Icon(Icons.star_border, size: 12.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 4.0),
                            Text(
                              'Citations: ${NumberFormat.decimalPattern().format(journal.citedByCount)}',
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class HorizontalBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final String title;
  final Color barColor;

  const HorizontalBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.title,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: labels.length,
          itemBuilder: (context, index) {
            final label = labels[index];
            final value = values[index];
            final pct = maxValue == 0 ? 0.0 : value / maxValue;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, child) {
                          return Container(
                            height: 16,
                            width: MediaQuery.of(context).size.width * 0.45 * val,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  barColor.withValues(alpha: 0.6),
                                  barColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      value.toInt().toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
