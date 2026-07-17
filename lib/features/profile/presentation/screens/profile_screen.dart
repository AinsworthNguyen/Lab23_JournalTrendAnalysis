import 'dart:io';
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../injection_container.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/firebase/firebase_remote_config_service.dart';
import '../../../../core/firebase/firebase_crashlytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../personalization/domain/entities/user_preferences.dart';
import '../../../personalization/domain/usecases/get_user_preferences_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../home/presentation/blocs/dashboard_bloc.dart';
import '../../../home/presentation/blocs/dashboard_state.dart';
import '../../../personalization/presentation/blocs/auth_bloc.dart';
import '../../../personalization/presentation/blocs/auth_event.dart';
import '../../../personalization/presentation/blocs/auth_state.dart';
import '../blocs/theme_cubit.dart';
import '../blocs/report_cubit.dart';
import '../blocs/report_state.dart';
import '../blocs/notification_cubit.dart';
import '../../../personalization/data/datasources/personalization_local_data_source.dart';
import '../../../keywords/data/datasources/keywords_local_data_source.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserPreferences? _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPrefs();
  }

  void _loadUserPrefs() async {
    final usecase = getIt<GetUserPreferencesUseCase>();
    final result = await usecase(const NoParams());
    if (mounted) {
      result.fold(
        (failure) => setState(() => _isLoading = false),
        (prefs) => setState(() {
          _prefs = prefs;
          _isLoading = false;
        }),
      );
    }
  }

  void _clearCacheAndReset(BuildContext context) async {
    await getIt<KeywordsLocalDataSource>().clearCache();
    await getIt<PersonalizationLocalDataSource>().clearUserPreferences();
    if (context.mounted) {
      context.go('/setup');
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('profile.clear_cache'.tr()),
          content: Text('profile.clear_cache_desc'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'profile.clear_cache_cancel'.tr(),
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _clearCacheAndReset(context);
              },
              child: Text(
                'profile.clear_cache_confirm'.tr(),
                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = getIt<IFirebaseAuthService>();
    final user = authService.currentUser;

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => getIt<AuthBloc>()),
        BlocProvider<ReportCubit>(create: (context) => getIt<ReportCubit>()),
        BlocProvider<NotificationCubit>(create: (context) => getIt<NotificationCubit>()..fetchTokenAndLog()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'profile.title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : MultiBlocListener(
                  listeners: [
                    BlocListener<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is Unauthenticated) {
                          context.go('/login');
                        } else if (state is AuthError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
                          );
                        }
                      },
                    ),
                    BlocListener<ReportCubit, ReportState>(
                      listener: (context, state) {
                        if (state is ReportUploadSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report generated and uploaded successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (state is ReportFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Report error: ${state.message}'),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Header Card (Firebase details)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: const BorderSide(color: AppColors.border, width: 1.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30.0,
                                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                                  child: user?.photoURL == null
                                      ? Text(
                                          user?.displayName?.isNotEmpty == true ? user!.displayName![0] : 'U',
                                          style: TextStyle(
                                            fontSize: 24.0,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.displayName ?? _prefs?.fullName ?? 'Researcher',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        user?.email ?? 'No Google Account Linked',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        'Field: ${_prefs?.interestConceptName ?? "None"}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // PDF Report Export Panel
                        _buildSectionHeader(theme, 'Analytics Export'),
                        const SizedBox(height: 8.0),
                        BlocBuilder<ReportCubit, ReportState>(
                          builder: (context, state) {
                            final isGenerating = state is ReportGenerating;
                            final isUploading = state is ReportUploading;
                            final isBusy = isGenerating || isUploading;

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                side: const BorderSide(color: AppColors.border, width: 1.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Generate PDF Summary Report',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                    ),
                                    const SizedBox(height: 8.0),
                                    const Text(
                                      'Export your dashboard metrics, active publications, and citations directly to a shareable PDF document stored securely in Firebase Storage.',
                                      style: TextStyle(fontSize: 13.0, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16.0),
                                    if (state is ReportUploadSuccess) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.green),
                                            const SizedBox(width: 8.0),
                                            Expanded(
                                              child: SelectableText(
                                                state.downloadUrl,
                                                style: const TextStyle(fontSize: 12.0),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 20.0),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: state.downloadUrl));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Link copied to clipboard!')),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.picture_as_pdf, size: 20.0),
                                              tooltip: 'Open PDF',
                                              onPressed: () async {
                                                try {
                                                  if (state.downloadUrl.startsWith('file://')) {
                                                    final localPath = state.downloadUrl.replaceFirst('file://', '');
                                                    final file = File(localPath);
                                                    if (await file.exists()) {
                                                      final bytes = await file.readAsBytes();
                                                      await Printing.layoutPdf(
                                                        onLayout: (format) async => bytes,
                                                        name: 'dashboard_report.pdf',
                                                      );
                                                    } else {
                                                      if (!context.mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Local PDF file not found')),
                                                      );
                                                    }
                                                  } else {
                                                    // Remote URL download
                                                    final url = Uri.parse(state.downloadUrl);
                                                    final client = HttpClient();
                                                    final request = await client.getUrl(url);
                                                    final response = await request.close();
                                                    final bytes = await response.fold<List<int>>([], (a, b) => a..addAll(b));
                                                    await Printing.layoutPdf(
                                                      onLayout: (format) async => Uint8List.fromList(bytes),
                                                      name: 'dashboard_report.pdf',
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error opening PDF: $e')),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12.0),
                                    ],
                                    ElevatedButton.icon(
                                      onPressed: isBusy
                                          ? null
                                          : () {
                                              // Read metrics from DashboardBloc
                                              final dashboardBloc = getIt<DashboardBloc>();
                                              final dashboardState = dashboardBloc.state;

                                              int totalPubs = 450;
                                              double avgCit = 18.5;
                                              int totalCit = 8325;
                                              int actYear = 2024;
                                              String topJour = 'Nature';
                                              String topAuth = 'Dr. John Doe';

                                              if (dashboardState is DashboardLoaded) {
                                                totalPubs = dashboardState.totalPublications;
                                                avgCit = dashboardState.avgCitations;
                                                totalCit = dashboardState.totalCitations;
                                                actYear = dashboardState.activeYear;
                                                topJour = dashboardState.topJournal;
                                                topAuth = dashboardState.topAuthor;
                                              }

                                              context.read<ReportCubit>().exportReport(
                                                    conceptName: _prefs?.interestConceptName ?? 'General Science',
                                                    fullName: user?.displayName ?? _prefs?.fullName ?? 'Researcher',
                                                    totalPublications: totalPubs,
                                                    avgCitations: avgCit,
                                                    totalCitations: totalCit,
                                                    activeYear: actYear,
                                                    topJournal: topJour,
                                                    topAuthor: topAuth,
                                                  );
                                            },
                                      icon: isBusy
                                          ? const SizedBox(
                                              height: 18.0,
                                              width: 18.0,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.picture_as_pdf),
                                      label: Text(
                                        isGenerating
                                            ? 'Generating PDF...'
                                            : isUploading
                                                ? 'Uploading PDF...'
                                                : 'Export PDF Report',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: theme.colorScheme.onPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24.0),

                        // Notification Center Widget (FCM Messages)
                        _buildSectionHeader(theme, 'Notification Center'),
                        const SizedBox(height: 8.0),
                        BlocBuilder<NotificationCubit, List<RemoteMessage>>(
                          builder: (context, messages) {
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                side: const BorderSide(color: AppColors.border, width: 1.0),
                              ),
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: messages.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: Center(
                                          child: Text(
                                            'No notifications received yet.\n(Foreground push events will append here)',
                                            style: TextStyle(color: Colors.grey, fontSize: 13.0),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: messages.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1.0),
                                        itemBuilder: (context, index) {
                                          final msg = messages[index];
                                          return ListTile(
                                            leading: const CircleAvatar(
                                              child: Icon(Icons.notifications_active, size: 20.0),
                                            ),
                                            title: Text(msg.notification?.title ?? 'Notification'),
                                            subtitle: Text(msg.notification?.body ?? 'No details provided'),
                                          );
                                        },
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24.0),

                        // Remote Config Constraints Preview
                        _buildSectionHeader(theme, 'Remote Configurations'),
                        const SizedBox(height: 8.0),
                        Builder(
                          builder: (context) {
                            final remoteConfig = getIt<IFirebaseRemoteConfigService>();
                            final maxJournals = remoteConfig.getInt('max_journals_limit');
                            final maxKeywords = remoteConfig.getInt('max_keywords_limit');

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                side: const BorderSide(color: AppColors.border, width: 1.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    _buildConfigItem(
                                      'Max Journals List Limit',
                                      '$maxJournals items',
                                      'Restricts pagination metrics dynamically',
                                    ),
                                    const Divider(height: 16.0),
                                    _buildConfigItem(
                                      'Max Keywords List Limit',
                                      '$maxKeywords items',
                                      'Controls active keyword tracking list limits',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24.0),

                        // Crashlytics Testing Hooks
                        _buildSectionHeader(theme, 'Developer Logs & Diagnostics'),
                        const SizedBox(height: 8.0),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: const BorderSide(color: AppColors.border, width: 1.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          try {
                                            throw Exception('Handled developer test exception for Crashlytics.');
                                          } catch (e, s) {
                                            getIt<IFirebaseCrashlyticsService>().recordError(e, s);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Handled error logged in Crashlytics.')),
                                            );
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                                          side: BorderSide(color: theme.colorScheme.primary),
                                        ),
                                        child: const Text('Log Handled Error'),
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          getIt<IFirebaseCrashlyticsService>().forceCrash();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.error,
                                          foregroundColor: theme.colorScheme.onError,
                                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        ),
                                        child: const Text('Force App Crash'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // Settings Section Header
                        _buildSectionHeader(theme, 'profile.settings'.tr()),
                        const SizedBox(height: 8.0),

                        // Theme selector
                        BlocBuilder<ThemeCubit, ThemeMode>(
                          builder: (context, currentThemeMode) {
                            return _buildSettingItem(
                              context,
                              title: 'profile.theme'.tr(),
                              icon: Icons.dark_mode_outlined,
                              trailing: DropdownButton<ThemeMode>(
                                value: currentThemeMode,
                                underline: const SizedBox.shrink(),
                                focusColor: Colors.transparent,
                                borderRadius: BorderRadius.circular(12.0),
                                onChanged: (ThemeMode? newMode) {
                                  if (newMode != null) {
                                    context.read<ThemeCubit>().setTheme(newMode);
                                  }
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: ThemeMode.light,
                                    child: Text('profile.theme_light'.tr()),
                                  ),
                                  DropdownMenuItem(
                                    value: ThemeMode.dark,
                                    child: Text('profile.theme_dark'.tr()),
                                  ),
                                  DropdownMenuItem(
                                    value: ThemeMode.system,
                                    child: Text('profile.theme_system'.tr()),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Language selector
                        _buildSettingItem(
                          context,
                          title: 'profile.language'.tr(),
                          icon: Icons.language,
                          trailing: DropdownButton<Locale>(
                            value: context.locale,
                            underline: const SizedBox.shrink(),
                            focusColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(12.0),
                            onChanged: (Locale? newLocale) {
                              if (newLocale != null) {
                                context.setLocale(newLocale);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: Locale('en'),
                                child: Text('English'),
                              ),
                              DropdownMenuItem(
                                value: Locale('vi'),
                                child: Text('Tiếng Việt'),
                              ),
                            ],
                          ),
                        ),

                        // Clear Cache Action
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                          leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                          title: Text(
                            'profile.clear_cache'.tr(),
                            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w500),
                          ),
                          onTap: () => _showClearCacheDialog(context),
                        ),

                        // Firebase Sign Out Action
                        Builder(
                          builder: (context) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                              leading: Icon(Icons.logout, color: theme.colorScheme.error),
                              title: Text(
                                'Sign Out from Google',
                                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w500),
                              ),
                              onTap: () async {
                                // Clear all local caches and database boxes
                                await getIt<KeywordsLocalDataSource>().clearCache();
                                await getIt<PersonalizationLocalDataSource>().clearUserPreferences();
                                try {
                                  await Hive.box('analytics_cache').clear();
                                } catch (_) {}
                                try {
                                  await Hive.box('search_history').clear();
                                } catch (_) {}
                                
                                if (context.mounted) {
                                  context.read<AuthBloc>().add(SignOutRequested());
                                }
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 32.0),

                        // About section
                        _buildSectionHeader(theme, 'profile.about'.tr()),
                        const SizedBox(height: 8.0),

                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'profile.about_desc'.tr(),
                                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                ),
                                const Divider(height: 24.0),
                                Text(
                                  'profile.version'.tr(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.2),
    );
  }

  Widget _buildConfigItem(String title, String value, String desc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
              const SizedBox(height: 2.0),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11.0)),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
        leading: Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: trailing,
      ),
    );
  }
}
