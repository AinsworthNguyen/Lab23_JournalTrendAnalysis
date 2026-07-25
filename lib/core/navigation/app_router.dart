import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../injection_container.dart';
import '../../core/firebase/firebase_auth_service.dart';
import '../../features/personalization/presentation/screens/login_screen.dart';
import '../../features/personalization/presentation/screens/setup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/journal/presentation/screens/publication_detail_screen.dart';
import '../../features/journal/presentation/screens/journal_detail_screen.dart';
import '../../features/keywords/presentation/screens/keywords_screen.dart';
import '../../features/keywords/presentation/screens/keyword_detail_screen.dart';
import '../../features/author/presentation/screens/author_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_web_screen.dart';
import '../constants/prefs_keys.dart';
import '../utils/app_logger.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'home',
);
final GlobalKey<NavigatorState> journalNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'journal',
);
final GlobalKey<NavigatorState> keywordsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'keywords');
final GlobalKey<NavigatorState> profileNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'profile',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  redirect: (final BuildContext context, final GoRouterState state) {
    try {
      final IFirebaseAuthService authService = getIt<IFirebaseAuthService>();
      final bool isLoggedIn =
          authService.currentUser != null || authService.isBypassed;
      final bool isGoingToLogin = state.matchedLocation == '/login';
      final bool isGoingToAdmin = state.matchedLocation == '/admin';

      if (!isLoggedIn) {
        if (!isGoingToLogin) {
          return '/login';
        }
        return null;
      }

      if (isGoingToAdmin) {
        if (!authService.isAdmin) {
          return '/home';
        }
        return null;
      }

      // Logged in: check onboarding/personalization
      final SharedPreferences prefs = getIt<SharedPreferences>();
      final String? name = prefs.getString(PrefsKeys.fullName);
      final bool isPersonalized = name != null && name.trim().isNotEmpty;
      final bool isGoingToSetup = state.matchedLocation == '/setup';

      if (!isPersonalized) {
        if (!isGoingToSetup) {
          return '/setup';
        }
        return null;
      }

      // Logged in & Personalized
      if (isGoingToLogin || isGoingToSetup) {
        if (authService.isAdmin) {
          return '/admin';
        }
        return '/home';
      }
    } on Exception catch (e, st) {
      AppLogger.e('Router redirect error', e, st);
      return '/login'; // Fail-safe: redirect to login
    }
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/admin',
      builder: (final BuildContext context, final GoRouterState state) =>
          const AdminWebScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (final BuildContext context, final GoRouterState state) =>
          const LoginScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (final BuildContext context, final GoRouterState state) =>
          const PersonalizationSetupScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder:
          (
            final BuildContext context,
            final GoRouterState state,
            final StatefulNavigationShell navigationShell,
          ) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          navigatorKey: homeNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/home',
              builder:
                  (final BuildContext context, final GoRouterState state) =>
                      const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: journalNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/journal',
              builder:
                  (final BuildContext context, final GoRouterState state) =>
                      const JournalScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'publication/:id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder:
                      (final BuildContext context, final GoRouterState state) {
                        final String id = state.pathParameters['id'] ?? '';
                        return PublicationDetailScreen(paperId: id);
                      },
                ),
                GoRoute(
                  path: 'detail/:jid',
                  parentNavigatorKey: rootNavigatorKey,
                  builder:
                      (final BuildContext context, final GoRouterState state) {
                        final String jid = state.pathParameters['jid'] ?? '';
                        return JournalDetailScreen(journalId: jid);
                      },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: keywordsNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/keywords',
              builder:
                  (final BuildContext context, final GoRouterState state) =>
                      const KeywordsScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'author/:aid',
                  parentNavigatorKey: rootNavigatorKey,
                  builder:
                      (final BuildContext context, final GoRouterState state) {
                        final String aid = state.pathParameters['aid'] ?? '';
                        return AuthorDetailScreen(authorId: aid);
                      },
                ),
                GoRoute(
                  path: 'detail/:kid',
                  parentNavigatorKey: rootNavigatorKey,
                  builder:
                      (final BuildContext context, final GoRouterState state) {
                        final String kid = state.pathParameters['kid'] ?? '';
                        final String name =
                            state.uri.queryParameters['name'] ?? '';
                        return KeywordDetailScreen(
                          keywordId: kid,
                          keywordName: name,
                        );
                      },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: profileNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/profile',
              builder:
                  (final BuildContext context, final GoRouterState state) =>
                      const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (final int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Topics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
