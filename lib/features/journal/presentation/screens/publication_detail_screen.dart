import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/paper.dart';
import '../../domain/usecases/get_publication_details_usecase.dart';
import '../../../../core/firebase/firebase_analytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/network/openrouter_service.dart';

class PublicationDetailScreen extends StatefulWidget {
  final String paperId;
  const PublicationDetailScreen({super.key, required this.paperId});

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  Paper? _paper;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAuthorsExpanded = false;
  bool _isAiLoading = false;
  Map<String, dynamic>? _aiResponse;

  void _getAiInsights() async {
    if (_paper == null || _paper!.abstractText == null) return;
    setState(() {
      _isAiLoading = true;
      _aiResponse = null;
    });

    final openRouter = OpenRouterService();
    final result = await openRouter.summarizeAbstract(_paper!.abstractText!);

    if (mounted) {
      setState(() {
        _isAiLoading = false;
        _aiResponse = result;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPaper();
  }

  void _loadPaper() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final usecase = getIt<GetPublicationDetailsUseCase>();
    final result = await usecase(widget.paperId);

    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        }),
        (paper) {
          getIt<IFirebaseAnalyticsService>().logViewPublication(
            paper.title,
            paper.publicationYear,
          );
          setState(() {
            _isLoading = false;
            _paper = paper;
          });
        },
      );
    }
  }

  Future<void> _launchDoi(String doiUrl) async {
    final uri = Uri.parse(doiUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $doiUrl';
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
    final isVi = EasyLocalization.of(context)?.locale.languageCode == 'vi';

    return Scaffold(
      appBar: AppBar(title: Text('journal.details_title'.tr())),
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
                      ElevatedButton(
                        onPressed: _loadPaper,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_paper == null) {
              return const Center(
                child: Text('Publication details not found.'),
              );
            }

            final paper = _paper!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Badges row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 5.0,
                        ),
                        decoration: BoxDecoration(
                          color: paper.isOpenAccess
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              paper.isOpenAccess ? Icons.lock_open : Icons.lock,
                              size: 14.0,
                              color: paper.isOpenAccess
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              paper.isOpenAccess
                                  ? 'journal.open_access'.tr()
                                  : 'journal.closed_access'.tr(),
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: paper.isOpenAccess
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Icon(
                        Icons.format_quote,
                        size: 16.0,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${'journal.citations'.tr()}: ${NumberFormat.decimalPattern().format(paper.citationCount)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Title
                  Text(
                    paper.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Journal name & Year info
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 20.0,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Text(
                                  paper.journalName ??
                                      'No journal info available',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24.0),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 20.0,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Text(
                                'journal.published_in'.tr(
                                  namedArgs: {
                                    'year': paper.publicationYear.toString(),
                                  },
                                ),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Authors Section
                  Text(
                    'journal.authors'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  if (paper.authors.isEmpty)
                    Text(
                      'No authors listed.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                        height: 1.4,
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final hasMore = paper.authors.length > 3;
                        final isVi =
                            EasyLocalization.of(context)?.locale.languageCode ==
                            'vi';

                        if (!hasMore) {
                          return Text(
                            paper.authors.join(', '),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                              height: 1.4,
                            ),
                          );
                        }

                        if (_isAuthorsExpanded) {
                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: paper.authors.join(', '),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                    height: 1.4,
                                  ),
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isAuthorsExpanded = false;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        isVi ? 'Thu gọn' : 'Collapse',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: paper.authors.take(3).join(', '),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                    height: 1.4,
                                  ),
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isAuthorsExpanded = true;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Text(
                                        isVi ? '... Xem thêm' : '...more',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  const SizedBox(height: 24.0),

                  // Abstract Section
                  Text(
                    'journal.abstract'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    paper.abstractText ?? 'journal.abstract_not_available'.tr(),
                    textAlign: TextAlign.justify,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                  if (paper.abstractText != null &&
                      paper.abstractText!.isNotEmpty) ...[
                    const SizedBox(height: 24.0),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        side: BorderSide(
                          color: _aiResponse != null
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : theme.colorScheme.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.surface,
                              theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: theme.colorScheme.primary,
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      isVi
                                          ? 'Tóm tắt & Dịch thuật AI (Gemini)'
                                          : 'AI Summary & Translation (Gemini)',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                  if (_aiResponse != null && !_isAiLoading) ...[
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.refresh,
                                        size: 18.0,
                                      ),
                                      onPressed: _getAiInsights,
                                      tooltip: isVi ? 'Tải lại' : 'Refresh',
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12.0),
                              if (_aiResponse == null && !_isAiLoading) ...[
                                Text(
                                  isVi
                                      ? 'Sử dụng mô hình AI Gemini để dịch thuật và tóm tắt nhanh bài báo khoa học này thành các ý chính tiếng Việt.'
                                      : 'Use Gemini AI model to quickly summarize and translate this scientific abstract into key Vietnamese insights.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                ElevatedButton.icon(
                                  onPressed: _getAiInsights,
                                  icon: const Icon(Icons.bolt),
                                  label: Text(
                                    isVi
                                        ? 'Tạo tóm tắt AI'
                                        : 'Generate AI Summary',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                ),
                              ] else if (_isAiLoading) ...[
                                Column(
                                  children: [
                                    const SizedBox(height: 16.0),
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    Text(
                                      isVi
                                          ? 'AI đang phân tích tóm tắt bài viết...'
                                          : 'AI is generating academic insights...',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                  ],
                                ),
                              ] else if (_aiResponse != null) ...[
                                const Text(
                                  'Tóm tắt nội dung chính:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0,
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                ...(_aiResponse!['bullets'] as List<dynamic>? ??
                                        [])
                                    .map((bullet) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4.0,
                                          bottom: 10.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 18.0,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 10.0),
                                            Expanded(
                                              child: Text(
                                                bullet.toString(),
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      height: 1.4,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.9,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                const SizedBox(height: 8.0),
                                if (_aiResponse!['contribution'] != null) ...[
                                  const Text(
                                    'Đóng góp khoa học chính:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Container(
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Text(
                                      _aiResponse!['contribution'].toString(),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            height: 1.4,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.9),
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 36.0),

                  // DOI Link Button
                  if (paper.doi != null && paper.doi!.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _launchDoi(paper.doi!),
                      icon: const Icon(Icons.open_in_new),
                      label: Text('journal.view_doi'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20.0),
                ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
              ),
            );
          },
        ),
      ),
    );
  }
}
