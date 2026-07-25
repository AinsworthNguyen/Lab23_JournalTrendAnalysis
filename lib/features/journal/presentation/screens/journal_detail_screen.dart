import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/firebase/firebase_analytics_service.dart';
import '../../domain/entities/journal.dart';
import '../../domain/entities/paper.dart';
import '../../domain/usecases/get_journal_details_usecase.dart';
import '../../data/models/paper_model.dart';

class JournalDetailScreen extends StatefulWidget {
  final String journalId;
  const JournalDetailScreen({super.key, required this.journalId});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Journal? _journal;
  List<Paper> _papers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Log analytics event
      await getIt<IFirebaseAnalyticsService>().logViewJournal(widget.journalId);

      // 2. Fetch journal details
      final detailsResult = await getIt<GetJournalDetailsUseCase>().call(
        widget.journalId,
      );

      Journal? journalDetail;
      detailsResult.fold(
        (failure) => throw failure.message,
        (journal) => journalDetail = journal,
      );

      // 3. Fetch publications in this journal
      List<Paper> journalPapers = [];
      try {
        final response = await getIt<ApiClient>().get(
          '/works',
          queryParameters: {
            'filter':
                'primary_location.source.id:${widget.journalId},publication_year:<2026',
            'per_page': 10,
          },
        );
        final results = response['results'] as List<dynamic>? ?? [];
        journalPapers = results
            .map((json) => PaperModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Safe fallback for papers fetch
        debugPrint('Failed to load papers for journal: $e');
      }

      if (mounted) {
        setState(() {
          _journal = journalDetail;
          _papers = journalPapers;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open link: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journal Detail',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(child: _buildBody(theme)),
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
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
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
            // Header Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    if (journal.homepageUrl != null &&
                        journal.homepageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16.0),
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(journal.homepageUrl!),
                        icon: const Icon(Icons.language),
                        label: const Text('Visit Homepage'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ],
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
                          side: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                color: theme.colorScheme.primary,
                                size: 24.0,
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                NumberFormat.compact().format(
                                  journal.worksCount,
                                ),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Total Works',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
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
                          side: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.format_quote,
                                color: Colors.green,
                                size: 24.0,
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                NumberFormat.compact().format(
                                  journal.citedByCount,
                                ),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Total Citations',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 24.0),

            // Top Publications Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                'Top Publications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12.0),

            // Publications List
            if (_papers.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No publication data available for this journal.',
                    ),
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
                          side: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
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
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12.0,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  paper.publicationYear.toString(),
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(width: 16.0),
                                Icon(
                                  Icons.format_quote,
                                  size: 12.0,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
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
                      )
                      .animate(delay: (200 + index * 40).ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0);
                },
              ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}
