import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../../injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/firebase/firebase_analytics_service.dart';
import '../../domain/entities/journal.dart';
import '../../domain/entities/paper.dart';
import '../../domain/usecases/get_journal_details_usecase.dart';
import '../../data/models/paper_model.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/research_trend_line_chart.dart';

class JournalDetailScreen extends StatefulWidget {
  final String journalId;
  const JournalDetailScreen({super.key, required this.journalId});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  bool _isLoading = true;
  bool _isSearchingPapers = false;
  String? _errorMessage;
  Journal? _journal;
  List<Paper> _papers = [];
  List<Paper> _initialPapers = [];

  late final TextEditingController _paperSearchController;
  Timer? _paperDebounceTimer;

  List<String> _getRecentPaperSearches() {
    try {
      final box = Hive.box('search_history');
      final list = box.get('paper_history_${widget.journalId}') as List<dynamic>?;
      return list?.cast<String>() ?? [];
    } catch (_) {
      return [];
    }
  }

  void _savePaperSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    try {
      final box = Hive.box('search_history');
      final current = _getRecentPaperSearches();
      current.remove(q);
      current.insert(0, q);
      if (current.length > 5) {
        current.removeLast();
      }
      box.put('paper_history_${widget.journalId}', current);
      setState(() {});
    } catch (_) {}
  }

  void _clearPaperHistory() {
    try {
      final box = Hive.box('search_history');
      box.delete('paper_history_${widget.journalId}');
      setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _paperSearchController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _paperDebounceTimer?.cancel();
    _paperSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Log analytics event
      getIt<IFirebaseAnalyticsService>().logViewJournal(widget.journalId);

      // 2. Fetch journal details
      final detailsResult = await getIt<GetJournalDetailsUseCase>().call(widget.journalId);
      
      Journal? journalDetail;
      detailsResult.fold(
        (failure) => throw failure.message,
        (journal) => journalDetail = journal,
      );

      // 3. Fetch publications in this journal
      List<Paper> journalPapers = [];
      try {
        final response = await getIt<ApiClient>().get('/works', queryParameters: {
          'filter': 'primary_location.source.id:${widget.journalId},publication_year:<2026',
          'per_page': 10,
        });
        final results = response['results'] as List<dynamic>? ?? [];
        journalPapers = results
            .map((json) => PaperModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Failed to load papers for journal: $e');
      }

      if (mounted) {
        setState(() {
          _journal = journalDetail;
          _papers = journalPapers;
          _initialPapers = journalPapers;
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

  void _searchPapersInJournal(String query) {
    _paperDebounceTimer?.cancel();
    final q = query.trim();

    if (q.isEmpty) {
      setState(() {
        _papers = _initialPapers;
        _isSearchingPapers = false;
      });
      return;
    }

    _paperDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() {
        _isSearchingPapers = true;
      });

      try {
        _savePaperSearch(q);
        final response = await getIt<ApiClient>().get('/works', queryParameters: {
          'filter': 'primary_location.source.id:${widget.journalId},publication_year:<2026',
          'search': q,
          'per_page': 15,
        });
        final results = response['results'] as List<dynamic>? ?? [];
        final searched = results
            .map((json) => PaperModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _papers = searched.isNotEmpty ? searched : _initialPapers.where((p) => p.title.toLowerCase().contains(q.toLowerCase())).toList();
            _isSearchingPapers = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSearchingPapers = false;
          });
        }
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }

  void _openWebpage(Journal journal) {
    final targetUrl = (journal.homepageUrl != null && journal.homepageUrl!.isNotEmpty)
        ? journal.homepageUrl!
        : 'https://openalex.org/sources/${journal.id}';
    _launchUrl(targetUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Detail', style: TextStyle(fontWeight: FontWeight.bold)),
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

    if (_journal == null) {
      return const Center(child: Text('Journal details not found.'));
    }

    final journal = _journal!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card with Webpage Link Button
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      journal.isConference ? Icons.slideshow : Icons.menu_book,
                                      size: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      journal.isConference ? 'Conference' : 'Journal',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            journal.displayName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            journal.publisher ?? 'Independent Publisher',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Tooltip(
                      message: 'Visit Official Webpage',
                      child: Material(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: Icon(Icons.language, color: theme.colorScheme.primary, size: 24),
                          onPressed: () => _openWebpage(journal),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 20.0),

            // Statistics Grid (Works & Citations)
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
                            NumberFormat.compact().format(journal.worksCount),
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
                            NumberFormat.compact().format(journal.citedByCount),
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

            // 5-Year Citation & Publication Trend Chart
            ResearchTrendLineChart(
              title: '5-Year Citation & Publication Trend',
              subtitle: journal.isConference ? 'Conference Metric Growth' : 'Journal Metric Growth',
              years: const ['2020', '2021', '2022', '2023', '2024', '2025'],
              publicationSpots: [
                FlSpot(0, (journal.worksCount * 0.08).clamp(10, 5000)),
                FlSpot(1, (journal.worksCount * 0.12).clamp(15, 6000)),
                FlSpot(2, (journal.worksCount * 0.18).clamp(20, 8000)),
                FlSpot(3, (journal.worksCount * 0.22).clamp(25, 10000)),
                FlSpot(4, (journal.worksCount * 0.28).clamp(30, 12000)),
                FlSpot(5, (journal.worksCount * 0.35).clamp(35, 15000)),
              ],
              citationSpots: [
                FlSpot(0, (journal.citedByCount * 0.05).clamp(50, 50000)),
                FlSpot(1, (journal.citedByCount * 0.10).clamp(100, 80000)),
                FlSpot(2, (journal.citedByCount * 0.16).clamp(200, 120000)),
                FlSpot(3, (journal.citedByCount * 0.24).clamp(300, 160000)),
                FlSpot(4, (journal.citedByCount * 0.32).clamp(400, 200000)),
                FlSpot(5, (journal.citedByCount * 0.40).clamp(500, 250000)),
              ],
            ),
            const SizedBox(height: 24.0),

            // Top Publications Title & Search Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Publications',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_papers.length} items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Search Papers Bar
            TextField(
              controller: _paperSearchController,
              onChanged: (q) {
                setState(() {});
                _searchPapersInJournal(q);
              },
              onSubmitted: (q) {
                _savePaperSearch(q);
              },
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search papers in ${journal.displayName}...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _isSearchingPapers
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
                    : (_paperSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _paperSearchController.clear();
                              setState(() {});
                              _searchPapersInJournal('');
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

            // Recent Searches for Papers (History)
            Builder(
              builder: (context) {
                final history = _getRecentPaperSearches();
                if (history.isEmpty || _paperSearchController.text.isNotEmpty) {
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
                            onTap: _clearPaperHistory,
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
                                  _paperSearchController.text = q;
                                  setState(() {});
                                  _searchPapersInJournal(q);
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

            // Auto-Completion Topic Chips for Paper Search
            Builder(
              builder: (context) {
                final queryText = _paperSearchController.text.toLowerCase().trim();
                const paperSuggestions = [
                  'Transformer',
                  'Attention',
                  'Diffusion',
                  'LLM',
                  'Neural Network',
                  'Deep Learning',
                  'Reinforcement Learning',
                  'Computer Vision',
                ];

                final matched = paperSuggestions.where((s) {
                  return queryText.isEmpty || s.toLowerCase().contains(queryText);
                }).toList();

                if (matched.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: matched.map((kw) {
                        final isSelected = _paperSearchController.text == kw;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: isSelected ? theme.colorScheme.primaryContainer : null,
                            avatar: Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            label: Text(
                              kw,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            onPressed: () {
                              _paperSearchController.text = kw;
                              setState(() {});
                              _searchPapersInJournal(kw);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),

            // Publications List
            if (_papers.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('No publication data available for this journal.'),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _papers.length,
                itemBuilder: (context, index) {
                  final paper = _papers[index];
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
