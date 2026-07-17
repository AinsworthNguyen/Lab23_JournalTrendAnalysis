import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../injection_container.dart';
import '../blocs/publications_cubit.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PublicationsCubit>(
      create: (context) => getIt<PublicationsCubit>()..loadInitialPapers(),
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
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<PublicationsCubit>().loadNextPage();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    context.read<PublicationsCubit>().search(query);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatAuthors(List<String> authors) {
    if (authors.isEmpty) return 'No authors listed';
    if (authors.length <= 2) return authors.join(', ');
    return '${authors.sublist(0, 2).join(', ')} +${authors.length - 2} more';
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
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'journal.search_placeholder'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),

            // Papers List
            Expanded(
              child: BlocBuilder<PublicationsCubit, PublicationsState>(
                builder: (context, state) {
                  if (state.isLoading && state.papers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.errorMessage != null && state.papers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage!,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<PublicationsCubit>().loadInitialPapers();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state.papers.isEmpty) {
                    return Center(
                      child: Text(
                        'No publications found.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: state.papers.length + (state.hasReachedMax ? 0 : 1),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemBuilder: (context, index) {
                      if (index >= state.papers.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        );
                      }

                      final paper = state.papers[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.0),
                          onTap: () {
                            context.push('/journal/publication/${paper.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                            size: 12.0,
                                            color: paper.isOpenAccess ? Colors.green : Colors.grey,
                                          ),
                                          const SizedBox(width: 4.0),
                                          Text(
                                            paper.isOpenAccess
                                                ? 'journal.open_access'.tr()
                                                : 'journal.closed_access'.tr(),
                                            style: TextStyle(
                                              fontSize: 10.0,
                                              fontWeight: FontWeight.bold,
                                              color: paper.isOpenAccess ? Colors.green : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    // Citation Badge
                                    Icon(Icons.star, size: 14.0, color: theme.colorScheme.primary),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      NumberFormat.decimalPattern().format(paper.citationCount),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12.0),
                                Text(
                                  paper.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  _formatAuthors(paper.authors),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        paper.journalName ?? 'No journal info',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'journal.published_in'.tr(namedArgs: {'year': paper.publicationYear.toString()}),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
